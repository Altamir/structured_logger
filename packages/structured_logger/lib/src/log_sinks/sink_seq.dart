import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:structured_logger/src/logger/log_model.dart';
import 'package:structured_logger/src/logger/log_sink.dart';
import 'package:structured_logger/src/log_sinks/seq_constants.dart';

const bool _kDebugMode = !bool.fromEnvironment('dart.vm.product');

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
    final props = Map<String, dynamic>.from(properties);
    final eventDevice = props.remove('DeviceIdentifier') as String?;
    final resolvedDevice = (eventDevice != null && eventDevice.isNotEmpty)
        ? eventDevice
        : (deviceIdentifier ?? '');

    return {
      ...props,
      '@t': timestamp,
      '@mt': messageTemplate,
      '@l': level,
      'DeviceIdentifier': resolvedDevice,
    };
  }

  Future<void> _sendToSeq(Map<String, dynamic> clefEvent) async {
    final body = json.encode(clefEvent);

    try {
      final headers = <String, String>{'Content-Type': CONTENT_TYPE_CLEF};
      if (apiKey != null) {
        headers[SEQ_API_KEY] = apiKey!;
      }

      var uri = _eventsUri;
      const maxRedirects = 3;

      for (var attempt = 0; attempt <= maxRedirects; attempt++) {
        final response = await _client.post(
          uri,
          headers: headers,
          body: body,
        );

        if (response.statusCode >= 200 && response.statusCode < 202) {
          return;
        }

        final redirectUri = _redirectTarget(uri, response);
        if (redirectUri != null && attempt < maxRedirects) {
          uri = redirectUri;
          continue;
        }

        if (_kDebugMode) {
          final detail = response.body.isEmpty
              ? '${response.statusCode}'
              : '${response.statusCode} ${response.body}';
          print('$ERROR_SEND_TO_SEQ $detail');
        }
        return;
      }
    } catch (e) {
      if (_kDebugMode) {
        print('$ERROR_SEND_TO_SEQ $e');
      }
    }
  }

  /// Traefik and similar proxies often return 301/308 for http→https; the
  /// `http` package does not follow POST redirects automatically.
  Uri? _redirectTarget(Uri requestUri, http.Response response) {
    final code = response.statusCode;
    if (code != 301 &&
        code != 302 &&
        code != 303 &&
        code != 307 &&
        code != 308) {
      return null;
    }

    final location = response.headers['location'];
    if (location == null || location.isEmpty) {
      return null;
    }

    return requestUri.resolve(location);
  }
}
