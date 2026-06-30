## 1.0.3-DEV.0

 - **FIX**(clef-viewer): alinha filtro Now com timestamp CLEF. ([9cfdb097](https://github.com/Altamir/structured_logger/commit/9cfdb09729bdc8fb50f663eb01ddcbf40e139d63))

## 1.0.2

 - **FIX**(clef-viewer): alinha filtro Now com timestamp CLEF. ([9cfdb097](https://github.com/Altamir/structured_logger/commit/9cfdb09729bdc8fb50f663eb01ddcbf40e139d63))

## 1.0.2-DEV.0

 - **FIX**(clef-viewer): alinha filtro Now com timestamp CLEF. ([9cfdb097](https://github.com/Altamir/structured_logger/commit/9cfdb09729bdc8fb50f663eb01ddcbf40e139d63))

## 1.0.1

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 1.0.1-dev.5

* Republish aligned with `v{{version}}` tag workflow.

## 1.0.1-dev.3

* Republish aligned with `v{{version}}` tag workflow.

## 1.0.1-dev.2

* `SinkSeq` accepts per-event `DeviceIdentifier` from `event.data`, falling back to the sink constructor value when absent or empty.

## 1.0.1-dev.0

 - **FIX**: adiciona LICENSE e README.md nos pacotes. ([8c52242c](https://github.com/Altamir/structured_logger/commit/8c52242cbe631a7d2b38f2d790015ff8ae391192))

## 1.0.0

* **Dart-pure package**: removed all Flutter SDK and `flutter_*` dependencies. Core now publishes as pure Dart (CLI, server, Docker compatible without Flutter SDK).
* Switched tests to `package:test` and `lints`.
* Pub Workspaces + Melos monorepo layout.
* Re-export CLEF constants (`CONTENT_TYPE_CLEF`, `SEQ_API_KEY`, `ERROR_SEND_TO_SEQ`) from main barrel.
* Public API (`StructureLogger`, `SinkSeq`, sinks, LogModel etc.) unchanged. This is a major version to mark the Dart-first milestone.

## 0.1.2

* Added dartdoc comments for public API elements.
* Added `example/` directory for pub.dev documentation score.

## 0.1.1

* Fixed `SinkSeq` to send `Content-Type` header for CLEF payloads.
* Fixed CLEF reserved fields (`@t`, `@mt`, `@l`, `DeviceIdentifier`) being overwritten by `event.data`.
* Added `SinkSeq.close()` to dispose internally created `http.Client` instances.
* Fixed URL validation to throw `ArgumentError` in release builds.
* Fixed endpoint URL construction when `seqUrl` has a trailing slash.

## 0.1.0

* Added `SinkSeq` for sending structured logs to Seq (migrated from `structure_logs_sink_seq`).
* Added optional `http.Client` parameter to `SinkSeq` for testability.
* Added `http` dependency.

## 0.0.2

* Fix readme.
* Fix example.
* fix exports.


## 0.0.1

* Initial release of the `structured_logger` package.
* Added `StructureLogger` for implementing structured logs in Flutter applications.
* Included the `SimpleLineSink` as a sample Sink for sending logs to the terminal.
* Introduced the `LogSink` interface for custom log destination implementations.
* Illustrative usage examples for basic logging and adding custom Sinks.
* Instructions for package installation and contribution.
* License information included.
