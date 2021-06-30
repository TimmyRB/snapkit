# Snapkit

A plugin that allows developers like you to integrate with Snapchat (using [SnapKit](https://kit.snapchat.com)) into your Flutter applications!

## Getting Started

Follow the [Wiki](https://github.com/TimmyRB/snapkit/wiki) for steps on how to get setup in an existing project or just copy the [example](example) project into a directory of your choosing and rename it.

## Usage

### Create new Instance
```dart
Snapkit snapkit = new Snapkit();
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

  snapkit.addAuthStateListener(this);

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

// or

snapkit.login().then(user => {});
```

### Logout
```dart
await snapkit.logout();

// or

snapkit.logout().then(() => {});
```

## Share to Snapchat

### Share to LIVE
```dart
snapkit.share(SnapchatMediaType.NONE,
  sticker: SnapchatSticker?,
  caption: String?,
  attachmentUrl: String?
);
```

### Share with Background Photo
```dart
snapkit.share(SnapchatMediaType.PHOTO,
  image: ImageProvider,
  sticker: SnapchatSticker?,
  caption: String?,
  attachmentUrl: String?
);
```

### Share with Background Video
Currently unavailable on Android
```dart
snapkit.share(SnapchatMediaType.VIDEO,
  videoUrl: String,
  sticker: SnapchatSticker?,
  caption: String?,
  attachmentUrl: String?
);
```

### SnapchatSticker
```dart
new SnapchatSticker(
  image: ImageProvider
);
```