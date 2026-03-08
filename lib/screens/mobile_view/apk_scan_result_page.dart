import 'package:flutter/material.dart';
import 'analyze_apk_file_page.dart'; // ApkScanResult model lives here
import 'app_detail_page.dart';

class ApkScanResultPage extends StatefulWidget {
  final ApkScanResult result;
  final String fileName;
  final VoidCallback onScanAnother;

  const ApkScanResultPage({
    super.key,
    required this.result,
    required this.fileName,
    required this.onScanAnother,
  });

  @override
  State<ApkScanResultPage> createState() => _ApkScanResultPageState();
}

class _ApkScanResultPageState extends State<ApkScanResultPage>
    with SingleTickerProviderStateMixin {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _navy = Color(0xFF0A1F44);
  static const _green = Color(0xFF1ABC9C);
  static const _red = Color(0xFFE74C3C);
  static const _amber = Color(0xFFF39C12);
  static const _blue = Color(0xFF2980B9);
  static const _purple = Color(0xFF8E44AD);
  static const _bg = Color(0xFFF4F6FB);

  bool _showPermissions = false;
  bool _showApiCalls = false;

  // Entry animation
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _goToDetails() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppDetailPage(
            app: widget.result.toAppMap(widget.fileName),
          ),
        ),
      );

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final color = r.isMalware ? _red : _green;
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(r, color),
      body: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildVerdictCard(r),
                const SizedBox(height: 16),
                _buildStatsRow(r),
                const SizedBox(height: 16),
                _buildApkInfoCard(r),
                const SizedBox(height: 16),

                // Permissions
                if (r.matchedPermissions.isNotEmpty) ...[
                  _buildExpandableList(
                    icon: Icons.lock_outline_rounded,
                    title: "Matched Permissions",
                    count: r.matchedPermissions.length,
                    items: r.matchedPermissions,
                    isExpanded: _showPermissions,
                    onToggle: () =>
                        setState(() => _showPermissions = !_showPermissions),
                    chipColor: _amber,
                  ),
                  const SizedBox(height: 16),
                ],

                // API calls
                if (r.matchedApiCalls.isNotEmpty) ...[
                  _buildExpandableList(
                    icon: Icons.code_rounded,
                    title: "Matched API Calls",
                    count: r.matchedApiCalls.length,
                    items: r.matchedApiCalls,
                    isExpanded: _showApiCalls,
                    onToggle: () =>
                        setState(() => _showApiCalls = !_showApiCalls),
                    chipColor: _purple,
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ApkScanResult r, Color color) => AppBar(
        backgroundColor: _navy,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Scan Result",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          // Details button in AppBar
          TextButton.icon(
            onPressed: _goToDetails,
            icon:
                const Icon(Icons.info_outline, color: Colors.white70, size: 17),
            label: const Text(
              "Details",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );

  // ── Verdict card ──────────────────────────────────────────────────────────

  Widget _buildVerdictCard(ApkScanResult r) {
    final color = r.isMalware ? _red : _green;
    final icon =
        r.isMalware ? Icons.bug_report_rounded : Icons.verified_user_rounded;
    final title = r.isMalware ? "Malware Detected" : "File is Safe";
    final subtitle = r.isMalware
        ? "This APK exhibits suspicious behaviour"
        : "No threats were found in this APK";
    final pct = r.confidence != null
        ? "${(r.confidence! * 100).toStringAsFixed(1)}%"
        : "--";

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.13), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          // Animated icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: Icon(icon, color: color, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: _navy.withOpacity(0.55)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          // Confidence pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics_outlined, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  "Confidence: $pct",
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          // Confidence bar
          const SizedBox(height: 16),
          if (r.confidence != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Scan confidence",
                    style: TextStyle(
                        fontSize: 12, color: _navy.withOpacity(0.45))),
                Text(pct,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: r.confidence,
                minHeight: 8,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(ApkScanResult r) => Row(
        children: [
          _statTile(
            icon: Icons.folder_zip_outlined,
            label: "APK Size",
            value: _fmtBytes(r.apkSizeBytes),
            color: _blue,
          ),
          const SizedBox(width: 12),
          _statTile(
            icon: Icons.insert_drive_file_outlined,
            label: "Total Files",
            value: "${r.totalFiles}",
            color: _amber,
          ),
          const SizedBox(width: 12),
          _statTile(
            icon: Icons.track_changes_rounded,
            label: "Features Hit",
            value: "${r.totalMatchedFeatures}",
            color: r.isMalware ? _red : _green,
          ),
        ],
      );

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 3),
              Text(label,
                  style:
                      TextStyle(fontSize: 11, color: _navy.withOpacity(0.45)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  // ── APK info card ─────────────────────────────────────────────────────────

  Widget _buildApkInfoCard(ApkScanResult r) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: _navy.withOpacity(0.6), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    "APK Details",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _navy),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _detailRow(Icons.android_rounded, "File Name", widget.fileName),
            const Divider(height: 1, indent: 46, endIndent: 16),
            _detailRow(
              Icons.memory_rounded,
              "DEX Files",
              r.dexFiles.isNotEmpty ? r.dexFiles.join(', ') : 'None found',
            ),
            const SizedBox(height: 8),

            // Details button inside card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: OutlinedButton.icon(
                onPressed: _goToDetails,
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text("View Full Permission Analysis"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _navy,
                  side: BorderSide(color: _navy.withOpacity(0.35)),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: Colors.black38),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _navy, fontSize: 13),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      );

  // ── Expandable chips list ─────────────────────────────────────────────────

  Widget _buildExpandableList({
    required IconData icon,
    required String title,
    required int count,
    required List<String> items,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Color chipColor,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: chipColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: chipColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _navy),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: chipColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: chipColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: _navy.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: chipColor.withOpacity(0.25)),
                          ),
                          child: Text(
                            item,
                            style: TextStyle(
                                fontSize: 11,
                                color: chipColor,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      );

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons() => Row(
        children: [
          // Details
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _goToDetails,
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text("Details",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _navy,
                side: const BorderSide(color: _navy),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Scan another
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: widget.onScanAnother,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                "Scan Another",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      );
}
