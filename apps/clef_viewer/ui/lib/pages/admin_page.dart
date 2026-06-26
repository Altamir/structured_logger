import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/log_filter.dart';
import '../services/export_downloader.dart';
import '../services/log_api_client.dart';
import '../widgets/confirm_delete_dialog.dart';

class AdminPage extends StatefulWidget {
  final LogFilter activeFilter;

  const AdminPage({super.key, required this.activeFilter});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _api = LogApiClient();
  final _keyController = TextEditingController();
  int? _eventCount;
  String? _error;
  bool _loading = false;
  bool _showKeyBanner = false;

  @override
  void initState() {
    super.initState();
    final stored = html.window.sessionStorage[ApiConfig.adminKeyStorageKey];
    if (stored != null && stored.isNotEmpty) {
      _keyController.text = stored;
    } else {
      _showKeyBanner = true;
    }
    _refreshHealth();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptForApiKeyIfNeeded());
  }

  void _promptForApiKeyIfNeeded() {
    if (!_showKeyBanner || !mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin API Key Required'),
        content: const Text(
          'Enter your ADMIN_API_KEY below and save it to session storage. '
          'The key is never stored in the URL.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              setState(() => _showKeyBanner = false);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _refreshHealth() async {
    try {
      final health = await _api.fetchHealth();
      setState(() => _eventCount = health.events);
    } catch (_) {
      setState(() => _eventCount = null);
    }
  }

  void _saveKey() {
    html.window.sessionStorage[ApiConfig.adminKeyStorageKey] =
        _keyController.text;
    setState(() => _showKeyBanner = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved to session')),
    );
  }

  String? get _apiKey {
    final key = _keyController.text.trim();
    return key.isEmpty ? null : key;
  }

  Future<void> _export({bool filtered = false}) async {
    final key = _apiKey;
    if (key == null) {
      setState(() => _error = 'API key required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ExportDownloader.downloadClefExport(
        apiKey: key,
        filter: filtered ? widget.activeFilter : null,
      );
    } on UnauthorizedExportException {
      setState(() => _error = 'Invalid API key');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
      await _refreshHealth();
    }
  }

  Future<void> _confirmAndDelete({bool filtered = false}) async {
    final confirmed = await showConfirmDeleteDialog(context, filtered: filtered);

    if (confirmed != true || !mounted) return;

    final key = _apiKey;
    if (key == null) {
      setState(() => _error = 'API key required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.deleteLogs(
        filter: filtered ? widget.activeFilter : null,
        apiKey: key,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs deleted')),
        );
      }
    } on UnauthorizedException {
      setState(() => _error = 'Invalid API key');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
      await _refreshHealth();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showKeyBanner)
            MaterialBanner(
              content: const Text(
                'No admin API key configured. Enter your ADMIN_API_KEY and '
                'save it to session storage before using admin actions.',
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _showKeyBanner = false),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: _saveKey, child: const Text('Save to session')),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Storage: ${_eventCount ?? '—'} events',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: _loading ? null : () => _export(filtered: false),
                child: const Text('Export All CLEF'),
              ),
              ElevatedButton(
                onPressed: _loading ? null : () => _export(filtered: true),
                child: const Text('Export Filtered CLEF'),
              ),
              OutlinedButton(
                onPressed: _loading ? null : () => _confirmAndDelete(),
                child: const Text('Clear All Logs'),
              ),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _confirmAndDelete(filtered: true),
                child: const Text('Clear Filtered'),
              ),
            ],
          ),
          if (_loading) const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
        ],
      ),
    );
  }
}