import 'package:flutter/material.dart';

// Global variable
String ENDPOINT = "http://10.57.29.238:8000";

class EndpointSettingsPage extends StatefulWidget {
  const EndpointSettingsPage({super.key});

  @override
  State<EndpointSettingsPage> createState() => _EndpointSettingsPageState();
}

class _EndpointSettingsPageState extends State<EndpointSettingsPage> {
  late TextEditingController endpointController;

  @override
  void initState() {
    super.initState();
    endpointController = TextEditingController(text: ENDPOINT);
  }

  @override
  void dispose() {
    endpointController.dispose();
    super.dispose();
  }

  void saveEndpoint() {
    setState(() {
      ENDPOINT = endpointController.text.trim();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Endpoint updated successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Endpoint Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Endpoint',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: endpointController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter API endpoint',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveEndpoint,
                child: const Text('Save Endpoint'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Global Value: $ENDPOINT',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
