import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:snapkit/snapkit.dart';

import 'snapkit_platform_interface.dart';

/// An implementation of [SnapkitPlatform] that uses method channels.
class MethodChannelSnapkit extends SnapkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('snapkit');

  @override
  Future<bool?> isSnapchatInstalled() async {
    return await methodChannel.invokeMethod<bool>('isSnapchatInstalled');
  }

  @override
  Future<bool?> isLoggedIn() async {
    return await methodChannel.invokeMethod<bool>('isLoggedIn');
  }

  @override
  Future<void> login() async {
    try {
      await methodChannel.invokeMethod<void>('login');
    } on PlatformException catch (e) {
      if (e.code == 'LoginError') {
        throw LoginKitException(e.message ?? '');
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, String?>?> getCurrentUser() async {
    return await methodChannel
        .invokeMapMethod<String, String?>('getCurrentUser');
  }

  @override
  Future<void> logout() async {
    await methodChannel.invokeMethod<void>('logout');
  }

  @override
  Future<void> shareToCamera(
    Map<String, dynamic>? sticker,
    String? caption,
    String? link,
  ) async {
    await methodChannel.invokeMethod<void>(
      'shareToCamera',
      <String, dynamic>{
        'sticker': sticker,
        'caption': caption,
        'link': link,
      },
    );
  }

  @override
  Future<void> shareWithPhoto(
    String photoPath,
    Map<String, dynamic>? sticker,
    String? caption,
    String? link,
  ) async {
    await methodChannel.invokeMethod<void>(
      'shareWithPhoto',
      <String, dynamic>{
        'photoPath': photoPath,
        'sticker': sticker,
        'caption': caption,
        'link': link,
      },
    );
  }
}
