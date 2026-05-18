import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/overview_stats.dart';
import '../widgets/recent_activity.dart';
import '../services/ws_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import 'notifications_screen.dart';

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
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroPanel(userName, avatar, auth)),
            SliverToBoxAdapter(child: _buildSection(
              title: 'Overview',
              trailing: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/list_equipment'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
              child: const OverviewStats(),
            )),
            SliverToBoxAdapter(child: _buildSection(
              title: 'Recent Activity',
              trailing: const Icon(
                Icons.trending_up_rounded,
                color: AppColors.success, size: 20,
              ),
              child: const RecentActivity(),
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        notifCount: _notifCount,
        showReports: context.watch<AuthProvider>().canViewReports,
        showUsers: context.watch<AuthProvider>().canManageUsers,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          switch (i) {
            case 0: break;
            case 1:
              Navigator.pushNamed(context, '/list_equipment')
                  .then((_) { if (mounted) setState(() => _selectedIndex = 0); });
              break;
            case 3: _showMapsSheet(); break;
            case 4:
              Navigator.pushNamed(context, '/profile')
                  .then((_) { if (mounted) setState(() => _selectedIndex = 0); });
              break;
            case 5:
              Navigator.pushNamed(context, '/admin/users')
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

  void _showMapsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Maps & Navigation',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textH,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a view',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              _mapTile(
                icon: Icons.map_outlined,
                color: AppColors.success,
                title: 'Equipment Map 2D',
                subtitle: 'Interactive 2D room layout',
                route: '/equipmentmap',
              ),
              const SizedBox(height: 10),
              _mapTile(
                icon: Icons.view_in_ar_outlined,
                color: AppColors.primary,
                title: 'Equipment Map 3D',
                subtitle: 'Interactive 3D room layout',
                route: '/3dmap',
              ),
              const SizedBox(height: 10),
              _mapTile(
                icon: Icons.apartment_outlined,
                color: AppColors.accent,
                title: 'Institute View 3D',
                subtitle: 'ISET Mahdia — all departments',
                route: '/vueinstitut',
              ),
              const SizedBox(height: 10),
              _mapTile(
                icon: Icons.swap_horiz_rounded,
                color: AppColors.warning,
                title: 'Move Log',
                subtitle: 'Track every item relocation',
                route: '/movelog',
              ),
              const SizedBox(height: 10),
              _mapTile(
                icon: Icons.radar_rounded,
                color: AppColors.error,
                title: 'AirTag Tracker',
                subtitle: 'Live location of all equipment',
                route: '/tracker',
              ),
            ],
          ),
        ),
      ),
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

// ── Custom bottom navigation ──────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final int notifCount;
  final bool showReports;
  final bool showUsers;
  final void Function(int) onTap;
  final VoidCallback onScanTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.notifCount,
    required this.showReports,
    required this.showUsers,
    required this.onTap,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
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
              _item(0, Icons.home_rounded,        Icons.home_outlined,        'Home'),
              _item(1, Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'Inventory'),
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
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white, size: 24,
                  ),
                ),
              ),
              if (showReports)
                _item(3, Icons.map_rounded,   Icons.map_outlined,    'Maps'),
              if (showUsers)
                _item(5, Icons.group_rounded, Icons.group_outlined,  'Users'),
              _item(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
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
