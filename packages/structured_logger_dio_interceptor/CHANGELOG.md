## 0.1.0

* Initial release of `structured_logger_dio_interceptor`.
* `DioLoggingInterceptor` takes a pre-configured `StructureLogger` (positional) and optional `correlationalHeaderName`.
* Emits REQUEST / RESPONSE / ON_ERROR Log Events with templates, correlational ID, elapsedTime, full headers/payloads.
* Delegates transport to sinks on the injected logger (no direct Seq HTTP).
* `deviceIdentifier` belongs on `SinkSeq`, not the interceptor.
