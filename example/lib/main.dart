import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:snapkit/snapkit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements SnapchatAuthStateListener {
  GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  String _platformVersion = 'Unknown';
  SnapchatUser _snapchatUser;
  Snapkit _snapkit = Snapkit();

  bool _isSnackOpen = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();

    _snapkit.addAuthStateListener(this);

    // _snapkit.onAuthStateChanged.listen((SnapchatUser user) {
    //   setState(() {
    //     _snapchatUser = user;
    //   });
    // });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Snapkit.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> loginUser() async {
    try {
      bool installed = await _snapkit.isSnapchatInstalled;
      if (installed)
        await _snapkit.login();
      else if (!_isSnackOpen) {
        _isSnackOpen = true;
        _scaffoldMessengerKey.currentState
            .showSnackBar(
                SnackBar(content: Text("Snapchat App not Installed.")))
            .closed
            .then((_) {
          _isSnackOpen = false;
        });
      }
    } on PlatformException catch (exception) {
      print(exception);
    }
  }

  Future<void> logoutUser() async {
    try {
      await _snapkit.logout();
    } on PlatformException catch (exception) {
      print(exception);
    }

    setState(() {
      _snapchatUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Snapkit Example App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_snapchatUser != null)
                Container(
                    width: 50,
                    height: 50,
                    margin: EdgeInsets.all(15),
                    child: CircleAvatar(
                      backgroundColor: Colors.lightBlue,
                      foregroundImage: NetworkImage(_snapchatUser.bitmojiUrl),
                    )),
              if (_snapchatUser != null) Text(_snapchatUser.displayName),
              if (_snapchatUser != null)
                Text(_snapchatUser.externalId,
                    style: TextStyle(color: Colors.grey, fontSize: 9.0)),
              Text('Running on: $_platformVersion\n'),
              if (_snapchatUser == null)
                ElevatedButton(
                    onPressed: () => loginUser(),
                    child: Text("Login with Snapchat")),
              if (_snapchatUser != null)
                TextButton(onPressed: () => logoutUser(), child: Text("Logout"))
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _snapkit.share(SnapchatMediaType.PHOTO,
                image: NetworkImage(
                    "https://picsum.photos/${(this.context.size.width.round())}/${this.context.size.height.round()}.jpg"),
                sticker: SnapchatSticker(
                    image: NetworkImage(
                        "https://jacobbrasil.com/icons/icon-256x256.png?v=abb739a0a176ce4cc7e9ff069dee372c")),
                caption: "Snapkit Example Caption!",
                attachmentUrl: "https://JacobBrasil.com/");
          },
          child: Icon(Icons.camera),
        ),
      ),
    ));
  }

  @override
  void onLogin(SnapchatUser user) {
    setState(() {
      _snapchatUser = user;
    });
  }

  @override
  void onLogout() {
    setState(() {
      _snapchatUser = null;
    });
  }
}
