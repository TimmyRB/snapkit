# Snapkit

[![Pub Package](https://img.shields.io/pub/v/snapkit.svg)](https://pub.dev/packages/snapkit)
[![Code Analysis](https://github.com/TimmyRB/snapkit/actions/workflows/code-analysis.yml/badge.svg)](https://github.com/TimmyRB/snapkit/actions/workflows/code-analysis.yml)
[![Android Builds](https://github.com/TimmyRB/snapkit/actions/workflows/build-android.yml/badge.svg)](https://github.com/TimmyRB/snapkit/actions/workflows/build-android.yml)
[![iOS Builds](https://github.com/TimmyRB/snapkit/actions/workflows/build-ios.yml/badge.svg)](https://github.com/TimmyRB/snapkit/actions/workflows/build-ios.yml)

A plugin that allows developers like you to integrate with Snapchat (using [SnapKit](https://kit.snapchat.com)) into your Flutter applications!

## Getting Started

Follow the [Wiki](https://github.com/TimmyRB/snapkit/wiki) for steps on how to get setup in an existing project or just copy the [example](example) project into a directory of your choosing and rename it.

## Usage

### Create new Instance

```dart
final snapkit = Snapkit();
```

### AuthState Stream

```dart
snapkit.onAuthStateChanged.listen((SnapchatUser? user) {
    // Do something with the returned SnapchatUser or null here
});
```

### AuthState Class

```dart
class MyAppState extends State<MyApp> implements SnapchatAuthStateListener {
  @override
  void initState() {
    super.initState();
    _snapkit.addAuthStateListener(this);
  }

  @override
  void onLogin(SnapchatUser user) {
    // Do something with the returned SnapchatUser here
  }

  @override
  void onLogout() {
    // Do something on logout
  }
}
```

### Login

```dart
await snapkit.login();
```

### Logout

```dart
await snapkit.logout();
```

### Verify a Phone Number

Returns a `bool` if Snapchat has verified the phone number, throws
an error if there was a problem. Always returns `false` on Android.

```dart
try {
  final isVerified = snapkit.verifyPhoneNumber('US', '1231234567');
} catch (error, stackTrace) {
  // Handle error
}
```

## Share to Snapchat

### Share to LIVE

```dart
snapkit.share(
  SnapchatMediaType.NONE,
  sticker: SnapchatSticker?,
  caption: String?,
  attachmentUrl: String?
);
```

### Share with Background Photo

```dart
snapkit.share(
  SnapchatMediaType.PHOTO,
  image: ImageProvider,
  sticker: SnapchatSticker?,
  caption: String?,
  attachmentUrl: String?,
);
```

### Share with Background Video

Currently unavailable on Android.

```dart
snapkit.share(
  SnapchatMediaType.VIDEO,
  videoUrl: String,
  sticker: SnapchatSticker?,
  caption: String?,
  attachmentUrl: String?,
);
```

### SnapchatSticker

```dart
SnapchatSticker(
  image: ImageProvider,
);
```
