# Structured Logs
structured_logger

## Description
The ``structured_logger`` package provides an easy way to implement structured logs in your Flutter applications. It allows sending logs to different destinations, such as the terminal or external services, through interfaces called ``Sinks``. The package includes a sample Sink, SimpleLineSink, which sends logs to the terminal.

## Installation
Add the following to your pubspec.yaml file:

```yaml
  structured_logger: ^current_version
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

Register logs using the log method:

```dart
await logger.log(
  "Welcome {name}, your level is {level}",
  level: LogLevel.info,
  data: {"name": "John Doe", "level": 12},
);
```

terminal output [Fist line is written by SimpleLineSink, and second line is written by DefaultSink.]:
```log 
Seja bem vindo John Doe, seu nível é 12
[log] {@t: 2023-12-19T15:38:06.563023, @mt: Seja bem vindo {name}, seu nível é {level}, @l: info, data: {name: John Doe, level: 12}}
```

Fist line is written by SimpleLineSink, and second line is written by DefaultSink.



This is a simple example, and you can customize Sinks and log data as needed. For example, you can create a Sink that sends logs to an external service, such as Seq or Elastic. (Or use another package that already does this, such as (WIP)).

