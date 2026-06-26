/// Canonical log level options for filtering.
abstract final class LevelOptions {
  static const all = [
    'debug',
    'information',
    'info',
    'warning',
    'error',
    'fatal',
  ];

  /// Empty filter levels means "no restriction" — show all selected in UI.
  static Set<String> uiSelectionFromFilter(List<String> filterLevels) {
    if (filterLevels.isEmpty) return all.toSet();
    return filterLevels.toSet();
  }

  /// All levels selected in UI maps to empty filter (no level restriction).
  static List<String> filterFromUiSelection(Set<String> selected) {
    if (selected.length == all.length && all.every(selected.contains)) {
      return const [];
    }
    return selected.toList();
  }

  static bool isAllSelected(Set<String> selected) =>
      selected.length == all.length && all.every(selected.contains);
}