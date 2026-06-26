import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/admin_stats.dart';
import '../models/log_filter.dart';
import '../services/export_downloader.dart';
import '../services/log_api_client.dart';
import '../theme/clef_design_system.dart';
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
  AdminStats? _stats;
  String? _error;
  bool _loading = false;
  bool _statsLoading = false;
  bool _showKeyBanner = false;

  @override
  void initState() {
    super.initState();
    final stored = html.window.sessionStorage[ApiConfig.adminKeyStorageKey];
    if (stored != null && stored.isNotEmpty) {
      _keyController.text = stored;
      _refreshStats();
    } else {
      _showKeyBanner = true;
    }
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

  String? get _apiKey {
    final key = _keyController.text.trim();
    return key.isEmpty ? null : key;
  }

  Future<void> _refreshStats() async {
    final key = _apiKey;
    if (key == null) return;

    setState(() => _statsLoading = true);
    try {
      final stats = await _api.fetchAdminStats(apiKey: key);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _statsLoading = false;
        _error = null;
      });
    } on UnauthorizedException {
      setState(() {
        _stats = null;
        _statsLoading = false;
        _error = 'Invalid API key';
      });
    } catch (e) {
      setState(() {
        _stats = null;
        _statsLoading = false;
        _error = e.toString();
      });
    }
  }

  void _saveKey() {
    html.window.sessionStorage[ApiConfig.adminKeyStorageKey] =
        _keyController.text;
    setState(() => _showKeyBanner = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved to session')),
    );
    _refreshStats();
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
      await _refreshStats();
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
      await _refreshStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ClefDs.spaceXl),
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
          Container(
            padding: const EdgeInsets.all(ClefDs.spaceLg),
            decoration: ClefDs.surfaceCard(context),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: ClefDs.inputDecoration(
                      context: context,
                      label: 'API Key',
                    ),
                  ),
                ),
                const SizedBox(width: ClefDs.spaceMd),
                FilledButton(
                  onPressed: _saveKey,
                  child: const Text('Save to session'),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClefDs.spaceLg),
          _StorageSection(
            stats: _stats,
            loading: _statsLoading,
            onRefresh: _refreshStats,
          ),
          if (_error != null) ...[
            const SizedBox(height: ClefDs.spaceMd),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: ClefDs.spaceLg),
          _ReportsSection(stats: _stats, loading: _statsLoading),
          const SizedBox(height: ClefDs.spaceLg),
          Container(
            padding: const EdgeInsets.all(ClefDs.spaceLg),
            decoration: ClefDs.surfaceCard(context),
            child: Wrap(
              spacing: ClefDs.spaceMd,
              runSpacing: ClefDs.spaceMd,
              children: [
                FilledButton(
                  onPressed: _loading ? null : () => _export(filtered: false),
                  child: const Text('Export All CLEF'),
                ),
                FilledButton(
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
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: ClefDs.spaceMd),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _StorageSection extends StatelessWidget {
  final AdminStats? stats;
  final bool loading;
  final VoidCallback onRefresh;

  const _StorageSection({
    required this.stats,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClefDs.spaceLg),
      decoration: ClefDs.surfaceCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Storage', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                tooltip: 'Atualizar métricas',
                onPressed: loading ? null : onRefresh,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: ClefDs.spaceMd),
          Wrap(
            spacing: ClefDs.spaceLg,
            runSpacing: ClefDs.spaceMd,
            children: [
              _MetricTile(
                label: 'Espaço do banco',
                value: stats == null ? '—' : _formatBytes(stats!.dbSizeBytes),
                subtitle: stats?.dbSizeBytes == 0 ? 'em memória ou indisponível' : null,
              ),
              _MetricTile(
                label: 'Total de eventos',
                value: stats == null ? '—' : '${stats!.eventCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportsSection extends StatelessWidget {
  final AdminStats? stats;
  final bool loading;

  const _ReportsSection({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClefDs.spaceLg),
      decoration: ClefDs.surfaceCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Relatórios', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: ClefDs.spaceMd),
          if (loading && stats == null)
            const Center(child: CircularProgressIndicator())
          else if (stats == null)
            Text(
              'Salve a API key para carregar relatórios.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            Wrap(
              spacing: ClefDs.spaceLg,
              runSpacing: ClefDs.spaceMd,
              children: [
                _MetricTile(
                  label: 'Logs/seg (último minuto)',
                  value: stats!.logsPerSecondLastMinute.toStringAsFixed(2),
                ),
                _MetricTile(
                  label: 'Logs/seg (média última hora)',
                  value: stats!.logsPerSecondLastHour.toStringAsFixed(2),
                ),
              ],
            ),
            const SizedBox(height: ClefDs.spaceLg),
            Text(
              'Total por período (últimas 24h, por hora)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: ClefDs.spaceSm),
            _BucketTable(
              buckets: stats!.totalByPeriod,
              emptyMessage: 'Nenhum log nas últimas 24 horas.',
            ),
            const SizedBox(height: ClefDs.spaceLg),
            Text(
              'Picos de ingest (top 10 minutos, últimas 24h)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: ClefDs.spaceSm),
            _BucketTable(
              buckets: stats!.ingestPeaks,
              emptyMessage: 'Nenhum pico registrado.',
              showRank: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _MetricTile({
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(ClefDs.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ClefDs.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}

class _BucketTable extends StatelessWidget {
  final List<PeriodBucket> buckets;
  final String emptyMessage;
  final bool showRank;

  const _BucketTable({
    required this.buckets,
    required this.emptyMessage,
    this.showRank = false,
  });

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return Text(emptyMessage, style: Theme.of(context).textTheme.bodySmall);
    }

    final maxCount = buckets.map((b) => b.count).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var i = 0; i < buckets.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                if (showRank)
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#${i + 1}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatPeriod(buckets[i].period),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxCount == 0 ? 0 : buckets[i].count / maxCount,
                      minHeight: 8,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: ClefDs.spaceSm),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${buckets[i].count}',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

String _formatPeriod(String iso) {
  if (iso.length < 16) return iso;
  return '${iso.substring(0, 10)} ${iso.substring(11, 16)}';
}