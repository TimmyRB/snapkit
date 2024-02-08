import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:snapkit/snapkit.dart';

import 'snapkit_platform_interface.dart';

export 'snapchat_user.dart';

enum LoginKitEvent { loggedIn, loggedOut, updated }

class LoginKitException implements Exception {
  final String message;

  LoginKitException(this.message);

  @override
  String toString() {
    return 'LoginKitException: $message\n${StackTrace.current.toString()}';
  }
}

class LoginKit {
  /// The instance of [LoginKit] to use.
  /// LoginKit is used to authenticate users with Snapchat.
  static LoginKit I = LoginKit();

  /// The current Snapchat user.
  /// Will be `null` if the user is not logged in.
  SnapchatUser? get currentUser => _currentUser;

  SnapchatUser? _currentUser;

  final StreamController<LoginKitEvent> _authEventsController =
      StreamController<LoginKitEvent>.broadcast();

  /// A stream of Snapchat authentication events.
  ///
  /// Emits [LoginKitEvent.loggedIn] when the user logs in,
  /// [LoginKitEvent.loggedOut] when the user logs out,
  /// and [LoginKitEvent.updated] when the user data is updated.
  Stream<LoginKitEvent> get authEvents => _authEventsController.stream;

  /// Close the [authEvents] stream.
  /// Call this method when the [LoginKit] instance is no longer needed.
  void closeEventsStream() {
    _authEventsController.close();
  }

  LoginKit() {
    isLoggedIn().then((isLoggedIn) {
      if (isLoggedIn) {
        try {
          getCurrentUser();
        } on LoginKitException catch (e) {
          if (kDebugMode) {
            print(
                'Error while getting current user automatically: ${e.message}');
          }
        }
      }
    });
  }

  /// Checks if the user is logged into your app with Snapchat.
  Future<bool> isLoggedIn() async {
    return (await SnapkitPlatform.instance.isLoggedIn()) ?? false;
  }

  /// Logs the user into Snapchat.
  Future<void> login() async {
    await SnapkitPlatform.instance.login();
    await _getCurrentUser(event: LoginKitEvent.loggedIn);
  }

  /// Gets the current Snapchat user and sets it to [currentUser].
  /// Make sure to only call this method after the user has logged in before.
  ///
  /// Throws a [LoginKitException] if the user data is invalid.
  /// Writes non-fatal partial errors to the console in debug mode.
  Future<void> getCurrentUser() async {
    await _getCurrentUser();
  }

  Future<void> _getCurrentUser({
    LoginKitEvent event = LoginKitEvent.updated,
  }) async {
    Map<String, String?>? data =
        await SnapkitPlatform.instance.getCurrentUser();

    if (data == null) {
      throw LoginKitException('Failed to get current user');
    }

    if (data['errors'] != null) {
      if (kDebugMode) {
        print('Snapkit.getCurrentUser() Partial Errors: ${data['errors']}');
      }
    }

    if (data['externalId'] == null || data['displayName'] == null) {
      throw LoginKitException('Invalid user data');
    }

    _currentUser = SnapchatUser(
      data['externalId']!,
      data['displayName']!,
      data['bitmoji2DAvatarUrl'],
      data['bitmojiAvatarId'],
    );
    _authEventsController.add(event);
  }

  /// Logs the Snapchat user out of your app.
  Future<void> logout() async {
    await SnapkitPlatform.instance.logout();

    _currentUser = null;
    _authEventsController.add(LoginKitEvent.loggedOut);
  }
}
