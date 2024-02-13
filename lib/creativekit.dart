import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snapkit/creativekit_sticker.dart';
import 'package:snapkit/snapkit_platform_interface.dart';
import 'package:http/http.dart' as http;

export 'creativekit_sticker.dart';

class CreativeKitException implements Exception {
  final String message;

  CreativeKitException(this.message);

  @override
  String toString() {
    return 'CreativeKitException: $message\n${StackTrace.current.toString()}';
  }
}

class CreativeKit {
  /// The instance of [CreativeKit] to use.
  /// CreativeKit is used to share media to Snapchat.
  static CreativeKit I = CreativeKit();

  /// Share to Snapchat and let the user take their own snap.
  ///
  /// [sticker] is an optional sticker to add to the snap.
  ///
  /// [caption] is an optional caption to add to the snap, must be max 250 characters.
  ///
  /// [link] is an optional link to add to the snap.
  Future<void> shareToCamera({
    CreativeKitSticker? sticker,
    String? caption,
    Uri? link,
  }) async {
    // caption cannot be longer than 250 characters
    assert(caption != null ? caption.length <= 250 : true);

    await SnapkitPlatform.instance.shareToCamera(
      await sticker?.toMap(),
      caption,
      link.toString(),
    );
  }

  /// Share to Snapchat with a background photo.
  /// Photos must be 300MB or less and a PNG.
  ///
  /// [photo] is the photo to share to the background of the snap.
  ///
  /// [sticker] is an optional sticker to add to the snap.
  ///
  /// [caption] is an optional caption to add to the snap, must be max 250 characters.
  ///
  /// [link] is an optional link to add to the snap.
  Future<void> shareWithPhoto(
    ImageProvider photo, {
    CreativeKitSticker? sticker,
    String? caption,
    Uri? link,
  }) async {
    // caption cannot be longer than 250 characters
    assert(caption != null ? caption.length <= 250 : true);

    Completer<File> fileCompleter = Completer<File>();
    final path = (await getTemporaryDirectory()).path;

    photo.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener(
            (info, _) async {
              ByteData? byteData =
                  await info.image.toByteData(format: ImageByteFormat.png);

              if (byteData == null) {
                fileCompleter.completeError(
                  CreativeKitException('Failed to convert photo to byte data'),
                );
                return;
              }

              ByteBuffer buffer = byteData.buffer;
              File file = await File('$path/image.png').writeAsBytes(
                buffer.asUint8List(
                  byteData.offsetInBytes,
                  byteData.lengthInBytes,
                ),
              );

              fileCompleter.complete(file);
            },
            onError: (dynamic exception, StackTrace? stackTrace) {
              fileCompleter.completeError(exception, stackTrace);
            },
          ),
        );

    File photoFile = await fileCompleter.future;
    await SnapkitPlatform.instance.shareWithPhoto(
      photoFile.path,
      await sticker?.toMap(),
      caption,
      link.toString(),
    );
  }

  /// Share to Snapchat with a local background video.
  /// Videos must be 300MB or less, 60 seconds or shorter and a MP4 or MOV.
  /// Videos longer than 10 seconds will be split into multiple snaps.
  ///
  /// [video] is the video to share to the background of the snap.
  ///
  /// [sticker] is an optional sticker to add to the snap.
  ///
  /// [caption] is an optional caption to add to the snap, must be max 250 characters.
  ///
  /// [link] is an optional link to add to the snap.
  Future<void> shareWithVideo(
    Future<ByteData> videoData, {
    CreativeKitSticker? sticker,
    String? caption,
    Uri? link,
  }) async {
    // caption cannot be longer than 250 characters
    assert(caption != null ? caption.length <= 250 : true);

    Completer<File> fileCompleter = Completer<File>();
    final path = (await getTemporaryDirectory()).path;

    videoData.then((byteData) async {
      ByteBuffer buffer = byteData.buffer;
      File file = await File('$path/video.mp4').writeAsBytes(
        buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );

      fileCompleter.complete(file);
    });

    File videoFile = await fileCompleter.future;
    await SnapkitPlatform.instance.shareWithVideo(
      videoFile.path,
      await sticker?.toMap(),
      caption,
      link.toString(),
    );
  }

  /// Share to Snapchat with a remote background video.
  /// Videos must be 300MB or less, 60 seconds or shorter and a MP4 or MOV.
  /// Videos longer than 10 seconds will be split into multiple snaps.
  ///
  /// WARNING: This method will download the video to the device before sharing
  /// which may take a long time and use a lot of data.
  /// Use [shareWithVideo] if you have the video locally.
  ///
  /// [videoUrl] is the url of the video to share to the background of the snap.
  ///
  /// [sticker] is an optional sticker to add to the snap.
  ///
  /// [caption] is an optional caption to add to the snap, must be max 250 characters.
  ///
  /// [link] is an optional link to add to the snap.
  Future<void> shareWithRemoteVideo(
    Uri videoUrl, {
    CreativeKitSticker? sticker,
    String? caption,
    Uri? link,
  }) async {
    // caption cannot be longer than 250 characters
    assert(caption != null ? caption.length <= 250 : true);

    final res = await http.get(videoUrl);
    final path = (await getTemporaryDirectory()).path;

    final videoFile = File('$path/video.mp4');
    await videoFile.writeAsBytes(res.bodyBytes);

    await SnapkitPlatform.instance.shareWithVideo(
      videoFile.path,
      await sticker?.toMap(),
      caption,
      link.toString(),
    );
  }
}
