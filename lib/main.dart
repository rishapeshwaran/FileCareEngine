import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/mobile_view/MobileHomePage.dart';
import 'screens/web_view/web_home.dart';

void main() {
  runApp(const MalwareDetectionApp());
}

class MalwareDetectionApp extends StatelessWidget {
  const MalwareDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Malware Detection System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PlatformViewSwitcher(),
    );
  }
}

class PlatformViewSwitcher extends StatelessWidget {
  const PlatformViewSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const WebHomeView();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return const MobileHomePage();
      default:
        return const Scaffold(
          body: Center(
            child: Text("Unsupported Platform"),
          ),
        );
    }
  }
}
