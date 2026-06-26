import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/log_api_client.dart';

/// Shows webapp + server build versions (from CI git SHA).
class VersionBar extends StatefulWidget {
  const VersionBar({super.key});

  @override
  State<VersionBar> createState() => _VersionBarState();
}

class _VersionBarState extends State<VersionBar> {
  final _api = LogApiClient();
  String? _serverVersion;

  @override
  void initState() {
    super.initState();
    _loadServerVersion();
  }

  Future<void> _loadServerVersion() async {
    try {
      final health = await _api.fetchHealth();
      if (!mounted) return;
      setState(() => _serverVersion = health.version);
    } catch (_) {
      if (!mounted) return;
      setState(() => _serverVersion = 'offline');
    }
  }

  @override
  Widget build(BuildContext context) {
    final webapp = ApiConfig.shortLabel(ApiConfig.appVersion);
    final server = _serverVersion == null
        ? '…'
        : ApiConfig.shortLabel(_serverVersion!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        'webapp $webapp  ·  server $server',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}