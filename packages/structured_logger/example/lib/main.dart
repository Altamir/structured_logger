import 'dart:io';
import 'dart:math';

import 'package:structured_logger/structured_logger.dart';

/// Gera 4×1000 logs em paralelo (um produtor por deviceId) para validar a UI
/// do CLEF Viewer.
///
/// Uso:
/// ```bash
/// cd example
/// INGEST_API_KEY=algo-complexo-123 dart run lib/main.dart
/// ```
///
/// Arquivo local — não commitar (skip-worktree no git).
Future<void> main() async {
  const ingestUrl = 'https://clef-ingest.altamir.dev';
  const apiKey = String.fromEnvironment(
    'INGEST_API_KEY',
    defaultValue: 'algo-complexo-123',
  );
  final resolvedKey = apiKey.isNotEmpty
      ? apiKey
      : (Platform.environment['INGEST_API_KEY'] ?? 'algo-complexo-123');

  const deviceIds = [
    'mobile-ios',
    'mobile-android',
    'web-frontend',
    'api-gateway',
  ];

  const levels = [
    'debug',
    'verbose',
    'info',
    'information',
    'warning',
    'error',
    'fatal',
  ];

  const templates = [
    'User {UserId} opened screen {Screen}',
    'Payment {Action} for order {OrderId} status {Status}',
    'API {Method} {Endpoint} responded in {DurationMs}ms',
    'Cache {CacheOp} key {CacheKey} hit={CacheHit}',
    'Job {JobName} processed {ItemCount} items',
    'Auth attempt for {Email} result {AuthResult}',
    'SSE client {ClientId} subscribed to {Channel}',
    'Validation failed on field {FieldName}: {ErrorCode}',
  ];

  const screens = ['Home', 'Checkout', 'Profile', 'Settings', 'Logs'];
  const actions = ['create', 'update', 'delete', 'refund', 'retry'];
  const methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];

  const logsPerProducer = 1000;
  final total = deviceIds.length * logsPerProducer;

  stdout.writeln(
      'Enviando $total logs ($logsPerProducer por device) para $ingestUrl');
  stdout.writeln('Devices (paralelo): ${deviceIds.join(', ')}');
  stdout.writeln('API key: ${resolvedKey.substring(0, 4)}…');

  final results = await Future.wait(
    deviceIds.map(
      (deviceId) => _produceLogs(
        deviceId: deviceId,
        ingestUrl: ingestUrl,
        apiKey: resolvedKey,
        count: logsPerProducer,
        levels: levels,
        templates: templates,
        screens: screens,
        actions: actions,
        methods: methods,
      ),
    ),
  );

  var ok = 0;
  var fail = 0;
  for (final result in results) {
    ok += result.ok;
    fail += result.fail;
    stdout.writeln(
      '  ${result.deviceId}: ${result.ok} ok, ${result.fail} falhas',
    );
  }

  stdout.writeln('Concluído: $ok ok, $fail falhas.');
}

Future<_ProducerResult> _produceLogs({
  required String deviceId,
  required String ingestUrl,
  required String apiKey,
  required int count,
  required List<String> levels,
  required List<String> templates,
  required List<String> screens,
  required List<String> actions,
  required List<String> methods,
}) async {
  final sink = SinkSeq(
    ingestUrl,
    apiKey: apiKey,
    deviceIdentifier: deviceId,
  );

  final rng = Random(deviceId.hashCode);
  final sharedCorrelationalIds = List.generate(4, (_) => _randomUuid(rng));

  var ok = 0;
  var fail = 0;

  for (var i = 0; i < count; i++) {
    final level = levels[rng.nextInt(levels.length)];
    final template = templates[rng.nextInt(templates.length)];

    final correlationalId = rng.nextDouble() < 0.4
        ? sharedCorrelationalIds[rng.nextInt(sharedCorrelationalIds.length)]
        : _randomUuid(rng);

    final data = <String, dynamic>{
      'corelationalId': correlationalId,
      'DeviceId': deviceId,
      'UserId': rng.nextInt(500) + 1,
      'Screen': screens[rng.nextInt(screens.length)],
      'Action': actions[rng.nextInt(actions.length)],
      'OrderId': 'ORD-${10000 + rng.nextInt(90000)}',
      'Status': rng.nextBool() ? 'success' : 'failed',
      'Method': methods[rng.nextInt(methods.length)],
      'Endpoint':
          '/api/v${rng.nextInt(3) + 1}/${actions[rng.nextInt(actions.length)]}',
      'DurationMs': rng.nextInt(3000) + 1,
      'CacheOp': rng.nextBool() ? 'read' : 'write',
      'CacheKey': 'session:${rng.nextInt(1000)}',
      'CacheHit': rng.nextBool(),
      'JobName': 'sync-inventory',
      'ItemCount': rng.nextInt(200),
      'Email': 'user${rng.nextInt(100)}@example.com',
      'AuthResult': rng.nextBool() ? 'ok' : 'denied',
      'ClientId': 'client-${rng.nextInt(50)}',
      'Channel': 'events.${rng.nextInt(5)}',
      'FieldName': ['email', 'amount', 'sku'][rng.nextInt(3)],
      'ErrorCode': ['required', 'invalid', 'timeout'][rng.nextInt(3)],
      'BatchIndex': i + 1,
    };

    try {
      await sink.write(
        LogModel(
          mt: template,
          level: level,
          data: data,
        ),
      );
      ok++;
    } catch (e) {
      fail++;
      stderr.writeln('[$deviceId] Falha no log ${i + 1}: $e');
    }

    if ((i + 1) % 100 == 0) {
      stdout.writeln('  [$deviceId] ${i + 1}/$count enviados…');
    }

    if (i % 10 == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
  }

  sink.close();
  return _ProducerResult(deviceId: deviceId, ok: ok, fail: fail);
}

String _randomUuid(Random rng) {
  String hex(int len) =>
      List.generate(len, (_) => rng.nextInt(16).toRadixString(16)).join();

  return '${hex(8)}-${hex(4)}-4${hex(3)}-'
      '${['8', '9', 'a', 'b'][rng.nextInt(4)]}${hex(3)}-'
      '${hex(12)}';
}

class _ProducerResult {
  const _ProducerResult({
    required this.deviceId,
    required this.ok,
    required this.fail,
  });

  final String deviceId;
  final int ok;
  final int fail;
}
