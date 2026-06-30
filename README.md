# Structured Logger Monorepo

[![CI](https://github.com/Altamir/structured_logger/actions/workflows/ci.yml/badge.svg)](https://github.com/Altamir/structured_logger/actions/workflows/ci.yml)

This is the monorepo for **Structured Logger** — Dart-first structured logging with pluggable sinks (CLEF/Seq, console, etc.).

- Core package: `packages/structured_logger` (Dart pure, v1.0.2)
- Dio interceptor: `packages/structured_logger_dio_interceptor` (v1.2.0)
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
  structured_logger: ^1.0.2
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

The repository uses a **pre-release / master** flow. Everything runs in a single workflow ([`ci.yml`](.github/workflows/ci.yml)):

- `pre-release` — integration branch. Feature PRs target `pre-release`.
- `master` — stable. Promotion PRs go `pre-release` → `master`.

| Event | What runs |
|-------|-----------|
| PR open → `pre-release` | Tests + preview images (`-DEV-PR`) + preview docs |
| PR open → `master` | Tests only |
| **Merge** PR → `pre-release` | Dev version bump, tags → [`publish.yml`](.github/workflows/publish.yml), DEV images, docs |
| **Merge** PR `pre-release` → `master` | Stable graduate, tags → `publish.yml`, sync `pre-release`, `:latest` images, prod docs, version-bump PR |
| **Merge** PR `chore/release-*` → `master` | Tests only (sync pubspecs; does **not** re-run release) |
| Push → `pre-release` or `master` | Tests only |

### Automated flow (preferred)

1. Open PR → `pre-release` → CI runs tests + PR preview images/docs (`-DEV-PR`).
2. **Merge** the PR → `prerelease-release` job runs:
   - Full CI
   - `melos version --yes --prerelease --preid=DEV --no-git-tag-version`
   - Creates tags `vX.Y.Z-dev.N` (one per versioned package)
   - Pushes tags `vX.Y.Z-dev.N` → triggers [`publish.yml`](.github/workflows/publish.yml) (pub.dev requires **tag push**, not `pull_request`)
   - Creates GitHub **pre-release** per `v*` tag
   - Pushes DEV images (tags with `-DEV`, no `:latest`) + docs to CF `pre-release` branch
3. When ready: open PR `pre-release` → `master` (tests only while open).
4. **Merge the promotion PR** (`pre-release` → `master`) → `stable-release` job runs (other merges into `master`, including `chore/release-*`, do **not** trigger this):
   - `melos version --yes --graduate` (or conventional stable) with `--no-git-tag-version`
   - Pushes final `vX.Y.Z` tags → triggers `publish.yml` on pub.dev
   - **Syncs `pre-release`** with graduated versions (so the next dev cycle starts from stable, not stale `-dev` versions)
   - Opens a **follow-up PR** `chore/release-*` with pubspec bumps (because `master` blocks direct push)
5. **Merge the `chore/release-*` PR** to sync `master` pubspecs (CI runs tests only — no new release, tags, or chore PR).
   - Stable GitHub release per `v*` tag (already created in step 4)
   - Images with `:latest` + docs to CF `master` (already deployed in step 4)

### Keeping `pre-release` in sync with `master`

After a stable release, `stable-release` pushes the graduated commit to `pre-release` automatically. That way the next feature merge on `pre-release` bumps from the stable version (e.g. `1.0.2-dev.1`), not an old `-dev` counter.

`master` pubspecs are updated separately when you merge the `chore/release-*` PR (required because `master` is protected). Until that merge, `pre-release` may show stable versions before `master` does — that is expected.

**Requirement:** `pre-release` must allow push from `github-actions[bot]` (unprotected branch, or bypass for the bot).

### Protected `master` (no bypass required)

`master` does not accept direct push from Actions. The workflow does **not** need a bypass list or personal access token:

1. After your promotion PR merges, `stable-release` graduates versions, publishes to pub.dev, pushes **tags**, and opens `chore/release-<run_id>` → `master`.
2. You merge that small PR (pubspec/CHANGELOG only).

### GitHub Actions permissions (required once)

In **Settings → Actions → General → Workflow permissions**:

1. Select **Read and write permissions**
2. Enable **Allow GitHub Actions to create and approve pull requests**

Without step 2, `gh pr create` fails with `GitHub Actions is not permitted to create or approve pull requests`.

### Why publish is dispatched (not inline in the merge job)

pub.dev OIDC **rejects** `dart pub publish` from `pull_request` events. After `ci.yml` pushes tags, it dispatches [`publish.yml`](.github/workflows/publish.yml) via `workflow_dispatch` with `publish_sha`.

Tags pushed by `GITHUB_TOKEN` in CI **do not** trigger other workflows (GitHub anti-recursion), so `on: push: tags` alone is not enough for automated releases.

If publish failed after a release, run **Actions → Publish to pub.dev → Run workflow** with:

- **publish_sha**: the release commit SHA (from the `stable-release` or `prerelease-release` job log)

### Prerequisites (pub.dev Automated publishing) — IMPORTANT

Faça isso **uma única vez** para cada pacote (https://pub.dev):

1. Package admin → **Automated publishing**
2. Enable:
   - "Enable publishing from workflow_dispatch events"
   - "Enable publishing from push events" (required — `publish.yml` runs on **tag push**)
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

