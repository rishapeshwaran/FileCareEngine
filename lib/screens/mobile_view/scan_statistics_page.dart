import 'package:flutter/material.dart';
import 'scan_all_apps_page.dart';
import 'app_detail_page.dart';

class ScanStatisticsPage extends StatelessWidget {
  final List<AppScanResult> scanResults;
  final int safeCount;
  final int malwareCount;
  final int errorCount;

  const ScanStatisticsPage({
    super.key,
    required this.scanResults,
    required this.safeCount,
    required this.malwareCount,
    required this.errorCount,
  });

  static const Color primaryBlue = Color(0xFF0A1F44);
  static const Color accentGreen = Color(0xFF1ABC9C);

  @override
  Widget build(BuildContext context) {
    final total = scanResults.length;
    final scanned = safeCount + malwareCount + errorCount;

    // rishi changes
    final malwareApps = scanResults
        .where((r) =>
            r.status == ScanStatus.done &&
            r.result?["confidence"] > 0.65 &&
            (r.result?["label"] ?? "").toLowerCase().contains("malware"))
        .toList();

    final Map<String, int> permFrequency = {};
    for (final r in malwareApps) {
      final perms = r.result?["malicious_permissions"];
      if (perms != null && perms is List) {
        for (final p in perms) {
          final key = p.toString().replaceAll("android.permission.", "");
          permFrequency[key] = (permFrequency[key] ?? 0) + 1;
        }
      }
    }

    final sortedPerms = permFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final highConf =
        malwareApps.where((r) => (r.result?["confidence"] ?? 0) >= 0.8).length;
    final medConf = malwareApps
        .where((r) =>
            (r.result?["confidence"] ?? 0) >= 0.5 &&
            (r.result?["confidence"] ?? 0) < 0.8)
        .length;
    final lowConf =
        malwareApps.where((r) => (r.result?["confidence"] ?? 0) < 0.5).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text(
          "Scan Statistics",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Overview ──────────────────────────────────────────────────────
          _sectionCard(
            title: "Overview",
            icon: Icons.summarize_rounded,
            children: [
              _DonutChart(
                safe: safeCount,
                malware: malwareCount,
                error: errorCount,
                total: total,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statBadge("Total", total.toString(), Colors.blueGrey),
                  _statBadge("Safe", safeCount.toString(), accentGreen),
                  _statBadge("Malware", malwareCount.toString(), Colors.red),
                  _statBadge("Error", errorCount.toString(), Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              _statRow("Scan Coverage",
                  "${(scanned / (total == 0 ? 1 : total) * 100).toStringAsFixed(1)}%"),
              _statRow("Safe Rate",
                  "${(safeCount / (scanned == 0 ? 1 : scanned) * 100).toStringAsFixed(1)}%"),
              _statRow("Threat Rate",
                  "${(malwareCount / (scanned == 0 ? 1 : scanned) * 100).toStringAsFixed(1)}%"),
            ],
          ),
          const SizedBox(height: 16),

          // ── Confidence breakdown ───────────────────────────────────────
          if (malwareApps.isNotEmpty) ...[
            _sectionCard(
              title: "Malware Confidence Levels",
              icon: Icons.speed_rounded,
              children: [
                _BarChartRow(
                    label: "High (≥80%)",
                    value: highConf,
                    max: malwareApps.length,
                    color: Colors.red),
                _BarChartRow(
                    label: "Medium (50–80%)",
                    value: medConf,
                    max: malwareApps.length,
                    color: Colors.orange),
                _BarChartRow(
                    label: "Low (<50%)",
                    value: lowConf,
                    max: malwareApps.length,
                    color: Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Top flagged permissions ────────────────────────────────────
          if (sortedPerms.isNotEmpty) ...[
            _sectionCard(
              title: "Top Flagged Permissions",
              icon: Icons.lock_open_rounded,
              children: [
                ...sortedPerms.take(8).map((entry) => _BarChartRow(
                      label: entry.key,
                      value: entry.value,
                      max: malwareApps.isEmpty ? 1 : malwareApps.length,
                      color: Colors.red,
                      showCount: true,
                    )),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Detected threats list ─────────────────────────────────────
          if (malwareApps.isNotEmpty) ...[
            _sectionCard(
              title: "Detected Threats (${malwareApps.length})",
              icon: Icons.bug_report_rounded,
              children: [
                ...malwareApps.map(
                  (r) => _MalwareAppTile(
                    app: r.app,
                    confidence: r.result?["confidence"] ?? 0.0,
                    permissions: r.result?["malicious_permissions"] ?? [],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Security score ─────────────────────────────────────────────
          _sectionCard(
            title: "Device Security Score",
            icon: Icons.shield_rounded,
            children: [
              _SecurityScoreWidget(
                safeCount: safeCount,
                malwareCount: malwareCount,
                total: scanned,
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Section card shell ─────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(color: Colors.black45, fontSize: 12)),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Bar chart row ────────────────────────────────────────────────────────────

class _BarChartRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final bool showCount;

  const _BarChartRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : value / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                showCount ? "$value apps" : "$value",
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Malware app tile — now with Details button ───────────────────────────────

class _MalwareAppTile extends StatelessWidget {
  final Map<String, dynamic> app;
  final double confidence;
  final List<dynamic> permissions;

  const _MalwareAppTile({
    required this.app,
    required this.confidence,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final appName = app["appName"] ?? "";
    final packageName = app["packageName"] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App icon placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child:
                      const Icon(Icons.dangerous, color: Colors.red, size: 22),
                ),
                const SizedBox(width: 10),
                // Name + package
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        packageName,
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Confidence badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${(confidence * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ── Permission chips ─────────────────────────────────────────
          if (permissions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: permissions.take(5).map((p) {
                  final label =
                      p.toString().replaceAll("android.permission.", "");
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Divider + action buttons ──────────────────────────────────
          const Divider(height: 1, color: Color(0x22FF0000)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                // Details button → AppDetailPage
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppDetailPage(app: app),
                      ),
                    ),
                    icon: const Icon(Icons.info_outline, size: 15),
                    label: const Text(
                      "Details",
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0A1F44),
                      side: BorderSide(
                          color: const Color(0xFF0A1F44).withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Threat label badge (non-interactive, visual indicator)
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dangerous, color: Colors.white, size: 15),
                        SizedBox(width: 5),
                        Text(
                          "Malware",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Donut chart ──────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final int safe, malware, error, total;

  const _DonutChart({
    required this.safe,
    required this.malware,
    required this.error,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _DonutPainter(
            safe: safe, malware: malware, error: error, total: total),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                total.toString(),
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: ScanStatisticsPage.primaryBlue),
              ),
              const Text("Apps",
                  style: TextStyle(color: Colors.black45, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int safe, malware, error, total;

  _DonutPainter({
    required this.safe,
    required this.malware,
    required this.error,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2 - 10;
    const strokeWidth = 22.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.grey.shade100,
    );

    if (total == 0) return;

    final fullAngle = 2 * 3.14159265;
    double startAngle = -3.14159265 / 2;

    void drawArc(int count, Color color) {
      if (count == 0) return;
      final sweep = fullAngle * (count / total);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
      startAngle += sweep;
    }

    drawArc(safe, const Color(0xFF1ABC9C));
    drawArc(malware, Colors.red);
    drawArc(error, Colors.orange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Security score widget ────────────────────────────────────────────────────

class _SecurityScoreWidget extends StatelessWidget {
  final int safeCount, malwareCount, total;

  const _SecurityScoreWidget({
    required this.safeCount,
    required this.malwareCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final score = total == 0 ? 100 : ((safeCount / total) * 100).round();

    final Color scoreColor;
    final String label;
    final IconData icon;

    if (score >= 90) {
      scoreColor = const Color(0xFF1ABC9C);
      label = "Excellent";
      icon = Icons.verified_user;
    } else if (score >= 70) {
      scoreColor = Colors.orange;
      label = "Fair";
      icon = Icons.shield;
    } else {
      scoreColor = Colors.red;
      label = "At Risk";
      icon = Icons.gpp_bad;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: scoreColor, size: 48),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$score / 100",
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: scoreColor),
                ),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 16,
                      color: scoreColor,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 14,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          malwareCount == 0
              ? "No threats found. Your device is secure!"
              : "$malwareCount malicious app${malwareCount > 1 ? 's' : ''} detected. Consider removing them.",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: malwareCount == 0 ? Colors.black45 : Colors.red,
              fontSize: 13),
        ),
      ],
    );
  }
}
