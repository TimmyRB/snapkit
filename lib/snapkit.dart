import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';

class Snapkit {
  static const MethodChannel _channel = const MethodChannel('snapkit');

  /// platformVersion returns a `String` of the current platform
  /// the appplication is running on, it usally includes both the
  /// Operating System name eg (iOS / Android) and the Version
  /// Number eg (15 / 12)
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  late StreamController<SnapchatUser?> _authStatusController;
  late Stream<SnapchatUser?> onAuthStateChanged;

  SnapchatAuthStateListener? _authStateListener;

  /// Creates a new `Snapkit` instance
  Snapkit() {
    this._authStatusController = new StreamController<SnapchatUser?>();
    this.onAuthStateChanged = this._authStatusController.stream;
    this._authStatusController.add(null);

    this.currentUser.then((user) {
      this._authStatusController.add(user);
      this._authStateListener?.onLogin(user);
    }).catchError((error, StackTrace stacktrace) {
      this._authStatusController.add(null);
      this._authStateListener?.onLogout();
    });
  }

  /// Add a class that implements the `SnapchatAuthStateListener` class as
  /// a listener
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
    this._authStateListener?.onLogin(currentUser);
    return currentUser;
  }

  /// logout clears your apps local session and refresh tokens. You will
  /// no longer be able to make requests to fetch the `SnapchatUser` with
  /// `currentUser`. Call `closeStream()` to close the stream and prevent a
  /// resource sink.
  Future<void> logout() async {
    await _channel.invokeMethod('callLogout');
    this._authStatusController.add(null);
    this._authStateListener?.onLogout();
  }

  /// Closes the `AuthState` Stream
  void closeStream() {
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

  /// share shares Media to be sent in the Snapchat app. `mediaType`
  /// defines what type of background media is to be shared.
  /// `SnapchatMediaType.PHOTO` requires `image` to be non null.
  /// `SnapchatMediaType.VIDEO` requires `videoUrl` to be non null.
  /// `SnapchatMediaType.NONE` allows the User to take a photo or
  /// video
  ///
  /// `caption`, `sticker` and `attachmentUrl` are optional
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

  /// Creates a new `SnapchatUser`
  SnapchatUser(this.externalId, this.displayName, this.bitmojiUrl);
}

class SnapchatSticker {
  /// Url to the Image to be used as a Sticker
  ImageProvider<Object> image;

  /// Creates a new `SnapchatSticker`
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

enum SnapchatButtonColors {
  /// Snapchat Yellow
  YELLOW,

  /// Snapchat Black
  BLACK,

  /// Snapchat White
  WHITE,

  /// Snapchat Gray
  GRAY
}

extension SnapchatButtonExtension on SnapchatButtonColors {
  /// Gets the Button Color value associated with ENUM
  Color get color {
    switch (this) {
      case SnapchatButtonColors.YELLOW:
        return const Color.fromRGBO(255, 252, 0, 1);
      case SnapchatButtonColors.BLACK:
        return const Color.fromRGBO(0, 0, 0, 1);
      case SnapchatButtonColors.WHITE:
        return const Color.fromRGBO(255, 255, 255, 1);
      case SnapchatButtonColors.GRAY:
        return const Color.fromRGBO(244, 244, 244, 1);
    }
  }

  /// Gets the Text Color to contrast button color
  Color get textColor {
    switch (this) {
      case SnapchatButtonColors.BLACK:
        return const Color.fromRGBO(255, 255, 255, 1);
      default:
        return const Color.fromRGBO(0, 0, 0, 1);
    }
  }

  /// Gets the Image to contrast button color
  AssetImage get ghost {
    switch (this) {
      case SnapchatButtonColors.BLACK:
        return AssetImage('assets/images/GhostLogoDark.png',
            package: 'snapkit');
      default:
        return AssetImage('assets/images/GhostLogoLight.png',
            package: 'snapkit');
    }
  }
}

class SnapchatButtonFontOptions {
  /// Change the `Text` font size
  final double? fontSize;

  /// Change the `Text` font weight
  final FontWeight? fontWeight;

  /// Change the `Text` font family
  final String? fontFamily;

  /// Change the `Text` font family fallback(s)
  final List<String>? fontFamilyFallback;

  /// Change the `Text` font features
  final List<FontFeature>? fontFeatures;

  /// Change the `Text` font style
  final FontStyle? fontStyle;

  /// Custom Font Options
  ///
  /// WARNING: Changing these will mean the button no longer follows
  /// Snapchat's Brand Guidelines
  SnapchatButtonFontOptions({
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontFeatures,
    this.fontStyle,
  });
}

class SnapchatButton extends StatelessWidget {
  /// Additional Font Options to change text
  final SnapchatButtonFontOptions? fontOptions;

  /// Desired Button Color
  final SnapchatButtonColors buttonColor;

  /// Snapkit Object used by button to Login
  final Snapkit snapkit;

  /// Creates a new `SnapchatButton` that by default conforms to
  /// Snapchat's Brand Guidelines
  const SnapchatButton({
    Key? key,
    required this.snapkit,
    this.buttonColor = SnapchatButtonColors.YELLOW,
    this.fontOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButtonTheme(
      data: TextButtonThemeData(
          style: ButtonStyle(
              shape: MaterialStateProperty.resolveWith<OutlinedBorder>(
                (states) => RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                  (states) => buttonColor.color),
              padding: MaterialStateProperty.resolveWith<EdgeInsetsGeometry>(
                  (states) => EdgeInsets.only(
                      left: 22, top: 20, right: 22, bottom: 20)))),
      child: TextButton(
        onPressed: () => this.snapkit.login(),
        style: ButtonStyle(
            padding: MaterialStateProperty.resolveWith<EdgeInsets>(
                (states) => EdgeInsets.all(16.0))),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.only(right: 16.0),
              child: Image(
                image: buttonColor.ghost,
                fit: BoxFit.contain,
                height: 32.0,
                width: 32.0,
              ),
            ),
            Text(
              "Login with Snapchat",
              style: TextStyle(
                color: this.buttonColor.textColor,
                fontFamily: this.fontOptions?.fontFamily,
                fontFamilyFallback: this.fontOptions?.fontFamilyFallback,
                fontFeatures: this.fontOptions?.fontFeatures,
                fontSize: this.fontOptions?.fontSize,
                fontStyle: this.fontOptions?.fontStyle,
                fontWeight: this.fontOptions?.fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
