// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? readAuthStorage(String key) {
  return html.window.sessionStorage[key];
}

void writeAuthStorage(String key, String value) {
  html.window.sessionStorage[key] = value;
}

void removeAuthStorage(String key) {
  html.window.sessionStorage.remove(key);
}