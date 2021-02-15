import 'dart:async';

import 'package:flutter/services.dart';

class Snapkit {
  static const MethodChannel _channel = const MethodChannel('snapkit');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  bool isLoggedIn;

  Snapkit() {
    this.isLoggedIn = false;
  }

  Future<SnapchatUser> login() async {
    await _channel.invokeMethod('callLogin');
    this.isLoggedIn = true;
    final currentUser = await this.currentUser;
    return currentUser;
  }

  Future<void> logout() async {
    await _channel.invokeMethod('callLogout');
    this.isLoggedIn = false;
  }

  Future<SnapchatUser> get currentUser async {
    assert(isLoggedIn);
    final List<dynamic> userDetails = await _channel.invokeMethod('getUser');
    return new SnapchatUser(userDetails[0] as String, userDetails[1] as String,
        userDetails[2] as String);
  }

  Future<bool> get isSnapchatInstalled async {
    final bool isInstalled = await _channel.invokeMethod('isInstalled');
    return isInstalled;
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
