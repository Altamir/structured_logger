---
sidebar_position: 1
title: Installation
description: How to add structured_logger to your Dart or Flutter project.
---

# Installation

Add **structured_logger** as a dependency (Dart-first):

```bash
dart pub add structured_logger
```

Or for a Flutter app:

```bash
flutter pub add structured_logger
```

Add to `pubspec.yaml` (or use the command above):

```yaml
dependencies:
  structured_logger: ^1.0.0
```

Then fetch dependencies:

```bash
dart pub get
# or
flutter pub get
```

## Import

Import the package in the Dart file where you use the logger:

```dart
import 'package:structured_logger/structured_logger.dart';
```

## Transitive dependency

The package declares `http` as a dependency (used by `SinkSeq`). You do not need to add it manually unless you inject a custom `http.Client` in tests.

## Included example

The repository includes a sample app in `example/`. To run it (pure Dart CLI):

```bash
cd example
dart run lib/main.dart
```

The example registers `SimpleLineSink` and `DefaultSink` and emits a demo log. (Flutter apps continue to consume the package normally via `flutter pub add`.)