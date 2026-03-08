import 'package:flutter/material.dart';

class ImageScanResultPage extends StatefulWidget {
  final Map<String, dynamic> result;

  const ImageScanResultPage({super.key, required this.result});

  @override
  State<ImageScanResultPage> createState() => _ImageScanResultPageState();
}

class _ImageScanResultPageState extends State<ImageScanResultPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF0A1F44);
  static const Color accentGreen = Color(0xFF1ABC9C);

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isValid = widget.result["valid"] ?? false;
    bool malicious = widget.result["malicious"] ?? false;

    Color statusColor;
    IconData statusIcon;
    String title;

    if (!isValid) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
      title = "Validation Failed";
    } else if (malicious) {
      statusColor = Colors.red;
      statusIcon = Icons.dangerous;
      title = "Malicious File Detected";
    } else {
      statusColor = accentGreen;
      statusIcon = Icons.verified;
      title = "File is Safe";
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text("Scan Result"),
      ),
      body: FadeTransition(
        opacity: _controller,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              /// STATUS CARD
              _buildStatusCard(statusColor, statusIcon, title),

              const SizedBox(height: 20),

              /// SUMMARY CARD
              _buildSummaryCard(),

              const SizedBox(height: 20),

              /// FILE INFO CARD
              _buildFileInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(Color color, IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Filename", widget.result["filename"]),
          _infoRow("Scan Stage", widget.result["stage"]),
          _infoRow("Valid", widget.result["valid"] == true ? "Yes" : "No"),
          if (widget.result["malicious"] != null)
            _infoRow("Malicious",
                widget.result["malicious"].toString().toUpperCase()),
          if (widget.result["verdict"] != null)
            _infoRow("Verdict", widget.result["verdict"]),
          if (widget.result["reason"] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.report_problem, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.result["reason"],
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildFileInfoCard() {
    final info = widget.result["file_info"] ?? widget.result["details"];

    if (info == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "File Properties",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue),
          ),
          const SizedBox(height: 15),
          ...info.entries.map<Widget>((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _infoRow(e.key.replaceAll("_", " "), e.value),
            );
          }).toList()
        ],
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: primaryBlue),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(value?.toString() ?? "-"),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 8),
        )
      ],
    );
  }
}
