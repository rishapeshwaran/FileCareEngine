// import 'package:flutter/material.dart';

// class AppDetailsDialog extends StatelessWidget {
//   final Map<String, dynamic> app;

//   const AppDetailsDialog({super.key, required this.app});

//   @override
//   Widget build(BuildContext context) {
//     final permissions = List<String>.from(app["permissions"] ?? []);

//     return AlertDialog(
//       title: Text(app["appName"] ?? "App"),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text("Package: ${app["packageName"]}"),
//               Text("Version: ${app["versionName"]}"),
//               Text("Installer: ${app["installer"] ?? "Not Available"}"),
//               Text("System App: ${app["isSystemApp"]}"),
//               Text("Debuggable: ${app["isDebuggable"]}"),
//               const SizedBox(height: 10),
//               const Text(
//                 "Permissions:",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 5),
//               permissions.isEmpty
//                   ? const Text("No permissions")
//                   : Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: permissions.map((p) => Text("• $p")).toList(),
//                     )
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text("Close"),
//         )
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';

class AppDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> app;

  const AppDetailsDialog({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final permissions = List<String>.from(app["permissions"] ?? []);

    const Color primaryBlue = Color(0xFF0A1F44);
    const Color accentGreen = Color(0xFF1ABC9C);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.android,
                      color: accentGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      app["appName"] ?? "Application",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// APP INFO SECTION
              _infoRow("Package", app["packageName"]),
              _infoRow("Version", app["versionName"]),
              // _infoRow("Installer", app["installer"] ?? "Not Available"),
              // _infoRow(
              //     "System App", (app["isSystemApp"] ?? false) ? "Yes" : "No"),
              // _infoRow(
              //     "Debuggable", (app["isDebuggable"] ?? false) ? "Yes" : "No"),

              const SizedBox(height: 20),

              /// PERMISSIONS TITLE
              const Text(
                "Permissions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 10),

              permissions.isEmpty
                  ? const Text(
                      "No permissions declared",
                      style: TextStyle(color: Colors.black54),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: permissions
                          .map(
                            (p) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: accentGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                p,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: accentGreen,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

              const SizedBox(height: 25),

              /// CLOSE BUTTON
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    const Color primaryBlue = Color(0xFF0A1F44);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            TextSpan(
              text: value?.toString() ?? "Not Available",
            ),
          ],
        ),
      ),
    );
  }
}
