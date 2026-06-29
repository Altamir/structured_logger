## 1.0.0-dev.2

* **Breaking:** remove property `queryParams`; each query param is emitted as `queryParam.<name>` (filterable in CLEF Viewer).
* **Breaking:** REQUEST template no longer includes `{queryParams}` placeholder.
* Obfuscate JWT strings in logged headers, query params, and bodies (6-char prefix + `...***`).

## 1.0.0-dev.1

* `DioLoggingInterceptor` maps `X-device-id` request header to per-event `DeviceIdentifier` (configurable via `deviceHeaderName`).
* Message templates aligned with `StructureLogger` (`{property}` placeholders); request/response bodies kept as properties only.

## 0.1.0

* Initial release of `structured_logger_dio_interceptor`.
* `DioLoggingInterceptor` takes a pre-configured `StructureLogger` (positional) and optional `correlationalHeaderName`.
* Emits REQUEST / RESPONSE / ON_ERROR Log Events with templates, correlational ID, elapsedTime, full headers/payloads.
* Delegates transport to sinks on the injected logger (no direct Seq HTTP).
* Default `deviceIdentifier` belongs on `SinkSeq`, with per-request override from `X-device-id` when present.
