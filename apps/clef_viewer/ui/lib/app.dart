import 'package:flutter/material.dart';

import 'models/log_filter.dart';
import 'pages/admin_page.dart';
import 'pages/viewer_page.dart';
import 'theme/clef_design_system.dart';
import 'theme/clef_theme.dart';
import 'widgets/version_bar.dart';

class ClefViewerApp extends StatefulWidget {
  const ClefViewerApp({super.key});

  @override
  State<ClefViewerApp> createState() => _ClefViewerAppState();
}

class _ClefViewerAppState extends State<ClefViewerApp> {
  int _index = 0;
  LogFilter _sharedFilter = const LogFilter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CLEF Viewer - POC',
      theme: buildClefTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('CLEF Viewer'),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(28),
            child: VersionBar(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: ClefDs.spaceMd),
              child: _SegmentedNav(
                index: _index,
                onChanged: (i) => setState(() => _index = i),
              ),
            ),
          ],
        ),
        body: _index == 0
            ? ViewerPage(
                sharedFilter: _sharedFilter,
                onFilterChanged: (filter) => setState(() => _sharedFilter = filter),
              )
            : AdminPage(activeFilter: _sharedFilter),
      ),
    );
  }
}

class _SegmentedNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _SegmentedNav({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ClefDs.appleGrayFill,
        borderRadius: BorderRadius.circular(ClefDs.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Viewer',
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
          _Segment(
            label: 'Admin',
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(ClefDs.radiusSm),
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClefDs.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? ClefDs.appleText : ClefDs.appleTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}