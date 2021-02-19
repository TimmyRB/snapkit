import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Snapkit {
  static const MethodChannel _channel = const MethodChannel('snapkit');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  StreamController<SnapchatUser> _authStatusController;
  Stream<SnapchatUser> onAuthStateChanged;

  SnapchatAuthStateListener authStateListener;

  Snapkit() {
    this._authStatusController = StreamController<SnapchatUser>();
    this.onAuthStateChanged = _authStatusController.stream;
    this._authStatusController.add(null);

    this.currentUser.then((user) {
      this._authStatusController.add(user);
      this.authStateListener.onLogin(user);
    }).catchError((error, StackTrace stacktrace) {
      this._authStatusController.add(null);
      this.authStateListener.onLogout();
    });
  }

  void addAuthStateListener(SnapchatAuthStateListener authStateListener) {
    this.authStateListener = authStateListener;
  }

  /// login opens Snapchat's OAuth screen in-app or through a browser if
  /// Snapchat is not installed. It will then return the logged in `SnapchatUser`
  /// An error will be thrown if something goes wrong
  Future<SnapchatUser> login() async {
    await _channel.invokeMethod('callLogin');
    final currentUser = await this.currentUser;
    this._authStatusController.add(currentUser);
    this.authStateListener.onLogin(currentUser);
    return currentUser;
  }

  /// logout clears your apps local session and refresh tokens. You will
  /// no longer be able to make requests to fetch the `SnapchatUser` with
  /// `currentUser`. Calling this will also close the `authStatus` stream.
  Future<void> logout() async {
    await _channel.invokeMethod('callLogout');
    this._authStatusController.add(null);
    this.authStateListener.onLogout();
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

  Future<void> share(SnapchatMediaType mediaType,
      {String mediaUrl,
      SnapchatSticker sticker,
      String caption,
      String attachmentUrl}) async {
    assert(
        mediaType != null && (caption != null ? caption.length <= 250 : true));
    if (mediaType != SnapchatMediaType.NONE) assert(mediaUrl != null);
    await _channel.invokeMethod('sendMedia', <String, dynamic>{
      'mediaType':
          mediaType.toString().substring(mediaType.toString().indexOf('.') + 1),
      'mediaUrl': mediaUrl,
      'sticker': sticker != null ? sticker.toMap() : null,
      'caption': caption,
      'attachmentUrl': attachmentUrl
    });
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

class SnapchatSticker {
  /// Width of the Sticker Image, must be above 0.0
  double width;

  /// Height of the Sticker Image, must be above 0.0
  double height;

  /// Position of the Sticker from the left as percentage, must be between 0.0 and 100.0
  double positionX;

  /// Position of the Stick from the top as percentage, must be between 0.0 and 100.0
  double positionY;

  /// Rotation of the Sticker clockwise, must be between 0.0 and 360.0
  double rotation;

  /// Url to the Image to be used as a Sticker
  String imageUrl;

  /// Whether or not the Sticker Image is animated
  bool isAnimated;

  SnapchatSticker(this.imageUrl, this.isAnimated,
      {this.width, this.height, this.positionX, this.positionY, this.rotation})
      : assert(
            imageUrl != null && isAnimated != null,
            width > 0 &&
                height > 0 &&
                positionX >= 0 &&
                positionX <= 100 &&
                positionY >= 0 &&
                positionY <= 100 &&
                rotation >= 0 &&
                rotation <= 360);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "width": this.width,
      "height": this.height,
      "x": this.positionX,
      "y": this.positionY,
      "rotation": this.rotation,
      "imageUrl": this.imageUrl,
      "animated": this.isAnimated
    };
  }
}

abstract class SnapchatAuthStateListener {
  void onLogin(SnapchatUser user);
  void onLogout();
}

enum SnapchatMediaType {
  /// Share a Photo
  PHOTO,

  /// Share a Video
  VIDEO,

  /// Let the User take their own Photo or Video
  NONE
}
