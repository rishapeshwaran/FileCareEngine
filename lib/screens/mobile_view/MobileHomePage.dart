import 'package:flutter/material.dart';

import '../../api_endpoint.dart';
import 'analyze_apk_file_page.dart';
import 'analyze_image_pdf_page.dart';
import 'home_page.dart';
import 'installed_apps_page.dart';
import 'scan_pdf_page.dart';

class MobileHomePage extends StatelessWidget {
  const MobileHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0A1F44);
    const Color accentGreen = Color(0xFF1ABC9C);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "FileCareEngine",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Protecting Your Files & Applications",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),

            // CARD 1
            _buildFeatureCard(
              icon: Icons.android,
              title: "Analyze Installed Applications",
              description: "Scan apps installed on your device for threats",
              primaryBlue: primaryBlue,
              accentGreen: accentGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const InstalledAppsAnalysisPage()),
                );
              },
            ),

            const SizedBox(height: 20),

            // CARD 2
            _buildFeatureCard(
              icon: Icons.upload_file,
              title: "Analyze APK File",
              description: "Upload and analyze APK files before installation",
              primaryBlue: primaryBlue,
              accentGreen: accentGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AnalyzeApkFilePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            _buildFeatureCard(
              icon: Icons.picture_as_pdf,
              title: "Scan Image",
              description: "Detect hidden threats inside images",
              primaryBlue: primaryBlue,
              accentGreen: accentGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AnalyzeImagePage(),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            // CARD 3
            _buildFeatureCard(
              icon: Icons.picture_as_pdf,
              title: "Scan PDF Files",
              description: "Detect hidden threats inside PDF documents",
              primaryBlue: primaryBlue,
              accentGreen: accentGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // builder: (_) => const AnalyzeImagePdfPage(),
                    builder: (_) => const PdfScanPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: accentGreen,
        unselectedItemColor: primaryBlue.withOpacity(0.6),
        showUnselectedLabels: true,
        currentIndex: 0,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EndpointSettingsPage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Scan History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   selectedItemColor: accentGreen,
      //   unselectedItemColor: primaryBlue.withOpacity(0.6),
      //   showUnselectedLabels: true,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: "Home",
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.history),
      //       label: "Scan History",
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.settings),
      //       label: "Settings",
      //     ),
      //   ],
      // ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color primaryBlue,
    required Color accentGreen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: primaryBlue.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: accentGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: primaryBlue.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
