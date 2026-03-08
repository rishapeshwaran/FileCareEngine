import 'package:flutter/material.dart';
import '../../services/app_install_source.dart';
import '../../services/malware_api_service.dart';
import '../../widgets/app_details_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> apps = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadApps();
  }

  void loadApps() async {
    final result = await AppInstallSource.getAllInstalledApps();

    setState(() {
      apps = result;
      loading = false;
    });
  }

  void showDetails(Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (_) => AppDetailsDialog(app: app),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Installed Applications")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                print("App: ${app["appName"]}, Installer: ${app["installer"]}");
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app["appName"] ?? "",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(app["packageName"] ?? ""),
                        Text("Installer: ${app["installer"] ?? "Unknown"}"),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => showDetails(app),
                              child: const Text("Details"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () async {
                                final result =
                                    await MalwareApiService.detectMalware(app);

                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title:
                                        const Text("Malware Detection Result"),
                                    content: result.containsKey("error")
                                        ? Text("Error: ${result["error"]}")
                                        : Text(
                                            "Label: ${result["label"]}\nConfidence: ${result["confidence"]}"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("OK"),
                                      )
                                    ],
                                  ),
                                );
                              },
                              child: const Text("Detect Malware"),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
