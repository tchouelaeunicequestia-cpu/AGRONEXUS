// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation: reads/writes from browser localStorage.
void writeToStorage(String key, String value) {
  html.window.localStorage[key] = value;
}

String? readFromStorage(String key) {
  return html.window.localStorage[key];
}
