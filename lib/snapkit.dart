import 'dart:async';

import 'package:flutter/services.dart';

class Snapkit {
  static const MethodChannel _channel = const MethodChannel('snapkit');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  StreamController<SnapchatUser> _authStatusController;
  Stream<SnapchatUser> onAuthStateChanged;

  Snapkit() {
    this._authStatusController = StreamController<SnapchatUser>();
    this.onAuthStateChanged = _authStatusController.stream;
    this._authStatusController.add(null);

    this
        .currentUser
        .then((user) => this._authStatusController.add(user))
        .catchError((error, StackTrace stacktrace) {
      this._authStatusController.add(null);
    });
  }

  /// login opens Snapchat's OAuth screen in-app or through a browser if
  /// Snapchat is not installed. It will then return the logged in `SnapchatUser`
  /// An error will be thrown if something goes wrong
  Future<SnapchatUser> login() async {
    await _channel.invokeMethod('callLogin');
    final currentUser = await this.currentUser;
    this._authStatusController.add(currentUser);
    return currentUser;
  }

  /// logout clears your apps local session and refresh tokens. You will
  /// no longer be able to make requests to fetch the `SnapchatUser` with
  /// `currentUser`. Calling this will also close the `authStatus` stream.
  Future<void> logout() async {
    await _channel.invokeMethod('callLogout');
    this._authStatusController.add(null);
    this._authStatusController.close();
  }

  /// currentUser fetches an up to date `SnapchatUser` and returns it.
  /// This will result in an error if the user was not previously logged in.
  Future<SnapchatUser> get currentUser async {
    try {
      final List<dynamic> userDetails = await _channel.invokeMethod('getUser');
      return new SnapchatUser(userDetails[0] as String,
          userDetails[1] as String, userDetails[2] as String);
    } on PlatformException catch (e) {
      if (e.code == "GetUserError" || e.code == "NetworkGetUserError")
        return null;
      else
        throw e;
    }
  }

  /// isSnapchatInstalled returns a `bool` of whether or not the Snapchat app
  /// is installed on the user's phone.
  Future<bool> get isSnapchatInstalled async {
    bool isInstalled;
    isInstalled = await _channel.invokeMethod('isInstalled');
    return isInstalled;
  }
}

class SnapchatUser {
  /// A Snapchat user's Unique ID
  final String externalId;

  /// A Snapchat user's Display Name (Not their username), can be changed by the user through Snapchat
  final String displayName;

  /// An automatic updating static URL to a Snapchat user's Bitmoji
  final String bitmojiUrl;

  SnapchatUser(this.externalId, this.displayName, this.bitmojiUrl);
}
