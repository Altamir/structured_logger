import 'dart:async';
import 'dart:html' as html;

import '../config/api_config.dart';
import '../models/log_filter.dart';

/// Streams admin export to a browser download without buffering in Dart memory.
class ExportDownloader {
  static Future<void> downloadClefExport({
    required String apiKey,
    LogFilter? filter,
  }) async {
    final params = filter?.toQueryParams() ?? {};
    final uri = ApiConfig.uri(
      '/api/admin/export',
      queryParameters: params.isEmpty ? null : params,
    );

    final completer = Completer<void>();
    final xhr = html.HttpRequest();
    xhr.open('GET', uri.toString());
    xhr.setRequestHeader('X-Seq-ApiKey', apiKey);
    xhr.responseType = 'blob';

    xhr.onLoad.listen((_) {
      if (xhr.status != 200) {
        if (xhr.status == 401) {
          completer.completeError(UnauthorizedExportException());
        } else {
          completer.completeError(
            Exception('Export failed: HTTP ${xhr.status}'),
          );
        }
        return;
      }

      final disposition = xhr.getResponseHeader('Content-Disposition') ?? '';
      final filenameMatch =
          RegExp(r'filename="([^"]+)"').firstMatch(disposition);
      final filename = filenameMatch?.group(1) ?? 'logs-export.clef';

      final blob = xhr.response as html.Blob;
      final objectUrl = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: objectUrl)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(objectUrl);
      anchor.remove();
      completer.complete();
    });

    xhr.onError.listen((_) {
      completer.completeError(Exception('Export network error'));
    });

    xhr.send();
    return completer.future;
  }
}

class UnauthorizedExportException implements Exception {}