import 'dart:async';

import 'package:flutter/services.dart';

class Ijkplayerview {
  static const MethodChannel _channel =
      const MethodChannel('ijkplayerview');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
