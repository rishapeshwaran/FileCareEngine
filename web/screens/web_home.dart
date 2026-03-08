import 'package:flutter/material.dart';

class WebHomeView extends StatelessWidget {
  const WebHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Web Malware Analyzer"),
      ),
      body: const Center(
        child: Text(
          "This is Web View",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
