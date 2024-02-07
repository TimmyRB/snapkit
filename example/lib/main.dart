import 'package:flutter/material.dart';
import 'package:snapkit/snapkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isSnapchatInstalled = false;

  @override
  void initState() {
    super.initState();

    LoginKit.I.authEvents.listen((event) {
      Future.delayed(Duration.zero, () {
        setState(() {});
      });
    });

    SnapKit.I.isSnapchatInstalled().then((value) {
      setState(() {
        _isSnapchatInstalled = value;
      });
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
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: LoginKit.I.currentUser?.bitmoji2DAvatarUrl !=
                        null
                    ? NetworkImage(LoginKit.I.currentUser!.bitmoji2DAvatarUrl!)
                    : null,
                radius: 50,
              ),
              const SizedBox(height: 16),
              Text(
                LoginKit.I.currentUser?.displayName ?? '',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                LoginKit.I.currentUser?.externalId ?? '',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      LoginKit.I.login();
                    },
                    child: const Text('Login'),
                  ),
                  TextButton(
                    onPressed: () {
                      LoginKit.I.logout().then((_) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                            content: Text('Logged out of App'),
                          ),
                        );
                      });
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                  'Snapchat installed: ${_isSnapchatInstalled ? 'Yes' : 'No'}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      CreativeKit.I.shareToCamera(
                        sticker: const CreativeKitSticker(
                          NetworkImage(
                            'https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png',
                          ),
                        ),
                        caption: 'SnapKit Share to Camera!',
                        link: Uri.parse('https://kit.snapchat.com'),
                      );
                    },
                    child: const Text('Share to Camera'),
                  ),
                  TextButton(
                    onPressed: () {
                      CreativeKit.I.shareWithPhoto(
                        const NetworkImage(
                          'https://img.freepik.com/free-vector/dark-gradient-background-with-copy-space_53876-99548.jpg?size=626&ext=jpg',
                        ),
                        sticker: const CreativeKitSticker(
                          NetworkImage(
                            'https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png',
                          ),
                        ),
                        caption: 'SnapKit Share with Photo!',
                        link: Uri.parse('https://kit.snapchat.com'),
                      );
                    },
                    child: const Text('Share with Photo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
