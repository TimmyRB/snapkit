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

## 3.0.0

* Restructured the project
* Upgraded SnapSDK to 2.1.0 for Android
* Upgraded SnapSDK to 2.5.0 for iOS
* Split LoginKit & CreativeKit into their own classes
* Classes now have static references to an Instance allow calls across pages without having to pass instances around
* The current user is now saved on an instance of LoginKit allowing access across your entire app
* Added OIDC to the current user's data
* Added a caller for the access token
* Added lots of error checking in platform code and more verbose errors
* Fixed issue where videos wouldn't send on Android
* Removed deprecated Verify Phone Number

