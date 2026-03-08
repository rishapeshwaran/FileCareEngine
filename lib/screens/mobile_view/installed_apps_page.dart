// // import 'package:flutter/material.dart';
// // import '../../services/app_install_source.dart';
// // import '../../widgets/app_details_dialog.dart';
// // import 'malware_scan_result_page.dart';
// // import 'scan_all_apps_page.dart';

// // class InstalledAppsAnalysisPage extends StatefulWidget {
// //   const InstalledAppsAnalysisPage({super.key});

// //   @override
// //   State createState() => _InstalledAppsAnalysisPageState();
// // }

// // class _InstalledAppsAnalysisPageState extends State
// //     with SingleTickerProviderStateMixin {
// //   List<Map<String, dynamic>> allApps = [];
// //   List<Map<String, dynamic>> filteredApps = [];
// //   bool loading = true;

// //   final TextEditingController _searchController = TextEditingController();
// //   Color primaryBlue = const Color(0xFF0A1F44);
// //   Color accentGreen = const Color(0xFF1ABC9C);

// //   @override
// //   void initState() {
// //     super.initState();
// //     loadApps();
// //     _searchController.addListener(filterApps);
// //   }

// //   void loadApps() async {
// //     final result = await AppInstallSource.getAllInstalledApps();
// //     setState(() {
// //       allApps = result;
// //       filteredApps = result;
// //       loading = false;
// //     });
// //   }

// //   void filterApps() {
// //     String query = _searchController.text.toLowerCase();
// //     List<Map<String, dynamic>> temp = allApps.where((app) {
// //       final appName = (app["appName"] ?? "").toLowerCase();
// //       final packageName = (app["packageName"] ?? "").toLowerCase();
// //       bool matchesSearch =
// //           appName.contains(query) || packageName.contains(query);
// //       return matchesSearch;
// //     }).toList();
// //     setState(() {
// //       filteredApps = temp;
// //     });
// //   }

// //   void showDetails(Map<String, dynamic> app) {
// //     showDialog(
// //       context: context,
// //       builder: (_) => AppDetailsDialog(app: app),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _searchController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         backgroundColor: primaryBlue,
// //         title: const Text(
// //           "Installed Applications",
// //           style: TextStyle(color: Colors.white),
// //         ),
// //         centerTitle: true,
// //         actions: [
// //           if (!loading)
// //             Padding(
// //               padding: const EdgeInsets.only(right: 10),
// //               child: _ScanAllButton(
// //                 onPressed: () {
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (_) => ScanAllAppsPage(apps: allApps),
// //                     ),
// //                   );
// //                 },
// //                 accentGreen: accentGreen,
// //               ),
// //             ),
// //         ],
// //         bottom: PreferredSize(
// //           preferredSize: const Size.fromHeight(68),
// //           child: Padding(
// //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// //             child: Container(
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               child: TextField(
// //                 controller: _searchController,
// //                 decoration: InputDecoration(
// //                   hintText: "Search applications...",
// //                   prefixIcon: Icon(Icons.search, color: primaryBlue),
// //                   border: InputBorder.none,
// //                   contentPadding: const EdgeInsets.symmetric(vertical: 14),
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //       body: loading
// //           ? Center(
// //               child: CircularProgressIndicator(color: accentGreen),
// //             )
// //           : filteredApps.isEmpty
// //               ? const Center(child: Text("No applications found"))
// //               : ListView.builder(
// //                   padding:
// //                       const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// //                   itemCount: filteredApps.length,
// //                   itemBuilder: (context, index) {
// //                     final app = filteredApps[index];
// //                     return _buildAppCard(app);
// //                   },
// //                 ),
// //     );
// //   }

// //   Widget _buildAppCard(Map<String, dynamic> app) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 16),
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(18),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.05),
// //             blurRadius: 10,
// //             offset: const Offset(0, 6),
// //           ),
// //         ],
// //         border: Border.all(
// //           color: primaryBlue.withOpacity(0.05),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Icon(Icons.android, color: accentGreen),
// //               const SizedBox(width: 10),
// //               Expanded(
// //                 child: Text(
// //                   app["appName"] ?? "",
// //                   style: TextStyle(
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 16,
// //                     color: primaryBlue,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 6),
// //           Text(
// //             app["packageName"] ?? "",
// //             style: const TextStyle(color: Colors.black54),
// //           ),
// //           const SizedBox(height: 14),
// //           Row(
// //             children: [
// //               Expanded(
// //                 child: OutlinedButton(
// //                   onPressed: () => showDetails(app),
// //                   style: OutlinedButton.styleFrom(
// //                     foregroundColor: primaryBlue,
// //                     side: BorderSide(color: primaryBlue),
// //                   ),
// //                   child: const Text("Details"),
// //                 ),
// //               ),
// //               const SizedBox(width: 10),
// //               Expanded(
// //                 child: ElevatedButton(
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: accentGreen,
// //                   ),
// //                   onPressed: () {
// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(
// //                         builder: (_) => MalwareScanResultPage(app: app),
// //                       ),
// //                     );
// //                   },
// //                   child: const Text("Scan"),
// //                 ),
// //               ),
// //             ],
// //           )
// //         ],
// //       ),
// //     );
// //   }
// // }

// // /// Animated "Scan All" button for the AppBar
// // class _ScanAllButton extends StatefulWidget {
// //   final VoidCallback onPressed;
// //   final Color accentGreen;

// //   const _ScanAllButton({required this.onPressed, required this.accentGreen});

// //   @override
// //   State<_ScanAllButton> createState() => _ScanAllButtonState();
// // }

// // class _ScanAllButtonState extends State<_ScanAllButton>
// //     with SingleTickerProviderStateMixin {
// //   late AnimationController _controller;
// //   late Animation<double> _scaleAnim;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _controller = AnimationController(
// //       vsync: this,
// //       duration: const Duration(milliseconds: 900),
// //       lowerBound: 0.93,
// //       upperBound: 1.0,
// //     )..repeat(reverse: true);
// //     _scaleAnim = _controller;
// //   }

// //   @override
// //   void dispose() {
// //     _controller.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return ScaleTransition(
// //       scale: _scaleAnim,
// //       child: ElevatedButton.icon(
// //         onPressed: widget.onPressed,
// //         icon: const Icon(Icons.radar, size: 18),
// //         label: const Text(
// //           "Scan All",
// //           style: TextStyle(fontWeight: FontWeight.bold),
// //         ),
// //         style: ElevatedButton.styleFrom(
// //           backgroundColor: widget.accentGreen,
// //           foregroundColor: Colors.white,
// //           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(20),
// //           ),
// //           elevation: 4,
// //         ),
// //       ),
// //     );
// //   }
// // }

import 'package:flutter/material.dart';
import '../../services/app_install_source.dart';
import 'app_detail_page.dart';
import 'malware_scan_result_page.dart';
import 'scan_all_apps_page.dart';

// ─── System-app detection (same logic used by ScanAllAppsPage) ──────────────
const List<String> _systemPrefixes = [
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
  if (app['isSystemApp'] == true) return true;
  final pkg = (app['packageName'] ?? '').toLowerCase();
  return _systemPrefixes.any((p) => pkg.startsWith(p));
}

// ─── Filter tabs ─────────────────────────────────────────────────────────────
enum AppFilter { user, all, system, playstore, thirdParty }

extension AppFilterLabel on AppFilter {
  String get label {
    switch (this) {
      case AppFilter.user:
        return 'User Apps';
      case AppFilter.all:
        return 'All';
      case AppFilter.system:
        return 'System';
      case AppFilter.playstore:
        return 'Play Store';
      case AppFilter.thirdParty:
        return '3rd Party';
    }
  }

  IconData get icon {
    switch (this) {
      case AppFilter.user:
        return Icons.person;
      case AppFilter.all:
        return Icons.apps;
      case AppFilter.system:
        return Icons.settings_suggest;
      case AppFilter.playstore:
        return Icons.shop;
      case AppFilter.thirdParty:
        return Icons.device_unknown;
    }
  }
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class InstalledAppsAnalysisPage extends StatefulWidget {
  const InstalledAppsAnalysisPage({super.key});

  @override
  State<InstalledAppsAnalysisPage> createState() =>
      _InstalledAppsAnalysisPageState();
}

class _InstalledAppsAnalysisPageState extends State<InstalledAppsAnalysisPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF0A1F44);
  static const Color accentGreen = Color(0xFF1ABC9C);

  List<Map<String, dynamic>> allApps = [];
  List<Map<String, dynamic>> filteredApps = [];
  bool loading = true;

  AppFilter _activeFilter = AppFilter.user; // default: exclude system apps
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadApps();
    _searchController.addListener(_applyFilters);
  }

  Future<void> loadApps() async {
    final result = await AppInstallSource.getAllInstalledApps();
    setState(() {
      allApps = result;
      loading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    List<Map<String, dynamic>> temp = allApps.where((app) {
      // ── Filter tab ──
      switch (_activeFilter) {
        case AppFilter.user:
          if (_isSystemApp(app)) return false;
          break;
        case AppFilter.system:
          if (!_isSystemApp(app)) return false;
          break;
        case AppFilter.playstore:
          final installer = (app['installer'] ?? '').toLowerCase();
          if (!installer.contains('play')) return false;
          break;
        case AppFilter.thirdParty:
          final installer = (app['installer'] ?? '').toLowerCase();
          if (_isSystemApp(app) || installer.contains('play')) return false;
          break;
        case AppFilter.all:
          break;
      }

      // ── Search query ──
      if (query.isEmpty) return true;
      final name = (app['appName'] ?? '').toLowerCase();
      final pkg = (app['packageName'] ?? '').toLowerCase();
      return name.contains(query) || pkg.contains(query);
    }).toList();

    setState(() => filteredApps = temp);
  }

  void _setFilter(AppFilter f) {
    setState(() => _activeFilter = f);
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: const Text('Installed Applications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (!loading)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _ScanAllButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ScanAllAppsPage(apps: allApps)),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(118),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search applications...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, color: primaryBlue),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              // Filter chips
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  children: AppFilter.values.map((f) {
                    final active = _activeFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _setFilter(f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? accentGreen
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? accentGreen
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(f.icon,
                                  size: 14,
                                  color:
                                      active ? Colors.white : Colors.white70),
                              const SizedBox(width: 5),
                              Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: active
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: active ? Colors.white : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentGreen))
          : Column(
              children: [
                // Results count bar
                _buildResultsBar(),
                Expanded(
                  child: filteredApps.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filteredApps.length,
                          itemBuilder: (ctx, i) =>
                              _buildAppCard(filteredApps[i]),
                        ),
                ),
              ],
            ),
    );
  }

  // ─── Results count bar ──────────────────────────────────────────────────

  Widget _buildResultsBar() {
    final userCount = allApps.where((a) => !_isSystemApp(a)).length;
    final sysCount = allApps.length - userCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            '${filteredApps.length} app${filteredApps.length != 1 ? 's' : ''}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 14),
          ),
          const Spacer(),
          _miniStat(Icons.person, '$userCount user', accentGreen),
          const SizedBox(width: 10),
          _miniStat(
              Icons.settings_suggest, '$sysCount system', Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            _searchController.text.isEmpty
                ? 'No apps in this category'
                : 'No results for "${_searchController.text}"',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── App card ───────────────────────────────────────────────────────────

  Widget _buildAppCard(Map<String, dynamic> app) {
    final isSystem = _isSystemApp(app);
    final installer = (app['installer'] ?? '').toLowerCase();
    final isPlaystore = installer.contains('play');

    String sourceLabel;
    Color sourceColor;
    IconData sourceIcon;

    if (isSystem) {
      sourceLabel = 'System';
      sourceColor = Colors.blueGrey;
      sourceIcon = Icons.settings_suggest;
    } else if (isPlaystore) {
      sourceLabel = 'Play Store';
      sourceColor = const Color(0xFF34A853);
      sourceIcon = Icons.shop;
    } else {
      sourceLabel = '3rd Party';
      sourceColor = Colors.deepOrange;
      sourceIcon = Icons.device_unknown;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: primaryBlue.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App icon placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.android, color: primaryBlue, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['appName'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: primaryBlue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        app['packageName'] ?? '',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Source badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: sourceColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sourceColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(sourceIcon, size: 11, color: sourceColor),
                                const SizedBox(width: 4),
                                Text(
                                  sourceLabel,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: sourceColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          if (app['versionName'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'v${app['versionName']}',
                              style: const TextStyle(
                                  color: Colors.black38, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, indent: 14, endIndent: 14),
          const SizedBox(height: 10),

          // ── Action buttons ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AppDetailPage(app: app)),
                    ),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: const BorderSide(color: primaryBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MalwareScanResultPage(app: app)),
                    ),
                    icon: const Icon(Icons.radar, size: 16),
                    label: const Text('Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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

// ─── Animated "Scan All" AppBar button ───────────────────────────────────────

class _ScanAllButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _ScanAllButton({required this.onPressed});

  @override
  State<_ScanAllButton> createState() => _ScanAllButtonState();
}

class _ScanAllButtonState extends State<_ScanAllButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.93,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _ctrl,
      child: ElevatedButton.icon(
        onPressed: widget.onPressed,
        icon: const Icon(Icons.radar, size: 17),
        label: const Text('Scan All',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1ABC9C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
        ),
      ),
    );
  }
}
