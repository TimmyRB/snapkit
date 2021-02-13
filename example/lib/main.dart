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

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  SnapchatUser _snapchatUser;
  Snapkit _snapkit = Snapkit();

  @override
  void initState() {
    super.initState();
    initPlatformState();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                        backgroundColor: Colors.grey,
                        foregroundImage: NetworkImage(_snapchatUser.bitmojiUrl),
                      )),
                if (_snapchatUser != null) Text(_snapchatUser.externalId),
                if (_snapchatUser != null) Text(_snapchatUser.displayName),
                Text('Running on: $_platformVersion\n'),
                ElevatedButton(
                    onPressed: () {
                      _snapkit.login().then((user) {
                        setState(() {
                          _snapchatUser = user;
                        });
                      });
                    },
                    child: Text("Login with Snapchat")),
                TextButton(onPressed: () {}, child: Text("Logout"))
              ],
            ),
          )),
    );
  }
}
