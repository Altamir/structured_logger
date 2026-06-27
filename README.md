# Structured Logger Monorepo

[![CI](https://github.com/Altamir/structured_logger/actions/workflows/ci.yml/badge.svg)](https://github.com/Altamir/structured_logger/actions/workflows/ci.yml)

This is the monorepo for **Structured Logger** — Dart-first structured logging with pluggable sinks (CLEF/Seq, console, etc.).

- Core package: `packages/structured_logger` (Dart pure, v1.0.0+)
- Dio interceptor: `packages/structured_logger_dio_interceptor` (new)
- CLEF Viewer: `apps/clef_viewer/{server,ui}`
- Docs: `docs/` (Dart-first) + website

**Documentação e blog:** [https://structured-logger.altamir.dev](https://structured-logger.altamir.dev)

## Description
The ``structured_logger`` package provides an easy way to implement structured logs in Dart and Flutter applications. It allows sending logs to different destinations, such as the terminal or external services, through interfaces called ``Sinks``. The package includes a sample Sink, SimpleLineSink, which sends logs to the terminal.

## Installation

Primary (Dart / CLI / server):

```bash
dart pub add structured_logger
```

For Flutter apps:

```bash
flutter pub add structured_logger
```

Add the following to your pubspec.yaml file (or use the pub command):

```yaml
dependencies:
  structured_logger: ^1.0.0
```

## Basic Usage

Import the package into your Dart file:
```dart
import 'package:structured_logger/structured_logger.dart';
```

Create an instance of the logger:

```dart
final logger = StructureLogger();
```

Add a Sink to specify where the logs should be sent. For example, to send logs to the terminal, use SimpleLineSink:

```dart
LogSink sink = SimpleLineSink();
logger.addSink(sink);
```

Add other Sinks, if necessary, to send logs to different destinations.

```dart
LogSink defaultlog = DefaultSink();
logger.addSink(defaultlog);
```

To send logs to a [Seq](https://datalust.co/seq) server, use `SinkSeq`:

```dart
logger.addSink(SinkSeq(
  'https://your-seq-server-url',
  apiKey: 'your-api-key',
  deviceIdentifier: 'my-device',
));
```

Call `close()` on the sink when discarding it in long-lived apps to release the internal HTTP connection pool.

Register logs using the log method:

```dart
await logger.log(
  "Welcome {name}, your level is {level}",
  level: LogLevel.info,
  data: {"name": "John Doe", "level": 12},
);
```

terminal output [First line is written by SimpleLineSink, and second line is written by DefaultSink.]:
```log 
Seja bem vindo John Doe, seu nível é 12
[log] {@t: 2023-12-19T15:38:06.563023, @mt: Seja bem vindo {name}, seu nível é {level}, @l: info, data: {name: John Doe, level: 12}}
```

First line is written by SimpleLineSink, and second line is written by DefaultSink.



This is a simple example, and you can customize Sinks and log data as needed.

## Packages in this monorepo

- `structured_logger` (core, Dart-pure)
- `structured_logger_dio_interceptor` (Dio HTTP logging via StructureLogger + your sinks)
- See `packages/` and docs for interceptor usage and migration from legacy `dio_interceptor_seq`.

## Releasing new versions (pub.dev)

Releases are fully automated via GitHub Actions using Melos.

### Workflow Features
- Automatic version bumping (`melos version`)
- Support for **prereleases**
- Automatic **GitHub Release** creation (with generated notes)
- Uses **OIDC Trusted Publishing** (no long-lived `credentials.json` secret required)

### Prerequisites (seguindo o oficial do pub.dev)
Faça isso **uma única vez** para cada pacote:

1. Acesse o Admin do pacote no pub.dev.

2. Na seção **Automated publishing**:
   - Marque **Enable publishing from workflow_dispatch events**
   - (Opcional) Marque também **Enable publishing from push events**
   - Tag pattern: `structured_logger-v{{version}}` (ou `*-v{{version}}`)
   - (Opcional) Marque "Require GitHub Actions environment" (ex: pub-dev)

3. Salve. Repita para os dois pacotes.

O workflow agora usa o reusable oficial:
`uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1`

Com `working-directory` para monorepo.

### How to release
1. Go to **Actions** → **Publish to pub.dev**
2. Click **Run workflow**
3. Fill the inputs:
   - `package`: `structured_logger`, `structured_logger_dio_interceptor`, or `all`
   - `bump`: `patch`, `minor`, or `major`
   - `prerelease`: check if this is a prerelease version
4. The workflow will:
   - Run CI checks
   - Bump version(s) with Melos (using official tag pattern)
   - Push tag(s)
   - Publish using the official reusable workflow (dart-lang/setup-dart)
   - Create GitHub Release(s)

**Tag pattern no pub.dev**: `structured_logger-v{{version}}` (or `*-v{{version}}`)

**Order note**: When publishing both, the core is handled first in the matrix.

You can still use `melos version` + `dart pub publish` locally.

