import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/overview_stats.dart';
import '../widgets/recent_activity.dart';
import '../widgets/profile_header.dart';
import '../widgets/inventaire_card.dart';
import '../utils/app_colors.dart';
import '../services/ws_service.dart';
import '../services/notification_service.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    // Load user if not already loaded (e.g. after hot restart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) auth.loadUser();
    });
  }

  Future<void> _initNotifications() async {
    await WsService.connect();
    await NotificationService.instance.init();
    NotificationService.instance.addListener(_onNotifChanged);
    if (mounted) setState(() => _notifCount = NotificationService.instance.unreadCount);
  }

  void _onNotifChanged() {
    if (mounted) setState(() => _notifCount = NotificationService.instance.unreadCount);
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_onNotifChanged);
    super.dispose();
  }

  // ── Bottom nav items per role ───────────────────────────────────────────────

  List<BottomNavigationBarItem> _navItems(AuthProvider auth) {
    if (auth.isTechnicien) {
      return const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2_outlined), label: 'Scan'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline), label: 'Add'),
        BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded), label: 'List'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
      ];
    }
    return const [
      BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_2_outlined), label: 'Scan'),
      BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined), label: 'ISET'),
      BottomNavigationBarItem(
          icon: Icon(Icons.view_in_ar_outlined), label: '3D Map'),
      BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline), label: 'Add'),
      BottomNavigationBarItem(
          icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  void _onNavTap(int index, AuthProvider auth) {
    setState(() => _selectedIndex = index);
    if (auth.isTechnicien) {
      switch (index) {
        case 0: break;
        case 1: Navigator.pushNamed(context, '/qrscanner'); break;
        case 2: Navigator.pushNamed(context, '/addproduct'); break;
        case 3: Navigator.pushNamed(context, '/list_equipment'); break;
        case 4: Navigator.pushNamed(context, '/profile'); break;
      }
    } else {
      switch (index) {
        case 0: break;
        case 1: Navigator.pushNamed(context, '/qrscanner'); break;
        case 2: Navigator.pushNamed(context, '/vueinstitut'); break;
        case 3: Navigator.pushNamed(context, '/3dmap'); break;
        case 4: Navigator.pushNamed(context, '/addproduct'); break;
        case 5: Navigator.pushNamed(context, '/profile'); break;
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?['name'] as String? ?? 'User';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(
              userName: userName,
              location: 'ISET Mahdia',
              notificationCount: _notifCount,
              onProfileTap: () => Navigator.pushNamed(context, '/profile'),
              onNotificationTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()))
                    .then((_) => setState(() =>
                        _notifCount = NotificationService.instance.unreadCount));
              },
              onSignOut: () {},
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search inventory...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role badge
                  _RoleBadge(auth: auth),
                  const SizedBox(height: 16),

                  // Quick Actions
                  Text('Quick actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),

                  // Scan QR + Add Product — everyone
                  Row(children: [
                    Expanded(
                      child: QuickActionCard(
                        title: 'Scan QR',
                        subtitle: 'Barcode & QR support',
                        icon: Icons.qr_code_2,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.pushNamed(context, '/qrscanner'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QuickActionCard(
                        title: 'Add product',
                        subtitle: 'Manual entry',
                        icon: Icons.add,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.pushNamed(context, '/addproduct'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  QuickActionCard(
                    title: 'List Equipment',
                    subtitle: 'Search & manage equipment',
                    icon: Icons.list_alt_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.pushNamed(context, '/list_equipment'),
                  ),
                  const SizedBox(height: 12),

                  // Admin & Magazinier only below this line
                  if (auth.canViewMaps) ...[
                    QuickActionCard(
                      title: 'AirTag Tracker',
                      subtitle: 'Track DIY GPS devices',
                      icon: Icons.bluetooth_searching,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      onTap: () async {
                        const url = 'https://dchristl.github.io/macless-haystack/';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Admin-only: User management
                  if (auth.isAdmin) ...[
                    QuickActionCard(
                      title: 'Gestion Utilisateurs',
                      subtitle: 'Gérer les rôles et accès',
                      icon: Icons.manage_accounts,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      onTap: () => Navigator.pushNamed(context, '/admin/users'),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 20),

                  // ISET card + Departments + Maps — admin & magazinier only
                  if (auth.canViewMaps) ...[
                    const InventaireCard(),
                    const SizedBox(height: 32),
                    Text('Departments',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        _DepartmentButton(label: 'GI', color: AppColors.primary,
                            onTap: () => Navigator.pushNamed(context, '/departement_gi')),
                        _DepartmentButton(label: 'GE', color: const Color(0xFFF97316),
                            onTap: () => Navigator.pushNamed(context, '/departement_ge')),
                        _DepartmentButton(label: 'TC', color: const Color(0xFF16A34A),
                            onTap: () => Navigator.pushNamed(context, '/departement_tc')),
                        _DepartmentButton(label: 'ADM', color: const Color(0xFFA855F7),
                            onTap: () => Navigator.pushNamed(context, '/departement_adm')),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(children: [
                      Expanded(
                        child: QuickActionCard(
                          title: 'Equipment map',
                          subtitle: '2D locations',
                          icon: Icons.location_on_outlined,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          onTap: () => Navigator.pushNamed(context, '/equipmentmap'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickActionCard(
                          title: '3D map',
                          subtitle: 'Interactive 3D view',
                          icon: Icons.view_in_ar,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          onTap: () => Navigator.pushNamed(context, '/3dmap'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 32),
                  ],

                  // Overview Stats — everyone
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Overview',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/list_equipment'),
                        child: Row(children: [
                          Text('View all',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const OverviewStats(),
                  const SizedBox(height: 32),

                  Text('Recent activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const RecentActivity(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => _onNavTap(i, auth),
        type: BottomNavigationBarType.fixed,
        items: _navItems(auth),
      ),
    );
  }
}

// ── Role badge ─────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final AuthProvider auth;
  const _RoleBadge({required this.auth});

  Color get _color {
    switch (auth.role) {
      case 'admin':      return const Color(0xFFEF4444);
      case 'magazinier': return const Color(0xFF4F46E5);
      default:           return const Color(0xFF10B981);
    }
  }

  IconData get _icon {
    switch (auth.role) {
      case 'admin':      return Icons.shield;
      case 'magazinier': return Icons.inventory_2;
      default:           return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon, size: 16, color: _color),
        const SizedBox(width: 8),
        Text(auth.displayRole,
            style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

// ── Department button ──────────────────────────────────────────────────────────

class _DepartmentButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _DepartmentButton({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        ),
      ),
    );
  }
}
