# Snapkit

[![Pub Package](https://img.shields.io/pub/v/snapkit.svg)](https://pub.dev/packages/snapkit)
[![Code Analysis](https://github.com/TimmyRB/snapkit/actions/workflows/code-analysis.yml/badge.svg)](https://github.com/TimmyRB/snapkit/actions/workflows/code-analysis.yml)
[![Android Builds](https://github.com/TimmyRB/snapkit/actions/workflows/build-android.yml/badge.svg)](https://github.com/TimmyRB/snapkit/actions/workflows/build-android.yml)
[![iOS Builds](https://github.com/TimmyRB/snapkit/actions/workflows/build-ios.yml/badge.svg)](https://github.com/TimmyRB/snapkit/actions/workflows/build-ios.yml)

A plugin that allows developers like you to integrate with Snapchat (using [Snapchat's Native SnapKit](https://kit.snapchat.com)) in your Flutter applications!

Contents:

 - [What's New](#✨-whats-new)
 - [Installation](#🛠️-installation)
	 - [Upgrading](#upgrading-from-older-versions)
   - [iOS Setup](#-ios-setup)
   - [Android Setup](#🤖-android-setup)
 - [Usage](#✏️-usage)

## ✨ What's new

This flutter plugin has now been updated to 3.0.0 and contains breaking changes from any project using versions <= 2.0.0. This plugin now uses the following versions for Snapchat's native SDKs.

```
iOS: ~2.5.0
Android: ~2.1.0
```

## 🛠️ Installation

Add it to your project
```
flutter pub add snapkit
```

Import it
```dart
import 'package:snapkit/snapkit.dart';
```

The following setup instructions assume you have created an app on the [Snapchat Developer Portal](https://devportal.snap.com/manage/) and have enabled 'Login Kit', 'Bitmoji Kit' & 'Creative Kit' in your app's settings. Make sure to setup a redirect URI in the 'Login Kit' settings and add your Snapchat username as a demo user in the general tab.

### Upgrading from older versions

On iOS the Installation is the same as before, however on Android you will need to modify and remove a few lines if you're upgrading from < 3.0.0.

Firstly, remove this line from your `app/android/build.grade`

```groovy
maven {
  url "https://storage.googleapis.com/snap-kit-build/maven"
}
```

Next, in your `app/android/app/build.grade`, remove these lines

```groovy
  implementation([
    'com.snapchat.kit.sdk:creative:1.10.0',
    'com.snapchat.kit.sdk:login:1.10.0',
    'com.snapchat.kit.sdk:bitmoji:1.10.0',
    'com.snapchat.kit.sdk:core:1.10.0'
])
```

Finally, in your `app/android/app/src/main/AndroidManifest.xml`

Change the following
```xml
com.snapchat.kit.sdk.clientId → com.snap.kit.clientId
com.snapchat.kit.sdk.redirectUrl → com.snap.kit.redirectUrl
com.snapchat.kit.sdk.scopes → com.snap.kit.scopes
```

And remove these lines
```xml
<queries>
  <package android:name="com.snapchat.android" />
</queries>
```

###  iOS Setup

Add the following to your `Info.plist` in `app/ios/Runner/`. Make sure to replace `YOUR_CLIENT_ID_HERE`, `YOUR_REDIRECT_URL_HERE` & `YOUR_URL_SCHEME_HERE` with the correct information from your [Snapchat Developer Portal](https://devportal.snap.com/manage/)

```plist
<key>SCSDKClientId</key>
<string>YOUR_CLIENT_ID_HERE</string>
<key>SCSDKRedirectUrl</key>
<string>YOUR_REDIRECT_URL_HERE</string>
<key>SCSDKScopes</key>
<array>
	<string>https://auth.snapchat.com/oauth2/api/user.display_name</string>
	<string>https://auth.snapchat.com/oauth2/api/user.bitmoji.avatar</string>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
	<string>snapchat</string>
	<string>bitmoji-sdk</string>
	<string>itms-apps</string>
</array>
<key>CFBundleURLSchemes</key>
<array>
	<string>YOUR_URL_SCHEME_HERE</string>
</array>
```

Your redirect url should be in a similar format and must match one of the redirect URIs you should've made in the Login Kit settings on the [Snapchat Developer Portal](https://devportal.snap.com/manage/)
```
myapp://snapkit/oauth2
```

Your url scheme is the text that comes before `://` in your redirect url, so if you are using the redirect url above, your url scheme would be
```
myapp
```

Next in XCode, open `Runner.xcworkspace` from `app/ios/`, then in `Runner → Targets → Runner → Info` scroll to the bottom of the `Info` tab, expand `URL Types` and press the add + button. Set the identifer to be your application's bundle identifier e.g. `com.example.app` and set URL schemes to be the url scheme you determined above, e.g. `myapp`.

Finally, add the following to your `AppDelegate.swift` file in `app/ios/Runner/` in order to be able to use the redirect url you just created

```swift
import UIKit
import Flutter
import SCSDKLoginKit // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
	override func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
	) -> Bool {
		GeneratedPluginRegistrant.register(with: self)
		return super.application(application, didFinishLaunchingWithOptions: launchOptions)
	}
	
	// Add this function
	override func application(
		_ app: UIApplication,
		open url: URL,
		options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
			return SCSDKLoginClient.application(app, open: url, options: options)
		}
}
```

### 🤖 Android Setup

Add the following to your `AndroidMainfest.xml` in `app/android/app/src/main` Make sure to replace `YOUR_CLIENT_ID_HERE`, `YOUR_SCHEME`, `YOUR_HOST` & `YOUR_PATH` with the correct information from your [Snapchat Developer Portal](https://devportal.snap.com/manage/)

`YOUR_SCHEME://YOUR_HOST/YOUR_PATH` Is your redirect URL from the Developer Portal that you should've made when enabling LoginKit. You will need to split up these redirect url segements in the `SnapKitActivity` block.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
	<application
		android:label="snapkit_example"
		android:name="${applicationName}"
		android:icon="@mipmap/ic_launcher">

	<meta-data
		android:name="com.snap.kit.clientId"
		android:value="YOUR_CLIENT_ID_HERE" />

	<meta-data
		android:name="com.snap.kit.redirectUrl"
		android:value="YOUR_SCHEME://YOUR_HOST/YOUR_PATH" />

	<meta-data
		android:name="com.snap.kit.scopes"
		android:resource="@array/snap_connect_scopes" />

	<activity
		android:name="com.snap.corekit.SnapKitActivity"
		android:launchMode="singleTask"
		android:exported="true">
		<intent-filter>
			<action android:name="android.intent.action.VIEW" />
			<category android:name="android.intent.category.DEFAULT" />
			<category android:name="android.intent.category.BROWSABLE" />
			<!-- Change this to match your redirect URL -->
			<data
				android:scheme="YOUR_SCHEME"
				android:host="YOUR_HOST"
				android:path="/YOUR_PATH" />
		</intent-filter>
	</activity>

	<!-- Add this if you want to use the Creative Kit -->
	<provider
		android:name="androidx.core.content.FileProvider"
		android:authorities="${applicationId}.fileprovider"
		android:exported="false"
		android:grantUriPermissions="true">
		<meta-data
			android:name="android.support.FILE_PROVIDER_PATHS"
			android:resource="@xml/file_paths" />
	</provider>

...
```

Create a file named `arrays.xml` in `app/android/app/src/main/res/values` with the following content
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string-array name="snap_connect_scopes">
        <item>https://auth.snapchat.com/oauth2/api/user.bitmoji.avatar</item>
        <item>https://auth.snapchat.com/oauth2/api/user.display_name</item>
        <item>https://auth.snapchat.com/oauth2/api/user.external_id</item>
    </string-array>
</resources>
```

Create another file named `file_paths.xml` in `app/android/app/src/main/res/xml` with the following
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <root-path name="root" path="." />
</paths>
```


## ✏️ Usage

Determine if Snapchat is installed on a user's device
```dart
await SnapKit.I.isSnapchatInstalled() → bool
```

Check the version of the native SnapSDK running
```dart
await SnapKit.I.getSnapSDKVersion() → String
```

### LoginKit

This Kit is used for authenticating with the user's Snapchat account. Using this Kit allows you to get a user's External ID, OIDC, Display Name, Bitmoji URL & Access Token.

Check if a user is already logged in
```dart
await LoginKit.I.isLoggedIn() → bool
```

Start the login flow
```dart
await LoginKit.I.login()
```

Logging in automatically fetchs the user's data from Snapchat, however if you need to refresh it for whatever reason you can do so manually
```dart
await LoginKit.I.getCurrentUser()
```

Since only one user can be authenticated with Snapchat at a time on a device, the current user and their data is found here
```dart
LoginKit.I.currentUser → SnapchatUser
```

Retrieve the access token like this
```dart
await LoginKit.I.getAccessToken() → String?
```

Logout the user and unlink from the current session
```dart
await LoginKit.I.logout()
```

### CreativeKit

This Kit is used for sharing photos, videos, stickers and more to Snapchat from inside your app. This Kit does **not** require the user be authenticated with LoginKit.

#### Media Size and Length Restrictions:

Shared media must be 300 MB or smaller.\
Videos must be 60 seconds or shorter.\
Videos that are longer than 10 seconds are split up into multiple Snaps of 10 seconds or less.

#### Suggested Media Parameters:

Aspect Ratio: 9:16\
Preferred Image File Types: .jpg or .png\
Preferred Video File Types: .mp4 or .mov\
Dimensions: 1080px x 1920px\
Video Bitrate: 1080p at 8mbps or 720p at 5mbps

Create a Sticker
```dart
var sticker = CreativeKitSticker(
		AssetImage('assets/image.png'),
		size: StickerSize(32, 32),
		offset: StickerOffset(0.5, 0.5),
		rotation: StickerRotation(30),
	);
```

Share to the Snapchat Camera
```dart
CreativeKit.I.shareToCamera(
	sticker: sticker,
	caption: 'This is Awesome!',
	link: Uri.parse('https://jacobbrasil.com/'),
)
```

Share with a background Photo
```dart
CreativeKit.I.shareWithPhoto(
	AssetImage('assets/image.png'),
	sticker: sticker,
	caption: 'This is Awesome!',
	link: Uri.parse('https://jacobbrasil.com/'),
)
```

Share with a background Video that's available locally
```dart
CreativeKit.I.shareWithVideo(
	DefaultAssetBundle.of(context).load('assets/video.mp4'),
	sticker: sticker,
	caption: 'This is Awesome!',
	link: Uri.parse('https://jacobbrasil.com/'),
)
```

Share with a background Video that's available online
```dart
CreativeKit.I.shareWithRemoteVideo(
	Uri.parse('https://link.to/video.mp4'),
	sticker: sticker,
	caption: 'This is Awesome!',
	link: Uri.parse('https://jacobbrasil.com/'),
)
```
