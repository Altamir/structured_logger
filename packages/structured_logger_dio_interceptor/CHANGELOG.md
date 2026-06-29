## 0.1.1-dev.0

 - **FIX**: adiciona LICENSE e README.md nos pacotes. ([8c52242c](https://github.com/Altamir/structured_logger/commit/8c52242cbe631a7d2b38f2d790015ff8ae391192))

## 0.1.0

* Initial release of `structured_logger_dio_interceptor`.
* `DioLoggingInterceptor` takes a pre-configured `StructureLogger` (positional) and optional `correlationalHeaderName`.
* Emits REQUEST / RESPONSE / ON_ERROR Log Events with templates, correlational ID, elapsedTime, full headers/payloads.
* Delegates transport to sinks on the injected logger (no direct Seq HTTP).
* `deviceIdentifier` belongs on `SinkSeq`, not the interceptor.
