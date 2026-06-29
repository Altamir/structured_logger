## 1.0.0-DEV.0

 - **FEAT**(interceptor): resolve and log query parameters from request options. ([6549c6e6](https://github.com/Altamir/structured_logger/commit/6549c6e65964ec1850f46adc05f4ae473f496549))
 - **FEAT**(interceptor): queryParam.* e ofuscação de JWT. ([78c694e5](https://github.com/Altamir/structured_logger/commit/78c694e59a9b43bf2ba0c7087978208f8c4c10ec))

## 1.0.0-dev.5

* Bump `structured_logger` dependency to `^1.0.1-dev.5`.

## 1.0.0-dev.4

* Extract `queryParam.*` from query strings embedded in the request URL when `queryParameters` is empty.
* Log `path` without the query string for consistent REQUEST / RESPONSE / ON_ERROR events.

## 1.0.0-dev.3

* Bump `structured_logger` dependency to `^1.0.1-dev.3`.

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
