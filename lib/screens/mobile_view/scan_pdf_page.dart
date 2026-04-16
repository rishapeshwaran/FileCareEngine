import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../api_endpoint.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const Color primaryBlue = Color(0xFF0A1F44);
const Color accentGreen = Color(0xFF1ABC9C);
const Color bgColor = Color(0xFFF5F7FB);

// ─── Model ───────────────────────────────────────────────────────────────────
class PdfScanResult {
  final bool success;
  final String fileName;
  final double fileSizeKb;
  final int pageCount;
  final String riskLevel;
  final int totalRules;
  final int failedRules;
  final int passedRules;
  final List<RuleResult> rules;

  PdfScanResult({
    required this.success,
    required this.fileName,
    required this.fileSizeKb,
    required this.pageCount,
    required this.riskLevel,
    required this.totalRules,
    required this.failedRules,
    required this.passedRules,
    required this.rules,
  });

  factory PdfScanResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final info = data['pdf_info'] as Map<String, dynamic>;
    final summary = data['analysis_summary'] as Map<String, dynamic>;
    final ruleList = (data['rule_analysis'] as List<dynamic>)
        .map((r) => RuleResult.fromJson(r as Map<String, dynamic>))
        .toList();

    return PdfScanResult(
      success: json['success'] as bool,
      fileName: info['file_name'] as String,
      fileSizeKb: (info['file_size_kb'] as num).toDouble(),
      pageCount: (data['pdf_features']['page_count'] as num).toInt(),
      riskLevel: data['risk_level'] as String,
      totalRules: (summary['total_rules_checked'] as num).toInt(),
      failedRules: (summary['failed_rules_count'] as num).toInt(),
      passedRules: (summary['passed_rules_count'] as num).toInt(),
      rules: ruleList,
    );
  }

  bool get isClean => failedRules == 0;
}

class RuleResult {
  final String name;
  final String result; // "passed" | "failed"
  final String action; // "allow" | "block"
  final String severity;
  final String mode;

  RuleResult({
    required this.name,
    required this.result,
    required this.action,
    required this.severity,
    required this.mode,
  });

  factory RuleResult.fromJson(Map<String, dynamic> json) => RuleResult(
        name: json['rule_name'] as String,
        result: json['result'] as String,
        action: json['action'] as String,
        severity: json['severity'] as String,
        mode: json['mode'] as String,
      );

  bool get isPassed => result == 'passed';
  bool get isHigh => severity == 'high';
}

// ─── Service ─────────────────────────────────────────────────────────────────
class PdfScanService {
  // static const String _baseUrl = 'http://10.10.51.167:8000';
  static String _baseUrl = ENDPOINT;

  static Future<PdfScanResult> scanPdf(File file) async {
    final uri = Uri.parse('$_baseUrl/pdf/scan');
    final request = http.MultipartRequest('POST', uri)
      ..headers['accept'] = 'application/json'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        // ignore: deprecated_member_use
      ));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;

    if (streamed.statusCode != 200) {
      throw Exception('Server returned ${streamed.statusCode}');
    }
    return PdfScanResult.fromJson(json);
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class PdfScanPage extends StatefulWidget {
  const PdfScanPage({super.key});

  @override
  State<PdfScanPage> createState() => _PdfScanPageState();
}

enum _ScanState { idle, picked, scanning, done, error }

class _PdfScanPageState extends State<PdfScanPage>
    with SingleTickerProviderStateMixin {
  _ScanState _state = _ScanState.idle;
  File? _pickedFile;
  String? _pickedFileName;
  double? _pickedFileSizeKb;
  PdfScanResult? _result;
  String _errorMessage = '';

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final pf = result.files.single;
    if (pf.path == null) return;

    setState(() {
      _pickedFile = File(pf.path!);
      _pickedFileName = pf.name;
      _pickedFileSizeKb = (pf.size / 1024);
      _state = _ScanState.picked;
      _result = null;
      _errorMessage = '';
    });
  }

  Future<void> _startScan() async {
    if (_pickedFile == null) return;
    setState(() => _state = _ScanState.scanning);

    try {
      final res = await PdfScanService.scanPdf(_pickedFile!);
      setState(() {
        _result = res;
        _state = _ScanState.done;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _state = _ScanState.error;
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _ScanState.idle;
      _pickedFile = null;
      _pickedFileName = null;
      _pickedFileSizeKb = null;
      _result = null;
      _errorMessage = '';
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          children: [
            Text('PDF Scan',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text('Malware & Threat Analysis',
                style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        actions: [
          if (_state == _ScanState.done || _state == _ScanState.error)
            IconButton(
              tooltip: 'New Scan',
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _reset,
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScanState.idle:
        return _buildIdleState();
      case _ScanState.picked:
        return _buildPickedState();
      case _ScanState.scanning:
        return _buildScanningState();
      case _ScanState.done:
        return _buildResultState();
      case _ScanState.error:
        return _buildErrorState();
    }
  }

  // ── Idle ─────────────────────────────────────────────────────────────────

  Widget _buildIdleState() {
    return Center(
      key: const ValueKey('idle'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PdfIconBounce(),
            const SizedBox(height: 28),
            const Text(
              'PDF Threat Scanner',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue),
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload a PDF file to scan for malware,\nphishing links, embedded scripts & more.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.black45, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 36),
            _GlowButton(
              label: 'Choose PDF File',
              icon: Icons.upload_file_rounded,
              onTap: _pickFile,
            ),
            const SizedBox(height: 20),
            _buildFeatureChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChips() {
    final features = [
      (Icons.link_off, 'URL Check'),
      (Icons.javascript, 'JS Detection'),
      (Icons.lock_open, 'Encryption'),
      (Icons.phishing, 'Phishing'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: features.map((f) => _featureChip(f.$1, f.$2)).toList(),
    );
  }

  Widget _featureChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryBlue.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: primaryBlue.withOpacity(0.6)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: primaryBlue.withOpacity(0.7))),
          ],
        ),
      );

  // ── Picked ───────────────────────────────────────────────────────────────

  Widget _buildPickedState() {
    return Center(
      key: const ValueKey('picked'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FileCard(
              fileName: _pickedFileName ?? '',
              fileSizeKb: _pickedFileSizeKb ?? 0,
            ),
            const SizedBox(height: 32),
            _GlowButton(
              label: 'Start Scan',
              icon: Icons.security_rounded,
              onTap: _startScan,
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Change File'),
              style: TextButton.styleFrom(foregroundColor: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  // ── Scanning ─────────────────────────────────────────────────────────────

  Widget _buildScanningState() {
    return Center(
      key: const ValueKey('scanning'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentGreen.withOpacity(0.1),
                  border:
                      Border.all(color: accentGreen.withOpacity(0.3), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.document_scanner_rounded,
                      size: 52, color: accentGreen),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Analyzing PDF...',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue)),
            const SizedBox(height: 10),
            Text(
              _pickedFileName ?? '',
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 220,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFDEE5F0),
                valueColor: AlwaysStoppedAnimation<Color>(accentGreen),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 20),
            ..._scanningSteps(),
          ],
        ),
      ),
    );
  }

  List<Widget> _scanningSteps() {
    final steps = [
      'Checking for embedded scripts…',
      'Validating URL integrity…',
      'Detecting phishing patterns…',
      'Analysing document actions…',
    ];
    return steps
        .map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accentGreen),
                  ),
                  const SizedBox(width: 8),
                  Text(s,
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 12)),
                ],
              ),
            ))
        .toList();
  }

  // ── Result ───────────────────────────────────────────────────────────────

  Widget _buildResultState() {
    final r = _result!;
    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildVerdictCard(r),
          const SizedBox(height: 14),
          _buildSummaryRow(r),
          const SizedBox(height: 14),
          _buildFileInfoCard(r),
          const SizedBox(height: 14),
          _buildRulesSection(r),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildVerdictCard(PdfScanResult r) {
    final isClean = r.isClean;
    final color = isClean ? accentGreen : Colors.red;
    final icon = isClean ? Icons.verified_rounded : Icons.dangerous_rounded;
    final label = isClean ? 'Clean' : 'Threats Detected';
    final sub = isClean
        ? 'No threats found in this PDF.'
        : '${r.failedRules} rule(s) violated — review details below.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, primaryBlue.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.4), width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _riskBadge(r.riskLevel),
                ]),
                const SizedBox(height: 4),
                Text(sub,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskBadge(String level) {
    final colors = {
      'low': accentGreen,
      'medium': Colors.orange,
      'high': Colors.red,
    };
    final c = colors[level.toLowerCase()] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(level.toUpperCase(),
          style:
              TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSummaryRow(PdfScanResult r) {
    return Row(
      children: [
        Expanded(
            child: _statCard(Icons.rule_rounded, '${r.totalRules}',
                'Rules Checked', Colors.blueGrey)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(Icons.check_circle_rounded, '${r.passedRules}',
                'Passed', accentGreen)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(Icons.cancel_rounded, '${r.failedRules}', 'Failed',
                r.failedRules > 0 ? Colors.red : Colors.grey)),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.black45, fontSize: 11)),
          ],
        ),
      );

  Widget _buildFileInfoCard(PdfScanResult r) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.insert_drive_file_rounded, 'File Info'),
            const SizedBox(height: 12),
            _infoRow('File Name', r.fileName),
            _infoRow('Size', '${r.fileSizeKb.toStringAsFixed(2)} KB'),
            _infoRow('Pages', '${r.pageCount}'),
          ],
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.black45, fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      );

  Widget _buildRulesSection(PdfScanResult r) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.policy_rounded, 'Rule Analysis'),
            const SizedBox(height: 14),
            ...r.rules.map((rule) => _buildRuleRow(rule)),
          ],
        ),
      );

  Widget _buildRuleRow(RuleResult rule) {
    final isPassed = rule.isPassed;
    final color = isPassed ? accentGreen : Colors.red;
    final icon = isPassed ? Icons.check_circle : Icons.cancel;

    // Shorten rule name for display
    final displayName = rule.name
        .replaceAll('PDF.', '')
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(displayName,
                style: const TextStyle(
                    fontSize: 12,
                    color: primaryBlue,
                    fontWeight: FontWeight.w500)),
          ),
          if (!isPassed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(rule.severity.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('PASS',
                  style: TextStyle(
                      color: accentGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────

  Widget _buildErrorState() => Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 72, color: Colors.orange),
              const SizedBox(height: 20),
              const Text('Scan Failed',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue)),
              const SizedBox(height: 10),
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black45, fontSize: 13)),
              const SizedBox(height: 32),
              _GlowButton(
                  label: 'Try Again', icon: Icons.refresh, onTap: _reset),
            ],
          ),
        ),
      );

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );

  Widget _sectionTitle(IconData icon, String title) => Row(
        children: [
          Icon(icon, size: 18, color: primaryBlue),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: primaryBlue)),
        ],
      );
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GlowButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [accentGreen, Color(0xFF16A085)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: accentGreen.withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  final String fileName;
  final double fileSizeKb;

  const _FileCard({required this.fileName, required this.fileSizeKb});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: Colors.red, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryBlue),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${fileSizeKb.toStringAsFixed(2)} KB  ·  PDF',
                    style:
                        const TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: accentGreen, size: 22),
        ],
      ),
    );
  }
}

class _PdfIconBounce extends StatefulWidget {
  @override
  State<_PdfIconBounce> createState() => _PdfIconBounceState();
}

class _PdfIconBounceState extends State<_PdfIconBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: -6, end: 6)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: child,
      ),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryBlue.withOpacity(0.07),
        ),
        child: const Icon(Icons.picture_as_pdf_rounded,
            size: 58, color: primaryBlue),
      ),
    );
  }
}
