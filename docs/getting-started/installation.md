---
sidebar_position: 1
title: Instalação
description: Como adicionar structured_logger ao seu projeto Flutter.
---

# Instalação

Adicione **structured_logger** como dependência no `pubspec.yaml` do seu app ou pacote:

```yaml
dependencies:
  structured_logger: ^0.1.2
```

Em seguida, baixe as dependências:

```bash
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

O repositório contém um app de exemplo em `example/`. Para executá-lo:

```bash
cd example
flutter run
```

O exemplo registra `SimpleLineSink` e `DefaultSink` e emite um log de demonstração.