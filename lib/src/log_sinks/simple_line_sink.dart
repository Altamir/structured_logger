import 'package:structured_logger/src/logger/log_model.dart';
import 'package:structured_logger/src/logger/log_sink.dart';

class SimpleLineSink extends LogSink {
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
