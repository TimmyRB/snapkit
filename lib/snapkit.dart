import 'dart:async';

import 'package:flutter/services.dart';

class Snapkit {
  static const MethodChannel _channel = const MethodChannel('snapkit');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<SnapchatUser> login() async {
    await _channel.invokeMethod('callLogin');
    List<dynamic> userDetails = await _channel.invokeMethod('getUser');
    return new SnapchatUser(userDetails[0] as String, userDetails[1] as String,
        userDetails[2] as String);
  }
}

class SnapchatUser {
  String externalId;
  String displayName;
  String bitmojiUrl;

  SnapchatUser(String externalId, String displayName, String bitmojiUrl) {
    this.externalId = externalId;
    this.displayName = displayName;
    this.bitmojiUrl = bitmojiUrl;
  }
}
