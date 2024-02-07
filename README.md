# Snapkit

[![Pub Package](https://img.shields.io/pub/v/snapkit.svg)](https://pub.dev/packages/snapkit)
[![Code Analysis](https://github.com/TimmyRB/snapkit/actions/workflows/code-analysis.yml/badge.svg)](https://github.com/TimmyRB/snapkit/actions/workflows/code-analysis.yml) 
[![Android Builds](https://github.com/TimmyRB/snapkit/actions/workflows/build-android.yml/badge.svg)](https://github.com/TimmyRB/snapkit/actions/workflows/build-android.yml) 
[![iOS Builds](https://github.com/TimmyRB/snapkit/actions/workflows/build-ios.yml/badge.svg)](https://github.com/TimmyRB/snapkit/actions/workflows/build-ios.yml) 

A plugin that allows developers like you to integrate with Snapchat (using [Snapchat's Native SnapKit](https://kit.snapchat.com)) in your Flutter applications!

Contents:

 - [What's New](#✨-whats-new)
 - [Installation](#🛠️-installation)
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


## ✏️ Usage