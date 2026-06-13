import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/overview_stats.dart';
import '../widgets/recent_activity.dart';
import '../services/ws_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../utils/app_l10n.dart';
import 'notifications_screen.dart';
import 'list_equipment_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _notifCount    = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) auth.loadUser();
    });
  }

  Future<void> _initNotifications() async {
    await WsService.connect();
    await NotificationService.instance.init();
    NotificationService.instance.addListener(_onNotifChanged);
    if (mounted) {
      setState(() => _notifCount = NotificationService.instance.unreadCount);
    }
  }

  void _onNotifChanged() {
    if (mounted) setState(() => _notifCount = NotificationService.instance.unreadCount);
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_onNotifChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final userName = auth.user?['name'] as String? ?? 'User';
    final avatar   = auth.user?['avatar'] as String?;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroPanel(userName, avatar, auth)),
            const SliverToBoxAdapter(child: _AlertsBanner()),
            SliverToBoxAdapter(child: _buildSection(
              title: 'Overview',
              trailing: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/list_equipment'),
                child: Text(context.l10n.viewAll,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight)),
              ),
              child: const OverviewStats(),
            )),
            SliverToBoxAdapter(child: _buildSection(
              title: 'Recent Activity',
              trailing: const Icon(Icons.trending_up_rounded,
                  color: AppColors.success, size: 20),
              child: const RecentActivity(),
            )),
            SliverToBoxAdapter(child: _buildSection(
              title: 'Recent Scans',
              trailing: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/qrscanner'),
                child: const Text('Scan', style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
              child: const _RecentScansWidget(),
            )),
            SliverToBoxAdapter(child: _buildToolsSection(auth)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        notifCount: _notifCount,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          switch (i) {
            case 0: break;
            case 1:
              Navigator.pushNamed(context, '/list_equipment')
                  .then((_) { if (mounted) setState(() => _selectedIndex = 0); });
              break;
            case 3: _showMapsSheet(); break;
            case 6: _showToolsSheet(); break;
            case 4:
              Navigator.pushNamed(context, '/profile')
                  .then((_) { if (mounted) setState(() => _selectedIndex = 0); });
              break;
          }
        },
        onScanTap: () => Navigator.pushNamed(context, '/qrscanner')
            .then((_) { if (mounted) setState(() => _selectedIndex = 0); }),
      ),
    );
  }

  // ── Gradient hero panel ──────────────────────────────────────────────────────

  Widget _buildHeroPanel(String userName, String? avatar, AuthProvider auth) {
    final baseHost  = ApiService.baseUrl.replaceAll('/api', '');
    final firstName = userName.split(' ').first;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.gradHeader,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile')
                    .then((_) { if (mounted) setState(() => _selectedIndex = 0); }),
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.35), width: 2),
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: avatar != null && avatar.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            '$baseHost$avatar',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _avatarFallback(firstName),
                          ),
                        )
                      : _avatarFallback(firstName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $firstName 👋',
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'ISET Mahdia',
                      style: TextStyle(
                        fontSize: 12, color: Colors.white60,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              _IconBtn(
                icon: Icons.notifications_outlined,
                badgeCount: _notifCount,
                onDark: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ).then((_) => setState(
                    () => _notifCount =
                        NotificationService.instance.unreadCount)),
              ),
              if (auth.canAddProduct) ...[
                const SizedBox(width: 8),
                _IconBtn(
                  icon: Icons.add,
                  onDark: true,
                  onTap: () =>
                      Navigator.pushNamed(context, '/addproduct'),
                ),
              ],
            ],
          ),

          const SizedBox(height: 18),

          // Search + filter row
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/list_equipment'),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.22)),
                  ),
                  child: const Row(children: [
                    SizedBox(width: 14),
                    Icon(Icons.search, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Search equipment...',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                auth.canViewMaps ? '/vueinstitut' : '/list_equipment',
              ),
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.28)),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
          ),
        ),
      );

  // ── Maps picker sheet ────────────────────────────────────────────────────────

  void _showMapsSheet() => _showSheet('Maps & Views', [
    _mapTile(icon: Icons.map_outlined,        color: AppColors.success,
        title: 'Equipment Map 2D', subtitle: 'Interactive 2D room layout',   route: '/equipmentmap'),
    _mapTile(icon: Icons.view_in_ar_outlined, color: AppColors.primary,
        title: 'Equipment Map 3D', subtitle: 'Interactive 3D room layout',   route: '/3dmap'),
    _mapTile(icon: Icons.apartment_outlined,  color: AppColors.accent,
        title: 'Institute View',   subtitle: 'ISET Mahdia — all departments', route: '/vueinstitut'),
    _mapTile(icon: Icons.swap_horiz_rounded,  color: AppColors.warning,
        title: 'Move Log',         subtitle: 'Track every item relocation',   route: '/movelog'),
  ]);

  void _showToolsSheet() {
    final auth = context.read<AuthProvider>();
    _showSheet('Tools', [
      _mapTile(icon: Icons.bar_chart_rounded,          color: const Color(0xFF4F46E5),
          title: 'Analytics',            subtitle: 'Charts, trends & warranty alerts', route: '/analytics'),
      _mapTile(icon: Icons.upload_file_rounded,        color: const Color(0xFF0EA5E9),
          title: 'Import Products',      subtitle: 'Bulk import from CSV',            route: '/import-products'),
      _mapTile(icon: Icons.radar_rounded,              color: AppColors.error,
          title: 'AirTag Tracker',       subtitle: 'Live location of equipment',      route: '/tracker'),
      _mapTile(icon: Icons.manage_search_rounded,      color: const Color(0xFF059669),
          title: 'Tracker Management',   subtitle: 'GPS map & battery status',        route: '/tracker-management'),
      _mapTile(icon: Icons.sensors_rounded,            color: const Color(0xFF6D28D9),
          title: 'IoT Live Feed',        subtitle: 'Real-time RFID zone events',      route: '/iot-feed'),
      _mapTile(icon: Icons.nfc_rounded,                color: AppColors.primary,
          title: 'RFID Scan History',    subtitle: 'RFID & BLE scan log',             route: '/rfid-scan-history'),
      _mapTile(icon: Icons.bluetooth_searching_rounded, color: AppColors.accent,
          title: 'BLE Proximity',        subtitle: 'Detect nearby inventory via BLE', route: '/ble-proximity'),
      _mapTile(icon: Icons.auto_awesome_rounded,       color: const Color(0xFF0EA5E9),
          title: 'AI Assistant',         subtitle: 'Ask anything about inventory',    route: '/ai'),
      _mapTile(icon: Icons.chat_bubble_outline_rounded, color: AppColors.primary,
          title: 'Messages',             subtitle: 'Chat with team members',          route: '/chat'),
      _mapTile(icon: Icons.build_rounded,              color: AppColors.error,
          title: 'Maintenance',          subtitle: 'Schedule and track repairs',      route: '/maintenance'),
      _mapTile(icon: Icons.swap_horiz_rounded,         color: const Color(0xFF059669),
          title: 'Move Log',             subtitle: 'Track item movements',            route: '/movelog'),
      if (auth.canManageUsers)
        _mapTile(icon: Icons.manage_accounts_rounded,  color: const Color(0xFF6D28D9),
            title: 'Manage Users',       subtitle: 'Roles, accounts & access control', route: '/admin/users'),
    ]);
  }

  void _showSheet(String title, List<Widget> tiles) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w700, color: AppColors.textH)),
                const SizedBox(height: 16),
                ...tiles.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10), child: t)),
              ]),
        ),
      ),
    );
  }

  Widget _buildToolsSection(AuthProvider auth) {
    final tools = [
      _ToolItem(Icons.bar_chart_rounded,              const Color(0xFF4F46E5), 'Analytics',         '/analytics'),
      _ToolItem(Icons.radar_rounded,                  const Color(0xFFEF4444), 'AirTag Tracker',    '/tracker'),
      _ToolItem(Icons.manage_search_rounded,          const Color(0xFF059669), 'Tracker Map',       '/tracker-management'),
      _ToolItem(Icons.bluetooth_searching_rounded,    const Color(0xFF0EA5E9), 'BLE Proximity',     '/ble-proximity'),
      _ToolItem(Icons.nfc_rounded,                    AppColors.primary,       'RFID History',      '/rfid-scan-history'),
      _ToolItem(Icons.sensors_rounded,                const Color(0xFF6D28D9), 'IoT Live Feed',     '/iot-feed'),
      _ToolItem(Icons.build_rounded,                  const Color(0xFFDC2626), 'Maintenance',       '/maintenance'),
      _ToolItem(Icons.auto_awesome_rounded,           const Color(0xFF0EA5E9), 'AI Assistant',      '/ai'),
      _ToolItem(Icons.upload_file_rounded,            const Color(0xFF0EA5E9), 'Import CSV',        '/import-products'),
      _ToolItem(Icons.chat_bubble_outline_rounded,    AppColors.primary,       'Messages',          '/chat'),
      _ToolItem(Icons.swap_horiz_rounded,             const Color(0xFF059669), 'Move Log',          '/movelog'),
      if (auth.canManageUsers)
        _ToolItem(Icons.manage_accounts_rounded,      const Color(0xFF6D28D9), 'Manage Users',      '/admin/users'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tools', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
            color: AppColors.textH)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: tools.map((t) => GestureDetector(
            onTap: () => Navigator.pushNamed(context, t.route),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.color.withOpacity(0.15)),
                boxShadow: AppColors.shadowMd,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 46, height: 46,
                  decoration: BoxDecoration(color: t.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(t.icon, color: t.color, size: 24)),
                const SizedBox(height: 8),
                Text(t.label, textAlign: TextAlign.center,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.textH, height: 1.2)),
              ]),
            ),
          )).toList(),
        ),
      ]),
    );
  }

  Widget _mapTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.textH,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
        ]),
      ),
    );
  }

  // ── Section wrapper ──────────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textH,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Header icon button ────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;
  final bool onDark;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = badgeCount > 99 ? '99+' : '$badgeCount';
    final wide  = badgeCount > 9;

    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: onDark
                ? Colors.white.withOpacity(0.18)
                : AppColors.bgCard,
            shape: BoxShape.circle,
            border: onDark
                ? Border.all(color: Colors.white.withOpacity(0.28))
                : null,
            boxShadow: onDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: onDark ? Colors.white : AppColors.textH,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 0, top: 0,
            child: Container(
              constraints: BoxConstraints(minWidth: wide ? 18 : 16),
              height: 16,
              padding: EdgeInsets.symmetric(horizontal: wide ? 3 : 0),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: onDark
                      ? Colors.transparent
                      : AppColors.bgCard,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Tool item model ───────────────────────────────────────────────────────────

class _ToolItem {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   route;
  const _ToolItem(this.icon, this.color, this.label, this.route);
}

// ── Recent scans widget ───────────────────────────────────────────────────────

class _RecentScansWidget extends StatefulWidget {
  const _RecentScansWidget();
  @override
  State<_RecentScansWidget> createState() => _RecentScansWidgetState();
}

class _RecentScansWidgetState extends State<_RecentScansWidget> {
  List<dynamic> _scans = [];
  bool _loading = true;
  final String _baseHost = ApiService.baseUrl.replaceAll('/api', '');

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final all = await ApiService.getScanHistory();
      if (!mounted) return;
      final scans = all
          .where((s) => s['type'] == 'scan' || s['type'] == 'product_added')
          .take(5)
          .toList();
      setState(() { _scans = scans; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 60,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)));

    if (_scans.isEmpty) return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.shadowMd),
      child: const Row(children: [
        Icon(Icons.qr_code_scanner_outlined, color: AppColors.textMuted, size: 20),
        SizedBox(width: 10),
        Text('No recent scans', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ]),
    );

    return Column(
      children: _scans.map((s) {
        final name    = s['name']         as String? ?? 'Unknown';
        final sku     = s['sku']          as String? ?? '';
        final photo   = s['photo_url']    as String?;
        final time    = s['scanned_at']   as String? ?? '';
        final prodId  = s['product_id']   as String?;
        final dt      = DateTime.tryParse(time);
        final timeStr = dt == null ? '' : _timeAgo(dt);

        return GestureDetector(
          onTap: prodId == null ? null : () async {
            final res = await ApiService.getProduct(prodId);
            if (res['success'] == true && context.mounted) {
              final p = Product.fromJson(res['data'] as Map<String, dynamic>);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: p)));
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.shadowMd),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photo != null
                    ? Image.network('$_baseHost$photo', width: 40, height: 40, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textH)),
                Text(sku, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ])),
              Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _placeholder() => Container(width: 40, height: 40, color: AppColors.bgMuted,
      child: const Icon(Icons.devices_other, size: 20, color: AppColors.textMuted));

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Alerts banner ────────────────────────────────────────────────────────────

class _AlertsBanner extends StatefulWidget {
  const _AlertsBanner();
  @override
  State<_AlertsBanner> createState() => _AlertsBannerState();
}

class _AlertsBannerState extends State<_AlertsBanner> {
  int _critical = 0, _lost = 0, _warrantyExpiring = 0;
  String? _nearestWarranty;
  bool _loaded = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final stats    = await ApiService.getStats();
      final warranty = await ApiService.getWarrantyAlerts();
      if (!mounted) return;
      final d = (stats?['data'] as Map<String, dynamic>?) ?? {};
      DateTime? nearest;
      for (final p in warranty) {
        final exp = p['warranty_expiry'] as String?;
        if (exp == null) continue;
        final dt = DateTime.tryParse(exp);
        if (dt != null && (nearest == null || dt.isBefore(nearest))) nearest = dt;
      }
      setState(() {
        _critical = (d['status_critical_issue'] as int? ?? 0);
        _lost     = (d['status_lost']           as int? ?? 0);
        _warrantyExpiring = warranty.length;
        if (nearest != null) {
          final days = nearest.difference(DateTime.now()).inDays;
          _nearestWarranty = days < 0 ? 'Expired' : 'in $days days';
        }
        _loaded = true;
      });
    } catch (_) { if (mounted) setState(() => _loaded = true); }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || (_critical == 0 && _lost == 0 && _warrantyExpiring == 0)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(children: [
        if (_critical > 0 || _lost > 0)
          _AlertTile(
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            bg: const Color(0xFFFEE2E2),
            label: [
              if (_critical > 0) '$_critical critical issue${_critical > 1 ? 's' : ''}',
              if (_lost > 0)     '$_lost lost item${_lost > 1 ? 's' : ''}',
            ].join(' · '),
            onTap: () => Navigator.pushNamed(context, '/list_equipment'),
          ),
        if (_warrantyExpiring > 0) ...[
          if (_critical > 0 || _lost > 0) const SizedBox(height: 8),
          _AlertTile(
            icon: Icons.verified_outlined,
            color: const Color(0xFFF59E0B),
            bg: const Color(0xFFFEF3C7),
            label: '$_warrantyExpiring warranty expiring'
                '${_nearestWarranty != null ? ' · nearest $_nearestWarranty' : ''}',
            onTap: () => Navigator.pushNamed(context, '/analytics'),
          ),
        ],
      ]),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final String label;
  final VoidCallback onTap;
  const _AlertTile({required this.icon, required this.color,
      required this.bg, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
      ]),
    ),
  );
}

// ── Custom bottom navigation ──────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final int notifCount;
  final void Function(int) onTap;
  final VoidCallback onScanTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.notifCount,
    required this.onTap,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(
          top: BorderSide(color: AppColors.divider(context), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(0, Icons.home_rounded,        Icons.home_outlined,        context.l10n.home),
              _item(1, Icons.inventory_2_rounded, Icons.inventory_2_outlined, context.l10n.inventory),
              // Centre scan FAB
              GestureDetector(
                onTap: onScanTap,
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradPrimary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.shadowColored(AppColors.primary),
                  ),
                  child: const Icon(Icons.qr_code_scanner,
                      color: Colors.white, size: 24),
                ),
              ),
              _item(3, Icons.map_rounded,     Icons.map_outlined,     context.l10n.maps),
              _item(6, Icons.widgets_rounded, Icons.widgets_outlined, context.l10n.tools),
              _item(4, Icons.person_rounded,  Icons.person_outline_rounded, context.l10n.profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData active, IconData inactive, String label) {
    final sel = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active indicator pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: sel ? 22 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              sel ? active : inactive,
              size: 22,
              color: sel ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
