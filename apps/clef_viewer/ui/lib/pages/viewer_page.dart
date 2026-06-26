import 'dart:async';

import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../models/log_filter.dart';
import '../services/log_api_client.dart';
import '../services/sse_client.dart';
import '../widgets/filter_bar.dart';
import '../widgets/group_panel.dart';
import '../widgets/log_table.dart';

class ViewerPage extends StatefulWidget {
  final LogFilter sharedFilter;
  final ValueChanged<LogFilter> onFilterChanged;

  const ViewerPage({
    super.key,
    required this.sharedFilter,
    required this.onFilterChanged,
  });

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  static const maxInMemory = 1000;

  final _api = LogApiClient();
  late SseClient _sse;
  StreamSubscription<LogEntry>? _sseSub;

  LogFilter _filter = const LogFilter();
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
    _filter = widget.sharedFilter;
    _sse = SseClient()..onReconnect = _onSseReconnect;
    _loadInitial();
    _connectSse();
    _startPolling();
  }

  @override
  void didUpdateWidget(ViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sharedFilter != widget.sharedFilter) {
      _filter = widget.sharedFilter;
      _loadInitial();
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

  /// Fallback when SSE is blocked by proxy — refresh every 3s without spinner.
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_paused && mounted) {
        _loadInitial(silent: true, refreshGroups: false);
      }
    });
  }

  Future<void> _loadInitial({bool silent = false, bool refreshGroups = true}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final result = await _api.fetchEvents(_filter, limit: 100);
      if (!mounted) return;
      setState(() {
        _events = result.events;
        _total = result.total;
        if (!silent) _loading = false;
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
        filter: _filter,
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
    if (_filter.hasActiveFilters && !_filter.matches(entry)) return;

    setState(() {
      _events = [entry, ..._events];
      _total++;
      if (_events.length > maxInMemory) {
        _events = _events.sublist(0, maxInMemory);
      }
    });
  }

  void _togglePause() {
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
  }

  void _applyFilter(LogFilter filter) {
    setState(() => _filter = filter);
    widget.onFilterChanged(filter);
    _loadInitial();
  }

  void _onGroupSelected(String key) {
    final newFilter = GroupPanel.applyGroupFilter(
      _filter,
      _groupBy,
      key,
      propertyName: _propertyName,
    );
    _applyFilter(newFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilterBar(
          key: _filterBarKey,
          initialFilter: _filter,
          onApply: _applyFilter,
          onClear: () => _applyFilter(const LogFilter()),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: GroupPanel(
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
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 3,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : LogTable(events: _events, total: _total),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FilledButton.icon(
              onPressed: _togglePause,
              icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              label: Text(_paused ? 'Resume' : 'Pause'),
            ),
          ),
        ),
      ],
    );
  }
}