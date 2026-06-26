import '../models/log_entry.dart';
import '../models/log_filter.dart';
import 'log_api_client.dart';

class DeviceSuggestionCache {
  static const maxSuggestions = 100;

  DeviceSuggestionCache({required LogApiClient api}) : _api = api;

  final LogApiClient _api;
  List<String> _suggestions = [];
  bool _isLoaded = false;

  List<String> get suggestions => List.unmodifiable(_suggestions);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    try {
      final groups = await _api.fetchGroups(
        groupBy: 'device_id',
        filter: const LogFilter(),
      );
      _suggestions = groups.map((g) => g.key).toList();
    } catch (_) {
      _suggestions = [];
    }
    _isLoaded = true;
  }

  void mergeFromEvent(LogEntry entry) {
    if (_suggestions.length >= maxSuggestions) return;

    final deviceId = entry.deviceId;
    final label = (deviceId == null || deviceId.isEmpty) ? '(empty)' : deviceId;
    if (!_suggestions.contains(label)) {
      _suggestions = [..._suggestions, label];
    }
  }

  List<String> search(String query) {
    final q = query.toLowerCase();
    return _suggestions
        .where((s) => s.toLowerCase().contains(q))
        .take(50)
        .toList();
  }
}