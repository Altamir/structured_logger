import 'package:flutter/material.dart';

import 'models/log_filter.dart';
import 'pages/admin_page.dart';
import 'pages/viewer_page.dart';

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
      title: 'CLEF Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('CLEF Viewer'),
          actions: [
            TextButton(
              onPressed: () => setState(() => _index = 0),
              child: const Text('Viewer'),
            ),
            TextButton(
              onPressed: () => setState(() => _index = 1),
              child: const Text('Admin'),
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