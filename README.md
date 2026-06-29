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

## Releasing new versions (pub.dev) + Branching model

The repository uses a **develop / master** flow:

- `develop` — integration branch. All feature PRs target `develop`.
- `master` — stable. Only PRs from `develop` to `master` for final releases.

### Automated flow (preferred)

1. Open PR → `develop` → CI runs tests + builds PR preview images/docs (`-DEV-PR`).
2. **Merge** the PR → `release.yml` runs:
   - Full CI
   - `melos version --yes --prerelease --preid=DEV --no-git-tag-version`
   - Creates tags `vX.Y.Z-DEV.N` (one per versioned package; same commit may have multiple `v*` tags)
   - Creates GitHub **pre-release** per `v*` tag
   - Publishes packages to pub.dev as **prerelease** (tag push triggers `publish.yml`)
   - Pushes DEV images (tags with `-DEV`, no `:latest`) + docs to CF `develop` branch
3. When ready: open PR `develop` → `master`.
4. On open → only tests + preview run.
5. **Merge** → `release.yml` runs:
   - `melos version --yes --graduate` (or conventional stable) with `--no-git-tag-version`
   - Pushes final `vX.Y.Z` tags only
   - Stable GitHub release per `v*` tag
   - Publishes final packages
   - Updates images with `:latest` + docs to CF `master`

### Prerequisites (pub.dev Automated publishing) — IMPORTANT

Faça isso **uma única vez** para cada pacote (https://pub.dev):

1. Package admin → **Automated publishing**
2. Enable:
   - "Enable publishing from workflow_dispatch events"
   - "Enable publishing from push events" (recommended)
3. **Tag pattern** (same for both packages):

   - `v{{version}}`

   Example: `v1.0.1-dev.2` publishes the package whose `pubspec.yaml` has `version: 1.0.1-dev.2`.

4. Save. Repeat for both packages.

If you see errors like:
- "publishing is configured to only be allowed from actions with specific ref pattern"

→ Your Tag pattern in pub.dev does not match `v{{version}}`.
  Fix the pattern and re-run the failed workflow (or push the tag again).

When both packages release in one commit, publish **core first** (`structured_logger`), then the interceptor — the interceptor depends on the new core version on pub.dev.

### Manual releases (still available)

1. Actions → **Publish to pub.dev** → Run workflow
2. Choose package, bump, prerelease flag.
3. Same CI + Melos + OIDC publish + GH release.

You can still use `melos version` + `dart pub publish` locally.

