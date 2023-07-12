## 0.0.1

* Initial release.

## 0.0.2

* Added AndroidX Support
* Added Bitmoji Kit

## 1.0.0

* First actual release
* Adds iOS Support
* Redoes Android Support
* Bump up to SnapKit 1.10.0

## 1.0.2

* Fixed AuthState Stream
* Fixed Warning when not using SnapchatAuthStateListener class
* Added Usage Documentation

## 1.1.0

* Added a new SnapchatButton Widget that follows Snapchat's Brand Guidelines

## 1.2.0

* Added Phone Number verification through Snapchat

## 1.2.1

* Improved package classes & methods documentation
* Moved SnapchatButton to it's own file

## 1.2.2

* Bug fixes

## 2.0.0

* Fixed Stickers not appearing on Android clients
* Added additional options to Stickers for fine tuning
* Fixed an issue where a user not sharing their Bitmoji would cause an exception
* Fixed Videos not working on Android Clients
* Fixed an issue where some Videos wouldn't work despite meeting Snapchat's Video requirements
* Bug fixes & Code improvements

# 3.0.0

* **BREAKING CHANGE:** Upgraded Snap Kit on Android to 2.1.0.
  When updating this plugin, please perform the following changes to your app:
  * in `android/build.gradle`, remove the following:

    ```groovy
    maven {
        url "https://storage.googleapis.com/snap-kit-build/maven"
    }
    ```

  * in `android/app/build.gradle`, remove the following:

    ```groovy
    implementation([
            'com.snapchat.kit.sdk:creative:1.10.0',
            'com.snapchat.kit.sdk:login:1.10.0',
            'com.snapchat.kit.sdk:bitmoji:1.10.0',
            'com.snapchat.kit.sdk:core:1.10.0'
    ])
    ```

  * in `android/app/src/main/AndroidManifest.xml`:
    * change `com.snapchat.kit.sdk.clientId` to `com.snap.kit.clientId`
    * change `com.snapchat.kit.sdk.redirectUrl` to `com.snap.kit.redirectUrl`
    * change `com.snapchat.kit.sdk.scopes` to `com.snap.kit.scopes"`
    * remove the following:

      ```xml
      <queries>
          <package android:name="com.snapchat.android" />
      </queries>
      ```

* Widened `http` support to >=0.13.3 <2.0.0
