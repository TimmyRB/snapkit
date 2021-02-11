
import 'dart:async';

import 'package:flutter/services.dart';

class Snapkit {
  static const MethodChannel _channel =
      const MethodChannel('snapkit');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
