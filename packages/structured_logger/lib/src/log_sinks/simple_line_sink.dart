import 'package:structured_logger/src/logger/log_model.dart';
import 'package:structured_logger/src/logger/log_sink.dart';

/// Prints a single human-readable line by interpolating [LogModel.data] into
/// the message template.
class SimpleLineSink extends LogSink {
  /// Creates a [SimpleLineSink].
  SimpleLineSink();

  @override
  Future<void> write(LogModel event) async {
    String msTemplate = event.mt;

    String message = msTemplate.replaceAllMapped(
      RegExp(r'{(.*?)}'),
      (match) => event.data?[match.group(1)]?.toString() ?? '',
    );

    print(message);
  }
}
