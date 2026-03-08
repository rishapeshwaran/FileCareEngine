import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'malware_scan_result_page.dart';

// ─── Permission category definitions ─────────────────────────────────────────

class _PermCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  const _PermCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.keywords,
  });
}

const List<_PermCategory> _categories = [
  _PermCategory(
    title: 'Location',
    icon: Icons.location_on,
    color: Color(0xFF4CAF50),
    keywords: ['location', 'gps', 'position', 'lat', 'lng'],
  ),
  _PermCategory(
    title: 'Camera & Media',
    icon: Icons.camera_alt,
    color: Color(0xFF2196F3),
    keywords: ['camera', 'photo', 'video', 'picture', 'media', 'image'],
  ),
  _PermCategory(
    title: 'Microphone',
    icon: Icons.mic,
    color: Color(0xFF9C27B0),
    keywords: ['audio', 'record', 'microphone', 'sound', 'mic'],
  ),
  _PermCategory(
    title: 'Contacts & Accounts',
    icon: Icons.contacts,
    color: Color(0xFF00BCD4),
    keywords: ['contact', 'account', 'profile', 'social', 'directory'],
  ),
  _PermCategory(
    title: 'Phone & Calls',
    icon: Icons.phone,
    color: Color(0xFF8BC34A),
    keywords: [
      'call',
      'phone',
      'dial',
      'process_outgoing',
      'read_phone',
      'answer',
      'telecom',
    ],
  ),
  _PermCategory(
    title: 'SMS & Messaging',
    icon: Icons.message,
    color: Color(0xFFFF9800),
    keywords: ['sms', 'mms', 'message', 'receive_sms', 'send_sms', 'read_sms'],
  ),
  _PermCategory(
    title: 'Storage & Files',
    icon: Icons.folder,
    color: Color(0xFF795548),
    keywords: [
      'storage',
      'external',
      'read_external',
      'write_external',
      'file',
      'document',
      'manage_external',
    ],
  ),
  _PermCategory(
    title: 'Network & Internet',
    icon: Icons.wifi,
    color: Color(0xFF03A9F4),
    keywords: [
      'internet',
      'network',
      'wifi',
      'bluetooth',
      'nfc',
      'change_network',
      'access_network',
      'access_wifi',
    ],
  ),
  _PermCategory(
    title: 'Calendar',
    icon: Icons.calendar_today,
    color: Color(0xFF3F51B5),
    keywords: ['calendar', 'event', 'schedule'],
  ),
  _PermCategory(
    title: 'Sensors & Health',
    icon: Icons.favorite,
    color: Color(0xFFE91E63),
    keywords: [
      'sensor',
      'health',
      'body',
      'activity',
      'step',
      'biometric',
      'heartrate',
    ],
  ),
  _PermCategory(
    title: 'Device & System',
    icon: Icons.settings,
    color: Color(0xFF607D8B),
    keywords: [
      'boot',
      'admin',
      'system',
      'device',
      'wake_lock',
      'vibrate',
      'flashlight',
      'install_packages',
      'request_install',
      'alert_window',
      'accessibility',
      'notification',
      'foreground',
      'battery',
      'receive_boot',
    ],
  ),
  _PermCategory(
    title: 'Billing & Purchases',
    icon: Icons.payment,
    color: Color(0xFFFF5722),
    keywords: ['billing', 'purchase', 'pay', 'subscription', 'buy'],
  ),
];

_PermCategory _categorize(String permission) {
  final lower = permission.toLowerCase();
  for (final cat in _categories) {
    if (cat.keywords.any((kw) => lower.contains(kw))) return cat;
  }
  return const _PermCategory(
    title: 'Other',
    icon: Icons.security,
    color: Color(0xFF9E9E9E),
    keywords: [],
  );
}

// ─── Risk level ───────────────────────────────────────────────────────────────

enum _Risk { critical, high, medium, low }

const Map<String, _Risk> _permRisk = {
  'BIND_DEVICE_ADMIN': _Risk.critical,
  'MANAGE_EXTERNAL_STORAGE': _Risk.critical,
  'SYSTEM_ALERT_WINDOW': _Risk.critical,
  'REQUEST_INSTALL_PACKAGES': _Risk.high,
  'RECORD_AUDIO': _Risk.high,
  'READ_SMS': _Risk.high,
  'SEND_SMS': _Risk.high,
  'PROCESS_OUTGOING_CALLS': _Risk.high,
  'READ_CALL_LOG': _Risk.high,
  'CAMERA': _Risk.high,
  'READ_CONTACTS': _Risk.high,
  'USE_BIOMETRIC': _Risk.high,
  'ACCESS_FINE_LOCATION': _Risk.medium,
  'ACCESS_COARSE_LOCATION': _Risk.medium,
  'READ_EXTERNAL_STORAGE': _Risk.medium,
  'WRITE_EXTERNAL_STORAGE': _Risk.medium,
  'GET_ACCOUNTS': _Risk.medium,
  'READ_PHONE_STATE': _Risk.medium,
  'CHANGE_NETWORK_STATE': _Risk.medium,
  'RECEIVE_BOOT_COMPLETED': _Risk.medium,
};

_Risk _riskOf(String permission) {
  final key = permission
      .replaceAll('android.permission.', '')
      .replaceAll('com.android.', '')
      .toUpperCase();
  return _permRisk[key] ?? _Risk.low;
}

Color _riskColor(_Risk r) {
  switch (r) {
    case _Risk.critical:
      return Colors.purple;
    case _Risk.high:
      return Colors.red;
    case _Risk.medium:
      return Colors.orange;
    case _Risk.low:
      return const Color(0xFF1ABC9C);
  }
}

String _riskLabel(_Risk r) {
  switch (r) {
    case _Risk.critical:
      return 'Critical';
    case _Risk.high:
      return 'High';
    case _Risk.medium:
      return 'Medium';
    case _Risk.low:
      return 'Low';
  }
}

// ─── AppDetailPage ────────────────────────────────────────────────────────────

class AppDetailPage extends StatefulWidget {
  final Map<String, dynamic> app;

  const AppDetailPage({super.key, required this.app});

  @override
  State<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends State<AppDetailPage>
    with TickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF0A1F44);
  static const Color accentGreen = Color(0xFF1ABC9C);

  late final TabController _tabController;
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Data helpers ─────────────────────────────────────────────────────────

  List<String> get _permissions {
    final raw = widget.app['permissions'];
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  Map<_PermCategory, List<String>> get _groupedPermissions {
    final map = <String, List<String>>{};
    final catMap = <String, _PermCategory>{};

    for (final perm in _permissions) {
      final cat = _categorize(perm);
      map.putIfAbsent(cat.title, () => []).add(perm);
      catMap[cat.title] = cat;
    }

    final sorted = map.entries.toList()
      ..sort((a, b) {
        final aMax =
            a.value.map(_riskOf).reduce((v, e) => e.index < v.index ? e : v);
        final bMax =
            b.value.map(_riskOf).reduce((v, e) => e.index < v.index ? e : v);
        return aMax.index.compareTo(bMax.index);
      });

    return {for (final e in sorted) catMap[e.key]!: e.value};
  }

  int get _highRiskCount => _permissions
      .where((p) => _riskOf(p) == _Risk.critical || _riskOf(p) == _Risk.high)
      .length;

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appName = widget.app['appName'] ?? 'Unknown';
    final pkgName = widget.app['packageName'] ?? '';
    final highRisk = _highRiskCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      // ── Standard AppBar (no SliverAppBar → no duplicate title) ──────────
      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          appName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentGreen,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MalwareScanResultPage(app: widget.app)),
        ),
        icon: const Icon(Icons.radar, color: Colors.white),
        label: const Text(
          'Scan App',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // ── Hero header ─────────────────────────────────────────────────
          _buildHeroHeader(appName, pkgName, highRisk),

          // ── Tab bar ──────────────────────────────────────────────────────
          Container(
            color: primaryBlue,
            child: TabBar(
              controller: _tabController,
              indicatorColor: accentGreen,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 16),
                      SizedBox(width: 6),
                      Text('Info'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 16),
                      SizedBox(width: 6),
                      Text('Permissions'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildPermissionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero header ──────────────────────────────────────────────────────────
  // Separate from the AppBar so the title never duplicates.

  Widget _buildHeroHeader(String appName, String pkgName, int highRisk) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1F44), Color(0xFF0D2B5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // App icon
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
            ),
            child: const Icon(Icons.android, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 12),

          // App name — single line with ellipsis, never overflows
          Text(
            appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Package name — wraps gracefully
          Text(
            pkgName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),

          // High-risk badge
          if (highRisk > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.redAccent, size: 14),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '$highRisk high-risk permission${highRisk > 1 ? 's' : ''} detected',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Info tab ─────────────────────────────────────────────────────────────

  Widget _buildInfoTab() {
    final app = widget.app;

    final fields = <Map<String, dynamic>>[
      {
        'icon': Icons.label,
        'label': 'App Name',
        'value': app['appName'] ?? '—',
        'copy': false
      },
      {
        'icon': Icons.fingerprint,
        'label': 'Package Name',
        'value': app['packageName'] ?? '—',
        'copy': true
      },
      {
        'icon': Icons.tag,
        'label': 'Version',
        'value': app['versionName'] ?? '—',
        'copy': false
      },
      {
        'icon': Icons.confirmation_number,
        'label': 'Version Code',
        'value': app['versionCode']?.toString() ?? '—',
        'copy': false
      },
      {
        'icon': Icons.install_mobile,
        'label': 'Installed From',
        'value': _friendlyInstaller(app['installer']),
        'copy': false
      },
      {
        'icon': Icons.calendar_today,
        'label': 'First Installed',
        'value': _formatMs(app['firstInstallTime']),
        'copy': false
      },
      {
        'icon': Icons.update,
        'label': 'Last Updated',
        'value': _formatMs(app['lastUpdateTime']),
        'copy': false
      },
      {
        'icon': Icons.storage,
        'label': 'Data Dir',
        'value': app['dataDir'] ?? '—',
        'copy': true
      },
      {
        'icon': Icons.settings_suggest,
        'label': 'System App',
        'value': (app['isSystemApp'] == true) ? 'Yes' : 'No',
        'copy': false,
        'highlight': app['isSystemApp'] == true,
      },
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _sectionHeader('Application Details', Icons.info_outline),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: fields.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              return _infoRow(
                icon: f['icon'] as IconData,
                label: f['label'] as String,
                value: f['value'] as String,
                canCopy: (f['copy'] as bool?) ?? false,
                highlight: (f['highlight'] as bool?) ?? false,
                showDivider: i < fields.length - 1,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool canCopy = false,
    bool highlight = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: Colors.black38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        color: highlight
                            ? Colors.blueGrey
                            : const Color(0xFF0A1F44),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      // Allows long paths / package names to wrap
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              if (canCopy)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label copied'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.copy, size: 16, color: Colors.black26),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 46, endIndent: 16),
      ],
    );
  }

  // ─── Permissions tab ──────────────────────────────────────────────────────

  Widget _buildPermissionsTab() {
    final grouped = _groupedPermissions;

    if (_permissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user,
                size: 64, color: accentGreen.withOpacity(0.4)),
            const SizedBox(height: 14),
            const Text(
              'No permissions declared',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildPermSummaryRow(),
        const SizedBox(height: 16),
        _sectionHeader(
          'Permissions by Category  (${_permissions.length} total)',
          Icons.lock_outline,
        ),
        const SizedBox(height: 8),
        ...grouped.entries.map((e) => _buildCategoryCard(e.key, e.value)),
      ],
    );
  }

  // Risk count chips at the top of the permissions tab
  Widget _buildPermSummaryRow() {
    final counts = {
      _Risk.critical: 0,
      _Risk.high: 0,
      _Risk.medium: 0,
      _Risk.low: 0,
    };
    for (final p in _permissions) {
      counts[_riskOf(p)] = (counts[_riskOf(p)] ?? 0) + 1;
    }

    return Row(
      children: [
        _riskChip('Critical', counts[_Risk.critical]!, Colors.purple),
        const SizedBox(width: 6),
        _riskChip('High', counts[_Risk.high]!, Colors.red),
        const SizedBox(width: 6),
        _riskChip('Medium', counts[_Risk.medium]!, Colors.orange),
        const SizedBox(width: 6),
        _riskChip('Low', counts[_Risk.low]!, accentGreen),
      ],
    );
  }

  Widget _riskChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // Collapsible category card
  Widget _buildCategoryCard(_PermCategory cat, List<String> perms) {
    final isOpen = _expanded[cat.title] ?? false;
    final sorted = [...perms]
      ..sort((a, b) => _riskOf(a).index.compareTo(_riskOf(b).index));
    final topRisk =
        sorted.map(_riskOf).reduce((v, e) => e.index < v.index ? e : v);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: topRisk.index <= _Risk.high.index
              ? cat.color.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded[cat.title] = !isOpen),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: isOpen ? Radius.zero : const Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Title + count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0A1F44),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${perms.length} permission${perms.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Top-risk badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _riskColor(topRisk).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _riskColor(topRisk).withOpacity(0.4)),
                    ),
                    child: Text(
                      _riskLabel(topRisk),
                      style: TextStyle(
                        color: _riskColor(topRisk),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.black38),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible permission list
          AnimatedCrossFade(
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                ...sorted.asMap().entries.map(
                      (e) => _buildPermissionRow(e.value, e.key, sorted.length),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String perm, int index, int total) {
    // Clean display name
    final shortName = perm
        .replaceAll('android.permission.', '')
        .replaceAll('com.android.vending.', '')
        .replaceAll('com.', '');
    final risk = _riskOf(perm);
    final riskColor = _riskColor(risk);
    final desc = _permDescription(perm);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coloured risk dot
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: riskColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF0A1F44),
                      ),
                      softWrap: true,
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      perm,
                      style: const TextStyle(
                        color: Colors.black26,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Risk badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: riskColor.withOpacity(0.35)),
                ),
                child: Text(
                  _riskLabel(risk),
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (index < total - 1)
          const Divider(height: 1, indent: 34, endIndent: 14),
      ],
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: primaryBlue),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: primaryBlue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyInstaller(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return 'Unknown / Sideloaded';
    final s = raw.toString().toLowerCase();
    if (s.contains('play')) return 'Google Play Store';
    if (s.contains('amazon')) return 'Amazon Appstore';
    if (s.contains('galaxy') || s.contains('samsung'))
      return 'Samsung Galaxy Store';
    if (s.contains('huawei') || s.contains('appgallery'))
      return 'Huawei AppGallery';
    return raw.toString();
  }

  String _formatMs(dynamic ms) {
    if (ms == null) return '—';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(ms.toString()));
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$d/$mo/${dt.year}  $h:$mi';
    } catch (_) {
      return ms.toString();
    }
  }

  String _permDescription(String perm) {
    const map = <String, String>{
      'READ_CONTACTS': 'Read all contacts on device',
      'WRITE_CONTACTS': 'Add or modify contacts',
      'READ_CALL_LOG': 'Access complete call history',
      'WRITE_CALL_LOG': 'Modify call history',
      'CALL_PHONE': 'Initiate phone calls',
      'PROCESS_OUTGOING_CALLS': 'Intercept or redirect outgoing calls',
      'RECORD_AUDIO': 'Record from microphone',
      'CAMERA': 'Access device camera',
      'READ_SMS': 'Read SMS messages (including OTPs)',
      'SEND_SMS': 'Send SMS without user interaction',
      'RECEIVE_SMS': 'Intercept incoming SMS',
      'READ_EXTERNAL_STORAGE': 'Read files from external storage',
      'WRITE_EXTERNAL_STORAGE': 'Write or delete files on storage',
      'MANAGE_EXTERNAL_STORAGE': 'Full access to all storage',
      'ACCESS_FINE_LOCATION': 'Access precise GPS location',
      'ACCESS_COARSE_LOCATION': 'Access approximate location',
      'ACCESS_BACKGROUND_LOCATION': 'Access location in background',
      'INTERNET': 'Full unrestricted network access',
      'ACCESS_NETWORK_STATE': 'View network connection status',
      'ACCESS_WIFI_STATE': 'View Wi-Fi connection info',
      'CHANGE_WIFI_STATE': 'Connect or disconnect Wi-Fi',
      'BLUETOOTH': 'Connect to paired Bluetooth devices',
      'BLUETOOTH_SCAN': 'Scan for nearby Bluetooth devices',
      'READ_CALENDAR': 'Read calendar events',
      'WRITE_CALENDAR': 'Add or modify calendar events',
      'GET_ACCOUNTS': 'Access list of device accounts',
      'USE_BIOMETRIC': 'Use biometric authentication',
      'USE_FINGERPRINT': 'Use fingerprint sensor',
      'BODY_SENSORS': 'Access heart rate and other body sensors',
      'ACTIVITY_RECOGNITION': 'Detect physical activities',
      'RECEIVE_BOOT_COMPLETED': 'Auto-start on device boot',
      'SYSTEM_ALERT_WINDOW': 'Draw overlays over other apps',
      'BIND_DEVICE_ADMIN': 'Full device administrator control',
      'REQUEST_INSTALL_PACKAGES': 'Silently install other packages',
      'READ_PHONE_STATE': 'Access device identifiers and call state',
      'VIBRATE': 'Control vibration motor',
      'WAKE_LOCK': 'Prevent processor from sleeping',
      'FOREGROUND_SERVICE': 'Run persistent background service',
      'BILLING': 'Trigger in-app purchases',
    };

    final key = perm
        .replaceAll('android.permission.', '')
        .replaceAll('com.android.vending.', '')
        .toUpperCase();
    return map[key] ?? '';
  }
}
