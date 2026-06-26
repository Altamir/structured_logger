import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:structured_logger/src/logger/log_model.dart';
import 'package:structured_logger/src/logger/log_sink.dart';
import 'package:structured_logger/src/log_sinks/seq_constants.dart';

/// Sends structured log events to a [Seq](https://datalust.co/seq) server
/// using the CLEF format.
class SinkSeq extends LogSink {
  /// The Seq server URL to send logs to.
  final String seqUrl;

  /// The optional API key for the Seq server.
  final String? apiKey;

  /// Identifies the device generating logs; useful for grouping in Seq.
  final String? deviceIdentifier;

  final http.Client _client;
  final bool _ownsClient;

  /// Creates a Seq sink. [seqUrl] must be an absolute URL.
  ///
  /// Pass [client] to inject a custom HTTP client (useful in tests).
  SinkSeq(
    this.seqUrl, {
    this.apiKey,
    this.deviceIdentifier,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null {
    if (!Uri.parse(seqUrl).isAbsolute) {
      throw ArgumentError.value(
        seqUrl,
        'seqUrl',
        'The provided seqUrl is not a valid URL',
      );
    }
  }

  Uri get _eventsUri => Uri.parse(seqUrl).resolve('api/events/raw?clef');

  /// Closes the internally created [http.Client] if one was not injected.
  /// Has no effect when a client was provided via the constructor.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  /// Converts [event] to CLEF and POSTs it to the configured Seq server.
  @override
  Future<void> write(LogModel event) {
    Map<String, dynamic> data = _createClefEvent(
      event.mt,
      event.level,
      event.t,
      event.data ?? <String, dynamic>{},
    );

    return _sendToSeq(data);
  }

  Map<String, dynamic> _createClefEvent(
    String messageTemplate,
    String level,
    String timestamp,
    Map<String, dynamic> properties,
  ) {
    return {
      ...properties,
      '@t': timestamp,
      '@mt': messageTemplate,
      '@l': level,
      'DeviceIdentifier': deviceIdentifier ?? '',
    };
  }

  Future<void> _sendToSeq(Map<String, dynamic> clefEvent) async {
    final body = json.encode(clefEvent);

    try {
      final headers = {'Content-Type': CONTENT_TYPE_CLEF};
      if (apiKey != null) {
        headers[SEQ_API_KEY] = apiKey!;
      }

      final response = await _client.post(
        _eventsUri,
        headers: headers,
        body: body,
      );

      if (response.statusCode < 200 || response.statusCode >= 202) {
        if (kDebugMode) {
          print('$ERROR_SEND_TO_SEQ ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('$ERROR_SEND_TO_SEQ $e');
      }
    }
  }
}