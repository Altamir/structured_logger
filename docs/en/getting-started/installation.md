---
sidebar_position: 1
title: Installation
description: How to add structured_logger to your Flutter project.
---

# Installation

Add **structured_logger** as a dependency in your app or package `pubspec.yaml`:

```yaml
dependencies:
  structured_logger: ^0.1.2
```

Then fetch dependencies:

```bash
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

The repository includes a sample app in `example/`. To run it:

```bash
cd example
flutter run
```

The example registers `SimpleLineSink` and `DefaultSink` and emits a demo log.