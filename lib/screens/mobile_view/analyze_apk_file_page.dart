// import 'dart:io';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';

// import '../../services/malware_api_service.dart';

// // ═══════════════════════════════════════════════════════════
// // DATA MODEL
// // ═══════════════════════════════════════════════════════════

// class ApkScanResult {
//   final int prediction;
//   final String label;
//   final double? confidence;
//   final int apkSizeBytes;
//   final int totalFiles;
//   final List<String> dexFiles;
//   final List<String> matchedPermissions;
//   final List<String> matchedApiCalls;
//   final int totalMatchedFeatures;

//   bool get isMalware => prediction == 1;

//   const ApkScanResult({
//     required this.prediction,
//     required this.label,
//     required this.confidence,
//     required this.apkSizeBytes,
//     required this.totalFiles,
//     required this.dexFiles,
//     required this.matchedPermissions,
//     required this.matchedApiCalls,
//     required this.totalMatchedFeatures,
//   });

//   factory ApkScanResult.fromJson(Map<String, dynamic> json) {
//     final info = (json['apk_info'] as Map<String, dynamic>?) ?? {};
//     final featureCount =
//         (json['matched_feature_count'] as Map<String, dynamic>?) ?? {};
//     return ApkScanResult(
//       prediction: json['prediction'] as int? ?? 0,
//       label: json['label'] as String? ?? 'Unknown',
//       confidence: (json['confidence'] as num?)?.toDouble(),
//       apkSizeBytes: info['apk_size_bytes'] as int? ?? 0,
//       totalFiles: info['total_files'] as int? ?? 0,
//       dexFiles: List<String>.from(info['dex_files'] ?? []),
//       matchedPermissions: List<String>.from(json['matched_permissions'] ?? []),
//       matchedApiCalls: List<String>.from(json['matched_api_calls'] ?? []),
//       totalMatchedFeatures: featureCount['total'] as int? ?? 0,
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════
// // PAGE
// // ═══════════════════════════════════════════════════════════

// class AnalyzeApkFilePage extends StatefulWidget {
//   const AnalyzeApkFilePage({super.key});

//   @override
//   State<AnalyzeApkFilePage> createState() => _AnalyzeApkFilePageState();
// }

// class _AnalyzeApkFilePageState extends State<AnalyzeApkFilePage>
//     with TickerProviderStateMixin {
//   // ── palette ──────────────────────────────────────────
//   static const _navy = Color(0xFF0A1F44);
//   static const _green = Color(0xFF1ABC9C);
//   static const _red = Color(0xFFE74C3C);
//   static const _amber = Color(0xFFF39C12);
//   static const _blue = Color(0xFF2980B9);
//   static const _purple = Color(0xFF8E44AD);
//   static const _bg = Color(0xFFF4F6FB);

//   // ── state ─────────────────────────────────────────────
//   File? _file;
//   String? _fileName;
//   int? _fileSizeBytes;

//   bool _isScanning = false;
//   ApkScanResult? _result;
//   String? _errorMsg;

//   bool _showPermissions = false;
//   bool _showApiCalls = false;

//   // animations
//   late final AnimationController _pulseCtrl;
//   late final AnimationController _resultCtrl;
//   late final Animation<double> _resultFade;
//   late final Animation<Offset> _resultSlide;

//   @override
//   void initState() {
//     super.initState();

//     _pulseCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);

//     _resultCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _resultFade = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
//     _resultSlide = Tween<Offset>(
//       begin: const Offset(0, 0.06),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut));
//   }

//   @override
//   void dispose() {
//     _pulseCtrl.dispose();
//     _resultCtrl.dispose();
//     super.dispose();
//   }

//   // ── helpers ───────────────────────────────────────────
//   String _fmtBytes(int b) {
//     if (b < 1024) return '$b B';
//     if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
//     return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
//   }

//   void _reset() {
//     setState(() {
//       _file = null;
//       _fileName = null;
//       _fileSizeBytes = null;
//       _result = null;
//       _errorMsg = null;
//       _isScanning = false;
//       _showPermissions = false;
//       _showApiCalls = false;
//     });
//     _resultCtrl.reset();
//   }

//   Future<void> _pickFile() async {
//     final picked = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['apk'],
//     );
//     if (picked == null || picked.files.single.path == null) return;
//     setState(() {
//       _file = File(picked.files.single.path!);
//       _fileName = picked.files.single.name;
//       _fileSizeBytes = picked.files.single.size;
//       _result = null;
//       _errorMsg = null;
//       _showPermissions = false;
//       _showApiCalls = false;
//     });
//     _resultCtrl.reset();
//   }

//   Future<void> _scan() async {
//     if (_file == null) return;
//     setState(() {
//       _isScanning = true;
//       _errorMsg = null;
//       _result = null;
//     });

//     final raw = await MalwareApiService.uploadAndScanApk(_file!);

//     if (raw.containsKey('error')) {
//       setState(() {
//         _errorMsg = raw['error'] as String;
//         _isScanning = false;
//       });
//       return;
//     }

//     final result = ApkScanResult.fromJson(raw);
//     setState(() {
//       _result = result;
//       _isScanning = false;
//     });
//     _resultCtrl.forward();
//   }

//   // ══════════════════════════════════════════════════════
//   // BUILD
//   // ══════════════════════════════════════════════════════
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _bg,
//       appBar: _buildAppBar(),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _buildUploadCard(),
//             const SizedBox(height: 16),
//             if (_file != null && !_isScanning && _result == null)
//               _buildScanButton(),
//             if (_isScanning) ...[
//               const SizedBox(height: 8),
//               _buildScanningCard(),
//             ],
//             if (_errorMsg != null) ...[
//               const SizedBox(height: 8),
//               _buildErrorCard(),
//             ],
//             if (_result != null) ...[
//               const SizedBox(height: 8),
//               _buildResults(),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────
//   // AppBar
//   // ─────────────────────────────────────────
//   PreferredSizeWidget _buildAppBar() => AppBar(
//         backgroundColor: _navy,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded,
//               color: Colors.white, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.upload_file_rounded, color: _green, size: 20),
//             SizedBox(width: 8),
//             Text(
//               "Analyze APK File",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 17,
//                 letterSpacing: 0.5,
//               ),
//             ),
//           ],
//         ),
//       );

//   // ─────────────────────────────────────────
//   // Upload / File Card
//   // ─────────────────────────────────────────
//   Widget _buildUploadCard() {
//     final hasFile = _file != null;
//     return GestureDetector(
//       onTap: (_isScanning || hasFile) ? null : _pickFile,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//         padding: EdgeInsets.all(hasFile ? 20 : 36),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(22),
//           border: Border.all(
//             color: hasFile ? _green : _navy.withOpacity(0.12),
//             width: hasFile ? 2 : 1.5,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: (hasFile ? _green : Colors.black).withOpacity(0.07),
//               blurRadius: 16,
//               offset: const Offset(0, 6),
//             ),
//           ],
//         ),
//         child: hasFile ? _fileRow() : _dropHint(),
//       ),
//     );
//   }

//   Widget _dropHint() => Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(22),
//             decoration: BoxDecoration(
//               color: _green.withOpacity(0.08),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.cloud_upload_outlined,
//                 size: 54, color: _green),
//           ),
//           const SizedBox(height: 18),
//           const Text(
//             "Tap to Select APK File",
//             style: TextStyle(
//                 fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Only .apk files are accepted",
//             style: TextStyle(fontSize: 13, color: _navy.withOpacity(0.45)),
//           ),
//         ],
//       );

//   Widget _fileRow() => Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: _green.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: const Icon(Icons.android_rounded, color: _green, size: 34),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _fileName ?? '',
//                   style: const TextStyle(
//                       fontSize: 15, fontWeight: FontWeight.bold, color: _navy),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 if (_fileSizeBytes != null) ...[
//                   const SizedBox(height: 4),
//                   Text(
//                     _fmtBytes(_fileSizeBytes!),
//                     style:
//                         TextStyle(fontSize: 12, color: _navy.withOpacity(0.45)),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           if (!_isScanning)
//             GestureDetector(
//               onTap: _pickFile,
//               child: Tooltip(
//                 message: "Change file",
//                 child: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: _navy.withOpacity(0.06),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(Icons.swap_horiz_rounded,
//                       color: _navy.withOpacity(0.5), size: 20),
//                 ),
//               ),
//             ),
//         ],
//       );

//   // ─────────────────────────────────────────
//   // Scan Button
//   // ─────────────────────────────────────────
//   Widget _buildScanButton() => GestureDetector(
//         onTap: _scan,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 17),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [_navy, Color(0xFF163A6E)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: _navy.withOpacity(0.3),
//                 blurRadius: 14,
//                 offset: const Offset(0, 7),
//               ),
//             ],
//           ),
//           child: const Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.security_rounded, color: _green, size: 22),
//               SizedBox(width: 10),
//               Text(
//                 "Start Scan",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );

//   // ─────────────────────────────────────────
//   // Scanning Indicator
//   // ─────────────────────────────────────────
//   Widget _buildScanningCard() => AnimatedBuilder(
//         animation: _pulseCtrl,
//         builder: (_, __) => Container(
//           padding: const EdgeInsets.symmetric(vertical: 36),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(22),
//             boxShadow: [
//               BoxShadow(
//                 color: _green.withOpacity(0.08 + _pulseCtrl.value * 0.1),
//                 blurRadius: 20,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               SizedBox(
//                 width: 70,
//                 height: 70,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     Opacity(
//                       opacity: 0.12 + _pulseCtrl.value * 0.18,
//                       child: Container(
//                         width: 70,
//                         height: 70,
//                         decoration: const BoxDecoration(
//                           color: _green,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(
//                       width: 38,
//                       height: 38,
//                       child: CircularProgressIndicator(
//                           color: _green, strokeWidth: 3),
//                     ),
//                     const Icon(Icons.security_rounded, color: _green, size: 18),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Text("Scanning APK…",
//                   style: TextStyle(
//                       fontSize: 17, fontWeight: FontWeight.bold, color: _navy)),
//               const SizedBox(height: 6),
//               Text(
//                 "Extracting features & running model",
//                 style: TextStyle(fontSize: 13, color: _navy.withOpacity(0.45)),
//               ),
//             ],
//           ),
//         ),
//       );

//   // ─────────────────────────────────────────
//   // Error Card
//   // ─────────────────────────────────────────
//   Widget _buildErrorCard() => Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: _red.withOpacity(0.06),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: _red.withOpacity(0.25)),
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.error_outline_rounded, color: _red, size: 22),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(_errorMsg!,
//                   style: const TextStyle(color: _red, fontSize: 13)),
//             ),
//           ],
//         ),
//       );

//   // ══════════════════════════════════════════════════════
//   // RESULTS
//   // ══════════════════════════════════════════════════════
//   Widget _buildResults() {
//     final r = _result!;
//     return SlideTransition(
//       position: _resultSlide,
//       child: FadeTransition(
//         opacity: _resultFade,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _buildVerdictCard(r),
//             const SizedBox(height: 14),
//             _buildStatsRow(r),
//             const SizedBox(height: 14),
//             _buildInfoCard(r),
//             if (r.matchedPermissions.isNotEmpty) ...[
//               const SizedBox(height: 14),
//               _buildExpandableList(
//                 icon: Icons.lock_outline_rounded,
//                 title: "Matched Permissions",
//                 count: r.matchedPermissions.length,
//                 items: r.matchedPermissions,
//                 isExpanded: _showPermissions,
//                 onToggle: () =>
//                     setState(() => _showPermissions = !_showPermissions),
//                 chipColor: _amber,
//               ),
//             ],
//             if (r.matchedApiCalls.isNotEmpty) ...[
//               const SizedBox(height: 14),
//               _buildExpandableList(
//                 icon: Icons.code_rounded,
//                 title: "Matched API Calls",
//                 count: r.matchedApiCalls.length,
//                 items: r.matchedApiCalls,
//                 isExpanded: _showApiCalls,
//                 onToggle: () => setState(() => _showApiCalls = !_showApiCalls),
//                 chipColor: _purple,
//               ),
//             ],
//             const SizedBox(height: 20),
//             _buildRescanButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Verdict Hero ──────────────────────────────────────
//   Widget _buildVerdictCard(ApkScanResult r) {
//     final color = r.isMalware ? _red : _green;
//     final icon =
//         r.isMalware ? Icons.bug_report_rounded : Icons.verified_user_rounded;
//     final title = r.isMalware ? "Malware Detected" : "File is Safe";
//     final subtitle = r.isMalware
//         ? "This APK exhibits suspicious behaviour"
//         : "No threats were found in this APK";
//     final pct = r.confidence != null
//         ? "${(r.confidence! * 100).toStringAsFixed(1)}%"
//         : "--";

//     return Container(
//       padding: const EdgeInsets.all(26),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [color.withOpacity(0.14), color.withOpacity(0.04)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(color: color.withOpacity(0.3), width: 1.5),
//       ),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(18),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.12),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 40),
//           ),
//           const SizedBox(height: 14),
//           Text(title,
//               style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                   letterSpacing: 0.3)),
//           const SizedBox(height: 6),
//           Text(subtitle,
//               style: TextStyle(fontSize: 13, color: _navy.withOpacity(0.55)),
//               textAlign: TextAlign.center),
//           const SizedBox(height: 18),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(30),
//               border: Border.all(color: color.withOpacity(0.3)),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.analytics_outlined, color: color, size: 16),
//                 const SizedBox(width: 6),
//                 Text("Confidence: $pct",
//                     style: TextStyle(
//                         color: color,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Stats Row ─────────────────────────────────────────
//   Widget _buildStatsRow(ApkScanResult r) => Row(
//         children: [
//           _statTile(
//             icon: Icons.folder_zip_outlined,
//             label: "APK Size",
//             value: _fmtBytes(r.apkSizeBytes),
//             color: _blue,
//           ),
//           const SizedBox(width: 12),
//           _statTile(
//             icon: Icons.insert_drive_file_outlined,
//             label: "Total Files",
//             value: "${r.totalFiles}",
//             color: _amber,
//           ),
//           const SizedBox(width: 12),
//           _statTile(
//             icon: Icons.track_changes_rounded,
//             label: "Features Hit",
//             value: "${r.totalMatchedFeatures}",
//             color: r.isMalware ? _red : _green,
//           ),
//         ],
//       );

//   Widget _statTile({
//     required IconData icon,
//     required String label,
//     required String value,
//     required Color color,
//   }) =>
//       Expanded(
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(18),
//             boxShadow: [
//               BoxShadow(
//                   color: Colors.black.withOpacity(0.04),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4))
//             ],
//           ),
//           child: Column(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(icon, color: color, size: 20),
//               ),
//               const SizedBox(height: 8),
//               Text(value,
//                   style: TextStyle(
//                       fontSize: 15, fontWeight: FontWeight.bold, color: color)),
//               const SizedBox(height: 3),
//               Text(label,
//                   style:
//                       TextStyle(fontSize: 11, color: _navy.withOpacity(0.45)),
//                   textAlign: TextAlign.center),
//             ],
//           ),
//         ),
//       );

//   // ── APK Info Card ─────────────────────────────────────
//   Widget _buildInfoCard(ApkScanResult r) => Container(
//         padding: const EdgeInsets.all(18),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withOpacity(0.04),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4))
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.info_outline_rounded,
//                     color: _navy.withOpacity(0.6), size: 18),
//                 const SizedBox(width: 8),
//                 const Text("APK Details",
//                     style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: _navy)),
//               ],
//             ),
//             const SizedBox(height: 14),
//             _infoRow("File name", _fileName ?? '--'),
//             _infoRow(
//               "DEX files",
//               r.dexFiles.isNotEmpty ? r.dexFiles.join(', ') : 'None found',
//             ),
//           ],
//         ),
//       );

//   Widget _infoRow(String label, String value) => Padding(
//         padding: const EdgeInsets.only(bottom: 8),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               width: 90,
//               child: Text(label,
//                   style:
//                       TextStyle(fontSize: 12, color: _navy.withOpacity(0.45))),
//             ),
//             Expanded(
//               child: Text(value,
//                   style: const TextStyle(
//                       fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
//             ),
//           ],
//         ),
//       );

//   // ── Expandable Chips List ─────────────────────────────
//   Widget _buildExpandableList({
//     required IconData icon,
//     required String title,
//     required int count,
//     required List<String> items,
//     required bool isExpanded,
//     required VoidCallback onToggle,
//     required Color chipColor,
//   }) =>
//       Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withOpacity(0.04),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4))
//           ],
//         ),
//         child: Column(
//           children: [
//             InkWell(
//               borderRadius: BorderRadius.circular(18),
//               onTap: onToggle,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: chipColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Icon(icon, color: chipColor, size: 18),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(title,
//                           style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: _navy)),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 10, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: chipColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text('$count',
//                           style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                               color: chipColor)),
//                     ),
//                     const SizedBox(width: 8),
//                     Icon(
//                       isExpanded
//                           ? Icons.keyboard_arrow_up_rounded
//                           : Icons.keyboard_arrow_down_rounded,
//                       color: _navy.withOpacity(0.4),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             AnimatedCrossFade(
//               firstChild: const SizedBox.shrink(),
//               secondChild: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 child: Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: items
//                       .map((item) => Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 10, vertical: 5),
//                             decoration: BoxDecoration(
//                               color: chipColor.withOpacity(0.07),
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(
//                                   color: chipColor.withOpacity(0.25)),
//                             ),
//                             child: Text(
//                               item,
//                               style: TextStyle(
//                                   fontSize: 11,
//                                   color: chipColor,
//                                   fontWeight: FontWeight.w500),
//                             ),
//                           ))
//                       .toList(),
//                 ),
//               ),
//               crossFadeState: isExpanded
//                   ? CrossFadeState.showSecond
//                   : CrossFadeState.showFirst,
//               duration: const Duration(milliseconds: 250),
//             ),
//           ],
//         ),
//       );

//   // ── Rescan Button ─────────────────────────────────────
//   Widget _buildRescanButton() => GestureDetector(
//         onTap: _reset,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 15),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: _navy.withOpacity(0.15)),
//             boxShadow: [
//               BoxShadow(
//                   color: Colors.black.withOpacity(0.04),
//                   blurRadius: 8,
//                   offset: const Offset(0, 4))
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.refresh_rounded,
//                   color: _navy.withOpacity(0.6), size: 20),
//               const SizedBox(width: 8),
//               Text("Scan Another File",
//                   style: TextStyle(
//                       color: _navy.withOpacity(0.7),
//                       fontWeight: FontWeight.w600,
//                       fontSize: 15)),
//             ],
//           ),
//         ),
//       );
// }

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/malware_api_service.dart';
import 'apk_scan_result_page.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class ApkScanResult {
  final int prediction;
  final String label;
  final double? confidence;
  final int apkSizeBytes;
  final int totalFiles;
  final List<String> dexFiles;
  final List<String> matchedPermissions;
  final List<String> matchedApiCalls;
  final int totalMatchedFeatures;

  bool get isMalware => prediction == 1;

  const ApkScanResult({
    required this.prediction,
    required this.label,
    required this.confidence,
    required this.apkSizeBytes,
    required this.totalFiles,
    required this.dexFiles,
    required this.matchedPermissions,
    required this.matchedApiCalls,
    required this.totalMatchedFeatures,
  });

  factory ApkScanResult.fromJson(Map<String, dynamic> json) {
    final info = (json['apk_info'] as Map<String, dynamic>?) ?? {};
    final featureCount =
        (json['matched_feature_count'] as Map<String, dynamic>?) ?? {};
    return ApkScanResult(
      prediction: json['prediction'] as int? ?? 0,
      label: json['label'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble(),
      apkSizeBytes: info['apk_size_bytes'] as int? ?? 0,
      totalFiles: info['total_files'] as int? ?? 0,
      dexFiles: List<String>.from(info['dex_files'] ?? []),
      matchedPermissions: List<String>.from(json['matched_permissions'] ?? []),
      matchedApiCalls: List<String>.from(json['matched_api_calls'] ?? []),
      totalMatchedFeatures: featureCount['total'] as int? ?? 0,
    );
  }

  /// Converts scan result into the app map shape AppDetailPage expects
  Map<String, dynamic> toAppMap(String fileName) => {
        'appName': fileName.replaceAll('.apk', ''),
        'packageName': '— (APK file, not installed)',
        'permissions': matchedPermissions,
        'isSystemApp': false,
      };
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class AnalyzeApkFilePage extends StatefulWidget {
  const AnalyzeApkFilePage({super.key});

  @override
  State<AnalyzeApkFilePage> createState() => _AnalyzeApkFilePageState();
}

class _AnalyzeApkFilePageState extends State<AnalyzeApkFilePage>
    with SingleTickerProviderStateMixin {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const _navy = Color(0xFF0A1F44);
  static const _green = Color(0xFF1ABC9C);
  static const _red = Color(0xFFE74C3C);
  static const _bg = Color(0xFFF4F6FB);

  // ── State ─────────────────────────────────────────────────────────────────
  File? _file;
  String? _fileName;
  int? _fileSizeBytes;
  bool _isScanning = false;
  String? _errorMsg;

  // Pulsing animation for scanning card
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _reset() => setState(() {
        _file = _fileName = _fileSizeBytes = _errorMsg = null;
        _isScanning = false;
      });

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );
    if (picked == null || picked.files.single.path == null) return;
    setState(() {
      _file = File(picked.files.single.path!);
      _fileName = picked.files.single.name;
      _fileSizeBytes = picked.files.single.size;
      _errorMsg = null;
    });
  }

  Future<void> _scan() async {
    if (_file == null) return;
    setState(() {
      _isScanning = true;
      _errorMsg = null;
    });

    final raw = await MalwareApiService.uploadAndScanApk(_file!);

    if (!mounted) return;

    if (raw.containsKey('error')) {
      setState(() {
        _errorMsg = raw['error'] as String;
        _isScanning = false;
      });
      return;
    }

    setState(() => _isScanning = false);

    // Navigate to the dedicated result page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApkScanResultPage(
          result: ApkScanResult.fromJson(raw),
          fileName: _fileName ?? 'Unknown',
          onScanAnother: () {
            Navigator.pop(context);
            _reset();
          },
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderBanner(),
            const SizedBox(height: 24),
            _buildUploadCard(),
            const SizedBox(height: 16),
            if (_file != null && !_isScanning) _buildScanButton(),
            if (_isScanning) ...[
              const SizedBox(height: 12),
              _buildScanningCard(),
            ],
            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              _buildErrorCard(),
            ],
            const SizedBox(height: 32),
            _buildInfoBanner(),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: _navy,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file_rounded, color: _green, size: 20),
            SizedBox(width: 8),
            Text(
              "APK Scanner",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      );

  // ── Header banner ─────────────────────────────────────────────────────────

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF0D2B5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shield_rounded, color: _green, size: 36),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Verify Before You Install",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Upload any APK file to check for malware, suspicious permissions and dangerous API calls before installing.",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload card ───────────────────────────────────────────────────────────

  Widget _buildUploadCard() {
    final hasFile = _file != null;
    return GestureDetector(
      onTap: (_isScanning || hasFile) ? null : _pickFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(hasFile ? 20 : 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasFile ? _green : _navy.withOpacity(0.1),
            width: hasFile ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasFile ? _green : Colors.black).withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: hasFile ? _buildFileRow() : _buildDropHint(),
      ),
    );
  }

  Widget _buildDropHint() => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined,
                size: 56, color: _green),
          ),
          const SizedBox(height: 20),
          const Text(
            "Tap to Select APK File",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
          ),
          const SizedBox(height: 8),
          Text(
            "Only .apk files are accepted",
            style: TextStyle(fontSize: 13, color: _navy.withOpacity(0.4)),
          ),
        ],
      );

  Widget _buildFileRow() => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.android_rounded, color: _green, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? '',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: _navy),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_fileSizeBytes != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.straighten,
                          size: 13, color: _navy.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text(
                        _fmtBytes(_fileSizeBytes!),
                        style: TextStyle(
                            fontSize: 12, color: _navy.withOpacity(0.45)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!_isScanning)
            GestureDetector(
              onTap: _pickFile,
              child: Tooltip(
                message: "Change file",
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _navy.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.swap_horiz_rounded,
                      color: _navy.withOpacity(0.5), size: 20),
                ),
              ),
            ),
        ],
      );

  // ── Scan button ───────────────────────────────────────────────────────────

  Widget _buildScanButton() => GestureDetector(
        onTap: _scan,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_navy, Color(0xFF163A6E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _navy.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security_rounded, color: _green, size: 22),
              SizedBox(width: 10),
              Text(
                "Start Scan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Scanning card ─────────────────────────────────────────────────────────

  Widget _buildScanningCard() => AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _green.withOpacity(0.08 + _pulseCtrl.value * 0.1),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.1 + _pulseCtrl.value * 0.2,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                            color: _green, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                          color: _green, strokeWidth: 3),
                    ),
                    const Icon(Icons.security_rounded, color: _green, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                "Scanning APK…",
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: _navy),
              ),
              const SizedBox(height: 6),
              Text(
                "Extracting features & running model",
                style: TextStyle(fontSize: 13, color: _navy.withOpacity(0.45)),
              ),
            ],
          ),
        ),
      );

  // ── Error card ────────────────────────────────────────────────────────────

  Widget _buildErrorCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _red.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: _red, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Scan Failed",
                      style: TextStyle(
                          color: _red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(_errorMsg!,
                      style: TextStyle(
                          color: _red.withOpacity(0.8), fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _scan,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Retry",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Info banner (bottom tips) ─────────────────────────────────────────────

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _navy.withOpacity(0.07)),
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
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: _navy.withOpacity(0.5), size: 17),
              const SizedBox(width: 8),
              Text(
                "What we check",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _navy.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _tipRow(Icons.lock_outline, "Dangerous permissions in the manifest"),
          _tipRow(Icons.code, "Suspicious API calls in DEX bytecode"),
          _tipRow(Icons.analytics_outlined,
              "ML model trained on thousands of malware samples"),
          _tipRow(Icons.insert_drive_file_outlined,
              "APK structure, file count & DEX file names"),
        ],
      ),
    );
  }

  Widget _tipRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 15, color: _green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style:
                      TextStyle(fontSize: 12, color: _navy.withOpacity(0.6))),
            ),
          ],
        ),
      );
}
