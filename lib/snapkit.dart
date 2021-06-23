import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';

class Snapkit {
  static const MethodChannel _channel = const MethodChannel('snapkit');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  late StreamController<SnapchatUser?> _authStatusController;
  late Stream<SnapchatUser?> onAuthStateChanged;

  late SnapchatAuthStateListener _authStateListener;

  Snapkit() {
    this._authStatusController = StreamController<SnapchatUser?>();
    this.onAuthStateChanged = _authStatusController.stream;
    this._authStatusController.add(null);

    this.currentUser.then((user) {
      this._authStatusController.add(user);
      this._authStateListener.onLogin(user);
    }).catchError((error, StackTrace stacktrace) {
      this._authStatusController.add(null);
      this._authStateListener.onLogout();
    });
  }

  void addAuthStateListener(SnapchatAuthStateListener authStateListener) {
    this._authStateListener = authStateListener;
  }

  /// login opens Snapchat's OAuth screen in-app or through a browser if
  /// Snapchat is not installed. It will then return the logged in `SnapchatUser`
  /// An error will be thrown if something goes wrong
  Future<SnapchatUser> login() async {
    await _channel.invokeMethod('callLogin');
    final currentUser = await this.currentUser;
    this._authStatusController.add(currentUser);
    this._authStateListener.onLogin(currentUser);
    return currentUser;
  }

  /// logout clears your apps local session and refresh tokens. You will
  /// no longer be able to make requests to fetch the `SnapchatUser` with
  /// `currentUser`. Calling this will also close the `authStatus` stream.
  Future<void> logout() async {
    await _channel.invokeMethod('callLogout');
    this._authStatusController.add(null);
    this._authStateListener.onLogout();
    this._authStatusController.close();
  }

  /// currentUser fetches an up to date `SnapchatUser` and returns it.
  /// This will result in an error if the user was not previously logged in.
  Future<SnapchatUser> get currentUser async {
    try {
      final List<dynamic> userDetails =
          (await _channel.invokeMethod('getUser')) as List<dynamic>;
      return new SnapchatUser(userDetails[0] as String,
          userDetails[1] as String, userDetails[2] as String);
    } on PlatformException catch (e) {
      throw e;
    }
  }

  /// Share shares Media to be sent in the Snapchat app. A Type & Url supplied
  /// through `mediaType` and `mediaUrl` will be the background, with the
  /// `Sticker` being a User adjustable image, the `Caption` being User editable
  /// text, and the `AttachmentUrl` will be an attached link User's can access
  /// by swiping upwards when they view the Snap
  Future<void> share(SnapchatMediaType mediaType,
      {ImageProvider<Object>? image,
      String? videoUrl,
      SnapchatSticker? sticker,
      String? caption,
      String? attachmentUrl}) async {
    assert(caption != null ? caption.length <= 250 : true);

    Completer<File?> c = new Completer<File?>();

    if (mediaType == SnapchatMediaType.PHOTO) {
      assert(image != null);
      image!
          .resolve(new ImageConfiguration())
          .addListener(new ImageStreamListener((imageInfo, _) async {
        String path = (await getTemporaryDirectory()).path;
        ByteData? byteData =
            await imageInfo.image.toByteData(format: ImageByteFormat.png);
        ByteBuffer buffer = byteData!.buffer;

        File file = await new File('$path/image.png').writeAsBytes(
            buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

        c.complete(file);
      }));
    } else {
      c.complete(null);
    }

    if (mediaType == SnapchatMediaType.VIDEO) assert(videoUrl != null);

    File? imageFile = await c.future;

    await _channel.invokeMethod('sendMedia', <String, dynamic>{
      'mediaType':
          mediaType.toString().substring(mediaType.toString().indexOf('.') + 1),
      'imagePath': imageFile?.path,
      'videoUrl': videoUrl,
      'sticker': sticker != null ? await sticker.toMap() : null,
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
  /// Url to the Image to be used as a Sticker
  ImageProvider<Object> image;

  SnapchatSticker({required this.image});

  Future<Map<String, dynamic>> toMap() async {
    Completer<Map<String, dynamic>> c = new Completer<Map<String, dynamic>>();

    this
        .image
        .resolve(new ImageConfiguration())
        .addListener(new ImageStreamListener((imageInfo, _) async {
      String path = (await getTemporaryDirectory()).path;
      ByteData? byteData =
          await imageInfo.image.toByteData(format: ImageByteFormat.png);
      ByteBuffer buffer = byteData!.buffer;
      File file = await File('$path/sticker.png').writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

      c.complete(<String, dynamic>{
        'imagePath': file.path,
      });
    }));

    return c.future;
  }
}

abstract class SnapchatAuthStateListener {
  void onLogin(SnapchatUser? user);
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
