import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../api_endpoint.dart';
import 'image_scan_result_page.dart';

class AnalyzeImagePage extends StatefulWidget {
  const AnalyzeImagePage({super.key});

  @override
  State<AnalyzeImagePage> createState() => _AnalyzeImagePageState();
}

class _AnalyzeImagePageState extends State<AnalyzeImagePage> {
  File? selectedFile;
  bool isUploading = false;

  Color primaryBlue = Color(0xFF0A1F44);
  Color accentGreen = Color(0xFF1ABC9C);

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'tiff', 'svg', 'gif'],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null) return;

    setState(() => isUploading = true);

    var request = http.MultipartRequest(
      'POST',
      // Uri.parse("http://10.10.51.167:8000/scan/malware"),
      Uri.parse("$ENDPOINT/scan/malware"),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        selectedFile!.path,
      ),
    );

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    final jsonResponse = jsonDecode(responseData);

    setState(() => isUploading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageScanResultPage(result: jsonResponse),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text("Scan Image "),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.image_search, color: Colors.white, size: 60),
                  SizedBox(height: 10),
                  Text(
                    "Deep File Analysis",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Detect hidden threats & phishing files",
                    style: TextStyle(color: Colors.white70),
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),

            /// UPLOAD CARD
            Center(
              child: GestureDetector(
                onTap: pickFile,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: accentGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.upload_file,
                          size: 50,
                          color: accentGreen,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Tap to Upload File",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Supports Images",
                        style: TextStyle(color: Colors.black54),
                      )
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (selectedFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file, color: accentGreen),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedFile!.path.split('/').last,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 30),

            if (selectedFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: uploadFile,
                    child: const Text("Analyze File"),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            if (isUploading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Uploading & Scanning...")
                ],
              )
          ],
        ),
      ),
    );
  }
}
