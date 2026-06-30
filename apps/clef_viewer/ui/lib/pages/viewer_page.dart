import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/viewer_config.dart';
import '../models/level_options.dart';
import '../models/log_entry.dart';
import '../models/log_filter.dart';
import '../models/viewer_time_window.dart';
import '../services/device_suggestion_cache.dart';
import '../services/log_api_client.dart';
import '../services/sse_client.dart';
import '../widgets/filter_bar.dart';
import '../widgets/group_panel.dart';
import '../widgets/log_table.dart';
import '../widgets/resizable_split_pane.dart';

class ViewerPage extends StatefulWidget {
  final LogFilter sharedFilter;
  final ValueChanged<LogFilter> onFilterChanged;
  final ValueChanged<bool>? onPausedChanged;

  const ViewerPage({
    super.key,
    required this.sharedFilter,
    required this.onFilterChanged,
    this.onPausedChanged,
  });

  @override
  State<ViewerPage> createState() => ViewerPageState();
}

class ViewerPageState extends State<ViewerPage> {
  final _api = LogApiClient();
  late final DeviceSuggestionCache _deviceCache;
  late SseClient _sse;
  StreamSubscription<LogEntry>? _sseSub;

  LogFilter _filter = const LogFilter();
  String _search = '';
  ViewerTimeWindow _timeWindow = const ViewerTimeWindow();
  List<LogEntry> _events = [];
  int _total = 0;
  bool _loading = true;
  bool _paused = false;
  String _groupBy = 'level';
  String _timeBucket = 'hour';
  String _propertyName = 'Screen';
  List<GroupResult> _groups = [];

  final _filterBarKey = GlobalKey<FilterBarState>();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _filter = _stripTime(widget.sharedFilter);
    _timeWindow = _timeWindowFromShared(widget.sharedFilter);
    _deviceCache = DeviceSuggestionCache(api: _api);
    _deviceCache.load();
    _sse = SseClient()..onReconnect = _onSseReconnect;
    _loadInitial();
    _connectSse();
    _startPolling();
  }

  @override
  void didUpdateWidget(ViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sharedFilterChanged(oldWidget.sharedFilter, widget.sharedFilter)) {
      _filter = _stripTime(widget.sharedFilter);
      _timeWindow = _timeWindowFromShared(widget.sharedFilter);
      _filterBarKey.currentState?.applyExternalFilter(
        _filter,
        timeWindow: _timeWindow,
        preserveSearch: true,
      );
      _loadInitial(silent: true);
      _loadGroups();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _sseSub?.cancel();
    _sse.dispose();
    super.dispose();
  }

  LogFilter _stripTime(LogFilter f) => f.copyWith(from: null, to: null);

  ViewerTimeWindow _timeWindowFromShared(LogFilter shared) {
    if (shared.from != null || shared.to != null) {
      return ViewerTimeWindow(
        kind: TimeWindowKind.customRange,
        customFrom: shared.from,
        customTo: shared.to,
        liveSteady: _timeWindow.liveSteady,
      );
    }
    return ViewerTimeWindow(liveSteady: _timeWindow.liveSteady);
  }

  LogFilter _effectiveFilter() {
    final base = _filter.copyWith(
      search: _search.trim().isEmpty ? null : _search.trim(),
    );
    return _timeWindow.applyTo(base, DateTime.now());
  }

  LogFilter _sharedSnapshot() => _effectiveFilter().copyWith(search: null);

  bool _sharedFilterChanged(LogFilter old, LogFilter neu) {
    return !listEquals(old.levels, neu.levels) ||
        old.deviceId != neu.deviceId ||
        !listEquals(old.properties, neu.properties) ||
        old.from != neu.from ||
        old.to != neu.to;
  }

  bool _structuralFilterChanged(LogFilter old, LogFilter neu) {
    return !listEquals(old.levels, neu.levels) ||
        old.deviceId != neu.deviceId ||
        !listEquals(old.properties, neu.properties);
  }

  void _publishSharedFilter() {
    widget.onFilterChanged(_sharedSnapshot());
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_paused && mounted) {
        _loadInitial(silent: true, refreshGroups: false);
      }
    });
  }

  Future<void> _loadInitial({bool silent = false, bool refreshGroups = true}) async {
    final queryFilter = _effectiveFilter();
    final timeError = _timeWindow.validate();
    if (timeError != null) {
      if (!silent && mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    if (!silent) setState(() => _loading = true);
    try {
      final result = await _api.fetchEvents(
        queryFilter,
        limit: ViewerConfig.maxDisplayedEvents,
      );
      if (!mounted) return;
      setState(() {
        _events = result.events;
        _total = result.total;
        if (!silent) _loading = false;
        if (!_timeWindow.liveSteady &&
            _timeWindow.kind == TimeWindowKind.liveNow) {
          _timeWindow = _timeWindow.copyWith(liveSteady: true);
        }
      });
    } catch (e) {
      if (!silent && mounted) setState(() => _loading = false);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e')),
        );
      }
    }
    if (refreshGroups) {
      await _loadGroups();
    }
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _api.fetchGroups(
        groupBy: _groupBy,
        filter: _effectiveFilter(),
        bucket: _groupBy == 'time' ? _timeBucket : null,
        groupProperty: _groupBy == 'property' ? _propertyName : null,
      );
      setState(() => _groups = groups);
    } catch (_) {
      setState(() => _groups = []);
    }
  }

  void _connectSse() {
    _sse.connect();
    _sseSub = _sse.stream.listen(_onSseEvent);
  }

  void _onSseReconnect() {
    if (_paused || !mounted) return;
    _loadInitial(silent: true);
  }

  void _onSseEvent(LogEntry entry) {
    if (_paused) return;
    if (!_effectiveFilter().matches(entry)) return;

    _deviceCache.mergeFromEvent(entry);

    setState(() {
      _events = [entry, ..._events];
      _total++;
      final cap = ViewerConfig.maxDisplayedEvents;
      if (_events.length > cap) {
        _events = _events.sublist(0, cap);
      }
    });
  }

  bool get isPaused => _paused;

  void togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _sse.disconnect();
      } else {
        _sse.resume();
        _sseSub?.cancel();
        _sseSub = _sse.stream.listen(_onSseEvent);
        _loadInitial();
      }
    });
    widget.onPausedChanged?.call(_paused);
  }

  void _applyFilter(LogFilter filter) {
    final structural = _stripTime(filter.copyWith(search: null));
    final structureChanged = _structuralFilterChanged(_filter, structural);

    setState(() {
      _search = filter.search ?? '';
      _filter = structural;
    });

    if (structureChanged) {
      _publishSharedFilter();
    }
    _loadInitial(silent: true);
    _loadGroups();
  }

  void _onTimeWindowChanged(ViewerTimeWindow window) {
    setState(() => _timeWindow = window);
    _publishSharedFilter();
    _loadInitial(silent: true);
    _loadGroups();
  }

  void _onLevelsChanged(Set<String> levels) {
    final filter = _filter.copyWith(
      levels: LevelOptions.filterFromUiSelection(levels),
    );
    _applyFilter(filter.copyWith(search: _search.isEmpty ? null : _search));
  }

  void _onClear() {
    setState(() {
      _filter = const LogFilter();
      _search = '';
      _timeWindow = const ViewerTimeWindow();
    });
    _filterBarKey.currentState?.applyExternalFilter(
      const LogFilter(),
      timeWindow: const ViewerTimeWindow(),
      clearSearch: true,
    );
    _publishSharedFilter();
    _loadInitial(silent: true);
    _loadGroups();
  }

  void _onGroupSelected(String key) {
    final newFilter = GroupPanel.applyGroupFilter(
      _filter,
      _groupBy,
      key,
      propertyName: _propertyName,
    );

    if (_groupBy == 'time') {
      setState(() {
        _timeWindow = ViewerTimeWindow(
          kind: TimeWindowKind.customRange,
          customFrom: newFilter.from,
          customTo: newFilter.to,
          liveSteady: _timeWindow.liveSteady,
        );
        _filter = _stripTime(newFilter);
      });
      _filterBarKey.currentState?.applyExternalFilter(
        _filter,
        timeWindow: _timeWindow,
        preserveSearch: true,
      );
      _publishSharedFilter();
      _loadInitial(silent: true);
      _loadGroups();
      return;
    }

    _applyFilter(
      newFilter.copyWith(search: _search.isEmpty ? null : _search),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLevels = LevelOptions.uiSelectionFromFilter(_filter.levels);

    return Column(
      children: [
        FilterBar(
          key: _filterBarKey,
          initialFilter: _filter,
          initialSearch: _search,
          timeWindow: _timeWindow,
          onTimeWindowChanged: _onTimeWindowChanged,
          onApply: _applyFilter,
          onClear: _onClear,
          deviceCache: _deviceCache,
        ),
        Expanded(
          child: ResizableSplitPane(
            left: GroupPanel(
              selectedLevels: selectedLevels,
              onLevelsChanged: _onLevelsChanged,
              groupBy: _groupBy,
              timeBucket: _timeBucket,
              propertyName: _propertyName,
              groups: _groups,
              groupByChanged: (v) {
                setState(() => _groupBy = v);
                _loadGroups();
              },
              timeBucketChanged: (v) {
                setState(() => _timeBucket = v);
                _loadGroups();
              },
              propertyNameChanged: (v) {
                setState(() => _propertyName = v);
                _loadGroups();
              },
              onGroupSelected: _onGroupSelected,
              onRefresh: _loadGroups,
            ),
            right: _loading && _events.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : LogTable(
                    events: _events,
                    total: _total,
                    displayCap: ViewerConfig.maxDisplayedEvents,
                    onPropertyFilter: (param) {
                      _filterBarKey.currentState?.applyPropertyFilter(param);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}