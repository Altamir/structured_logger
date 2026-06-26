---
sidebar_position: 1
title: Instalação
description: Como adicionar structured_logger ao seu projeto Dart ou Flutter.
---

# Instalação

Adicione **structured_logger** como dependência (Dart-first):

```bash
dart pub add structured_logger
```

Ou para app Flutter:

```bash
flutter pub add structured_logger
```

Adicione ao `pubspec.yaml` (ou use o comando):

```yaml
dependencies:
  structured_logger: ^1.0.0
```

Em seguida, baixe as dependências:

```bash
dart pub get
# ou
flutter pub get
```

## Importação

Importe o pacote no arquivo Dart em que for usar o logger:

```dart
import 'package:structured_logger/structured_logger.dart';
```

## Dependência transitiva

O pacote declara `http` como dependência (usada pelo `SinkSeq`). Você não precisa adicioná-la manualmente, a menos que injete um `http.Client` customizado nos testes.

## Exemplo incluído

O repositório contém um app de exemplo em `example/`. Para executá-lo (CLI Dart puro):

```bash
cd example
dart run lib/main.dart
```

O exemplo registra `SimpleLineSink` e `DefaultSink` e emite um log de demonstração. (Apps Flutter continuam usando o pacote normalmente via `flutter pub add`.)