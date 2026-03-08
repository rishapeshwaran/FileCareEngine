import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  PlatformFile? selectedFile;
  bool isScanning = false;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['apk', 'pdf', 'zip'],
    );

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  Future<void> startScan() async {
    if (selectedFile == null) return;

    setState(() => isScanning = true);

    // ⏳ simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => isScanning = false);

    // 🚀 Navigate to result screen
    Navigator.pushNamed(context, '/result', arguments: {
      "fileName": selectedFile!.name,
      "verdict": "Malware",
      "confidence": 92.4
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Malware Scan"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.security, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "Upload a file to scan",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.upload_file, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      selectedFile?.name ?? "Tap to select file",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isScanning ? null : startScan,
                child: isScanning
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Scan File"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
