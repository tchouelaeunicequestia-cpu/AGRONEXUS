import 'package:flutter/foundation.dart' show kIsWeb;

import 'runtime_platform.dart' show isAndroid;

String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8080';
  } else if (isAndroid) {
    return 'http://10.0.2.2:8080';
  } else {
    return 'http://localhost:8080';
  }
}