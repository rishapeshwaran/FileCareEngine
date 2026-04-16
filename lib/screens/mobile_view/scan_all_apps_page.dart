import 'package:flutter/material.dart';
import '../../services/malware_api_service.dart';
import 'scan_statistics_page.dart';

enum ScanStatus { pending, scanning, done, error }

class AppScanResult {
  final Map<String, dynamic> app;
  ScanStatus status;
  Map<String, dynamic>? result;

  AppScanResult({required this.app, this.status = ScanStatus.pending});
}

// ─── In-memory session cache ────────────────────────────────────────────────
// Lives as long as the app is open. Cleared on rescan.
final Map<String, Map<String, dynamic>> _scanCache = {};
DateTime? _lastScanTime;

// ─── System app detection ───────────────────────────────────────────────────
// Common OEM/OS package prefixes found on virtually all Android phones.
const List<String> _systemPackagePrefixes = [
  'com.android.',
  'android.',
  'com.google.android.',
  'com.samsung.',
  'com.sec.',
  'com.miui.',
  'com.xiaomi.',
  'com.oneplus.',
  'com.oppo.',
  'com.vivo.',
  'com.huawei.',
  'com.motorola.',
  'com.lge.',
  'com.htc.',
  'com.sony.',
  'com.asus.',
  'com.realme.',
  'com.qualcomm.',
  'com.mediatek.',
  'com.qti.',
  'com.google.',
];

bool _isSystemApp(Map<String, dynamic> app) {
  // Trust the flag from AppInstallSource when available
  if (app["isSystemApp"] == true) return true;

  // Fallback: match against known system package prefixes
  final pkg = (app["packageName"] ?? "").toLowerCase();
  for (final prefix in _systemPackagePrefixes) {
    if (pkg.startsWith(prefix)) return true;
  }
  return false;
}

class ScanAllAppsPage extends StatefulWidget {
  final List<Map<String, dynamic>> apps;

  const ScanAllAppsPage({super.key, required this.apps});

  @override
  State<ScanAllAppsPage> createState() => _ScanAllAppsPageState();
}

class _ScanAllAppsPageState extends State<ScanAllAppsPage> {
  static const Color primaryBlue = Color(0xFF0A1F44);
  static const Color accentGreen = Color(0xFF1ABC9C);

  late final List<Map<String, dynamic>> userApps; // non-system only
  late List<AppScanResult> scanResults;

  int currentIndex = 0;
  bool scanComplete = false;
  bool isPaused = false;
  bool isCheckingCache = true;

  int safeCount = 0;
  int malwareCount = 0;
  int errorCount = 0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Filter once — only user-installed apps
    userApps = widget.apps.where((app) => !_isSystemApp(app)).toList();
    _initFromCacheOrScan();
  }

  // ── Init: load cache or start scan ───────────────────────────────────────

  Future<void> _initFromCacheOrScan() async {
    final allCached = userApps.isNotEmpty &&
        userApps
            .every((app) => _scanCache.containsKey(app["packageName"] ?? ""));

    if (allCached) {
      // Restore previous results from cache
      scanResults = userApps.map((app) {
        final pkg = app["packageName"] ?? "";
        final cached = _scanCache[pkg]!;
        final r = AppScanResult(app: app);
        r.result = cached;

        final hasError = cached.containsKey("error");
        final label = (cached["label"] ?? "").toLowerCase();
        if (hasError) {
          r.status = ScanStatus.error;
          errorCount++;
        } else {
          r.status = ScanStatus.done;
          //rishi
          if (label.contains("malware") && (cached["confidence"] ?? 0) > 0.70) {
            malwareCount++;
          } else {
            safeCount++;
          }
        }
        return r;
      }).toList();

      setState(() {
        scanComplete = true;
        isCheckingCache = false;
      });
    } else {
      // Fresh scan
      scanResults = userApps.map((app) => AppScanResult(app: app)).toList();
      setState(() => isCheckingCache = false);
      _startScanning();
    }
  }

  // ── Scanning loop ─────────────────────────────────────────────────────────

  Future<void> _startScanning() async {
    for (int i = currentIndex; i < scanResults.length; i++) {
      if (!mounted) return;

      if (isPaused) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 300));
          return isPaused && mounted;
        });
      }

      setState(() {
        currentIndex = i;
        scanResults[i].status = ScanStatus.scanning;
      });
      _scrollToIndex(i);

      try {
        final response =
            await MalwareApiService.detectMalware(scanResults[i].app);
        if (!mounted) return;

        final pkg = scanResults[i].app["packageName"] ?? "";
        _scanCache[pkg] = response; // persist to cache

        final hasError = response.containsKey("error");
        final label = hasError ? "" : (response["label"] ?? "");

        setState(() {
          scanResults[i].result = response;
          if (hasError) {
            scanResults[i].status = ScanStatus.error;
            errorCount++;
          } else {
            scanResults[i].status = ScanStatus.done;
            //rishi
            if (label.toLowerCase().contains("malware") &&
                (response["confidence"] ?? 0) > 0.70) {
              malwareCount++;
            } else {
              safeCount++;
            }
          }
        });
      } catch (e) {
        if (!mounted) return;
        final errorResult = {"error": e.toString()};
        _scanCache[scanResults[i].app["packageName"] ?? ""] = errorResult;

        setState(() {
          scanResults[i].status = ScanStatus.error;
          scanResults[i].result = errorResult;
          errorCount++;
        });
      }
    }

    if (mounted) {
      _lastScanTime = DateTime.now();
      setState(() => scanComplete = true);
    }
  }

  // ── Rescan: clears cache and restarts ─────────────────────────────────────

  void _rescan() {
    _scanCache.clear();
    _lastScanTime = null;
    setState(() {
      currentIndex = 0;
      scanComplete = false;
      isPaused = false;
      safeCount = 0;
      malwareCount = 0;
      errorCount = 0;
      scanResults = userApps.map((app) => AppScanResult(app: app)).toList();
    });
    _startScanning();
  }

  void _showRescanDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Rescan All Apps?",
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will clear the previous scan results and scan all user-installed apps again. It may take a while.",
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _rescan();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text("Rescan"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToIndex(int index) {
    final offset = index * 130.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(offset,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isCheckingCache) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: primaryBlue,
          title: const Text("User App Scan",
              style: TextStyle(color: Colors.white)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: accentGreen),
              SizedBox(height: 16),
              Text("Checking previous scan results...",
                  style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: Column(
          children: [
            const Text("User App Scan",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(
              "${userApps.length} apps · system apps excluded",
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!scanComplete)
            IconButton(
              tooltip: isPaused ? "Resume" : "Pause",
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white),
              onPressed: () => setState(() => isPaused = !isPaused),
            ),
          if (scanComplete)
            IconButton(
              tooltip: "Rescan All",
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _showRescanDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: userApps.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: scanResults.length,
                    itemBuilder: (ctx, i) =>
                        _buildAppScanCard(scanResults[i], i),
                  ),
          ),
          if (scanComplete) _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Progress header ───────────────────────────────────────────────────────

  Widget _buildProgressHeader() {
    final scanned = scanResults
        .where(
            (r) => r.status == ScanStatus.done || r.status == ScanStatus.error)
        .length;
    final total = scanResults.length;
    final progress = total == 0 ? 1.0 : scanned / total;

    String statusLabel;
    if (scanComplete) {
      final timeStr = _lastScanTime != null ? _formatTime(_lastScanTime!) : "";
      statusLabel = timeStr.isEmpty ? "✓ Scan Complete" : "✓ Scanned $timeStr";
    } else if (isPaused) {
      statusLabel = "Paused...";
    } else {
      statusLabel = "Scanning...";
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: primaryBlue,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(statusLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text("$scanned / $total",
                  style: TextStyle(
                      color: accentGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(accentGreen),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _countChip(Icons.verified, "Safe", safeCount, accentGreen),
              _countChip(Icons.dangerous, "Malware", malwareCount, Colors.red),
              _countChip(
                  Icons.error_outline, "Error", errorCount, Colors.orange),
            ],
          ),
          // Cached results notice
          if (scanComplete && _lastScanTime != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.history, color: accentGreen, size: 13),
                  SizedBox(width: 6),
                  Text(
                    "Showing cached results  ·  Tap ↻ to rescan",
                    style: TextStyle(
                        color: accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _countChip(IconData icon, String label, int count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Text("$label: $count",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  // ── App scan card ─────────────────────────────────────────────────────────

  Widget _buildAppScanCard(AppScanResult scanResult, int index) {
    final app = scanResult.app;
    final status = scanResult.status;
    final result = scanResult.result;

    Color borderColor = Colors.grey.shade200;
    Color iconColor = Colors.grey;
    IconData statusIcon = Icons.hourglass_empty;
    String statusText = "Pending";

    switch (status) {
      case ScanStatus.scanning:
        borderColor = accentGreen.withOpacity(0.5);
        iconColor = accentGreen;
        statusIcon = Icons.radar;
        statusText = "Scanning...";
        break;
      case ScanStatus.done:
        final label = result?["label"] ?? "";
        // rishi
        final isMalware = label.toLowerCase().contains("malware") &&
            (result?["confidence"] ?? 0) > 0.70;
        borderColor = isMalware
            ? Colors.red.withOpacity(0.3)
            : accentGreen.withOpacity(0.3);
        iconColor = isMalware ? Colors.red : accentGreen;
        statusIcon = isMalware ? Icons.dangerous : Icons.verified;
        statusText = label;
        break;
      case ScanStatus.error:
        borderColor = Colors.orange.withOpacity(0.3);
        iconColor = Colors.orange;
        statusIcon = Icons.error_outline;
        statusText = "Scan Error";
        break;
      default:
        break;
    }

    final isMalwareDone = status == ScanStatus.done &&
        (result?["label"] ?? "").toLowerCase().contains("malware");

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: status == ScanStatus.scanning
                  ? SizedBox(
                      key: const ValueKey("spinner"),
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: accentGreen),
                    )
                  : Icon(statusIcon,
                      key: ValueKey(status), color: iconColor, size: 36),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app["appName"] ?? "",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryBlue)),
                const SizedBox(height: 2),
                Text(app["packageName"] ?? "",
                    style:
                        const TextStyle(color: Colors.black45, fontSize: 12)),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: status == ScanStatus.pending
                      ? const SizedBox.shrink()
                      : Column(
                          key: ValueKey(status),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(statusText,
                                style: TextStyle(
                                    color: iconColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            if (status == ScanStatus.done &&
                                result != null &&
                                !result.containsKey("error"))
                              Text(
                                "Confidence: ${((result["confidence"] ?? 0.0) * 100).toStringAsFixed(1)}%",
                                style: const TextStyle(
                                    color: Colors.black45, fontSize: 12),
                              ),
                            if (isMalwareDone &&
                                result?["malicious_permissions"] != null)
                              _buildPermBadge(result!["malicious_permissions"]),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermBadge(dynamic perms) {
    final list = (perms as List<dynamic>).map((e) => e.toString()).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          ...list.take(2).map((p) =>
              _chip(p.replaceAll("android.permission.", ""), Colors.red)),
          if (list.length > 2) _chip("+${list.length - 2} more", Colors.red),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10)),
      );

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 72, color: accentGreen.withOpacity(0.6)),
          const SizedBox(height: 16),
          const Text("No user-installed apps found",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryBlue)),
          const SizedBox(height: 8),
          const Text(
            "All detected apps appear to be system apps\nand have been excluded from scanning.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar: Rescan + Statistics ──────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: _showRescanDialog,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Rescan",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanStatisticsPage(
                    scanResults: scanResults,
                    safeCount: safeCount,
                    malwareCount: malwareCount,
                    errorCount: errorCount,
                  ),
                ),
              ),
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: const Text("View Statistics",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
