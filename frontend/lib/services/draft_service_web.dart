import 'package:web/web.dart' as web;

/// Web implementation: reads/writes from browser localStorage.
void writeToStorage(String key, String value) {
  web.window.localStorage.setItem(key, value);
}

String? readFromStorage(String key) {
  return web.window.localStorage.getItem(key);
}
