import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snapkit/creativekit.dart';

class CreativeKitSticker {
  /// The sticker to add to the snap.
  final ImageProvider image;

  /// The size of the sticker relative to the snap.
  final CreativeStickerSize size;

  /// The offset of the sticker relative to the snap.
  final CreativeKitStickerOffset offset;

  /// The rotation of the sticker.
  final CreativeKitStickerRotation rotation;

  const CreativeKitSticker(
    this.image,
    this.size, {
    this.offset = const CreativeKitStickerOffset(0, 0),
    this.rotation = const CreativeKitStickerRotation(0),
  });

  Future<Map<String, dynamic>> toMap() async {
    Completer<File> fileCompleter = Completer<File>();
    final path = (await getTemporaryDirectory()).path;

    image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener(
            (info, _) async {
              ByteData? byteData =
                  await info.image.toByteData(format: ImageByteFormat.png);

              if (byteData == null) {
                fileCompleter.completeError(
                  CreativeKitException(
                      'Failed to convert sticker image to byte data'),
                );
                return;
              }

              ByteBuffer buffer = byteData.buffer;
              File file = await File('$path/sticker.png').writeAsBytes(
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

    File stickerFile = await fileCompleter.future;
    return {
      'path': stickerFile.path,
      'size': size.toMap(),
      'offset': offset.toMap(),
      'rotation': rotation.toMap(),
    };
  }
}

class CreativeStickerSize {
  /// The width of the sticker relative to the snap.
  final double width;

  /// The height of the sticker relative to the snap.
  final double height;

  const CreativeStickerSize(this.width, this.height);

  Map<String, double> toMap() {
    return {'width': width, 'height': height};
  }
}

class CreativeKitStickerOffset {
  /// The x offset of the sticker relative to the left of the snap.
  /// Must be between 0 and 1.
  final double x;

  /// The y offset of the sticker relative to the top of the snap.
  /// Must be between 0 and 1.
  final double y;

  const CreativeKitStickerOffset(this.x, this.y)
      : assert(x >= 0 && x <= 1 && y >= 0 && y <= 1);

  Map<String, double> toMap() {
    return {'x': x, 'y': y};
  }
}

class CreativeKitStickerRotation {
  /// The angle of the sticker in degrees.
  final double angle;

  const CreativeKitStickerRotation(this.angle);

  Map<String, double> toMap() {
    return {'angle': angle};
  }
}
