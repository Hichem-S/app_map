import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/ws_service.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool get notificationsEnabled => !NotificationService.instance.muted;
  bool biometricEnabled = true;

  Map<String, dynamic>? _user;
  List<dynamic> _scanHistory = [];
  Map<String, dynamic>? _stats;
  bool _loadingUser  = true;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.photo_library, color: Color(0xFF4F46E5))),
            title: const Text('Choose from gallery',
                style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.camera_alt, color: Color(0xFF4F46E5))),
            title: const Text('Take a photo',
                style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final res = await ApiService.uploadAvatar(picked);
      if (mounted && res['success'] == true) {
        setState(() => _user = res['data'] as Map<String, dynamic>);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed, please try again'),
              backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        ApiService.getMe(),
        ApiService.getScanHistory(),
        ApiService.getStats(),
      ]);
      if (!mounted) return;
      final me = results[0] as Map<String, dynamic>;
      setState(() {
        if (me['success'] == true) _user = me['data'] as Map<String, dynamic>;
        _scanHistory = results[1] as List<dynamic>;
        _stats = results[2] as Map<String, dynamic>?;
        _loadingUser = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  String get _userName => _user?['name'] ?? '—';
  String get _userEmail => _user?['email'] ?? '—';
  String get _userRole => _user?['role'] ?? '—';

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient background
            _buildHeader(context),
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats cards
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  // Institution card
                  _buildInstitutionCard(context),
                  const SizedBox(height: 24),
                  // Badges section
                  _buildBadgesSection(),
                  const SizedBox(height: 24),
                  // Personal information
                  _buildPersonalInfoSection(context),
                  const SizedBox(height: 24),
                  // Recent activity
                  _buildRecentActivitySection(context),
                  const SizedBox(height: 24),
                  // User change
                  _buildUserChangeSection(context),
                  const SizedBox(height: 24),
                  // Preferences
                  _buildPreferencesSection(context),
                  const SizedBox(height: 24),
                  // Application section
                  _buildApplicationSection(context),
                  const SizedBox(height: 24),
                  // Support section
                  _buildSupportSection(context),
                  const SizedBox(height: 24),
                  // App info card
                  _buildAppInfoCard(context),
                  const SizedBox(height: 24),
                  // Sign out button
                  _buildSignOutButton(context),
                  const SizedBox(height: 32),
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),  // Scaffold
    );    // PopScope
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[700]!,
            Colors.purple[600]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
              const Text(
                'Mon Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => _showEditProfileSheet(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Profile image with status
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      colors: [Colors.cyan[300]!, Colors.blue[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: _uploadingAvatar
                        ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : _buildAvatarContent(),
                  ),
                ),
              ),
              // Status indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
              // Camera button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue[700],
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 17),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            _userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // Role
          _buildRoleBadge(_userRole),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    final avatarPath = _user?['avatar'] as String?;
    final url = ApiService.avatarUrl(avatarPath);
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (_, __, ___) => _avatarInitial(),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
      );
    }
    return _avatarInitial();
  }

  Widget _avatarInitial() => Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildRoleBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalScans = _stats?['total_scans'] ?? _scanHistory.length;
    final totalProducts = _stats?['total_products'] ?? 0;
    final categoriesUsed = _stats?['categories_used'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.qr_code_scanner,
            count: totalScans.toString(),
            label: 'Scans',
            iconColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2,
            count: totalProducts.toString(),
            label: 'Produits',
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.category,
            count: categoriesUsed.toString(),
            label: 'Types',
            iconColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Institution',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ISET Mahdia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Higher Institute of Technological Studies',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/vueinstitut'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Text(
                'Voir →',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    final badges = [
      _BadgeItem('Premier Scan', Icons.search, Colors.blue, true),
      _BadgeItem('Technicien Pro', Icons.build, Colors.purple, true),
      _BadgeItem('100 Inventaires', Icons.inventory_2, Colors.grey, false),
      _BadgeItem('Expert ISET', Icons.star, Colors.amber, true),
      _BadgeItem('Actif 30 jours', Icons.fitness_center, Colors.orange, true),
      _BadgeItem('Maintenance+', Icons.settings, Colors.grey, false),
      _BadgeItem('Top Gestionnaire', Icons.person, Colors.grey, false),
      _BadgeItem('Sécurité Max', Icons.lock, Colors.green, true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BADGES & RÉALISATIONS',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: badges.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => _buildBadgeCard(badges[index]),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(_BadgeItem badge) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.unlocked ? Colors.blue[200]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge.icon,
                color: badge.unlocked ? badge.color : Colors.grey[400],
                size: 32,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (badge.unlocked)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INFORMATIONS PERSONNELLES',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: Icons.person,
          iconColor: Colors.blue,
          label: 'Nom complet',
          value: _userName,
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: Icons.badge,
          iconColor: Colors.purple,
          label: 'Badge / Matricule',
          value: 'ADM-001',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: Icons.security,
          iconColor: Colors.purple,
          label: 'Role',
          value: _userRole,
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: Icons.domain,
          iconColor: Colors.green,
          label: 'Department',
          value: 'Administration',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: Icons.email,
          iconColor: Colors.orange,
          label: 'Email',
          value: _userEmail,
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          icon: Icons.phone,
          iconColor: Colors.teal,
          label: 'Phone',
          value: '+216 73 675 101',
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVITÉ RÉCENTE',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        if (_scanHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Text(
                'No recent activity',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int index = 0;
                  index < (_scanHistory.length > 10 ? 10 : _scanHistory.length);
                  index++) ...[
                if (index > 0) const SizedBox(height: 8),
                Builder(builder: (context) {
                  final item = _scanHistory[index] as Map<String, dynamic>;
                  final scannedAt = DateTime.tryParse(item['scanned_at'] ?? '');
                  final timeAgo = scannedAt != null ? _timeAgo(scannedAt) : '';
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? '—',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['category_name'] ?? item['sku'] ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildUserChangeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHANGER D\'UTILISATEUR',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildCollapsibleItem(
          icon: Icons.person,
          iconColor: Colors.purple,
          title: 'Profil actif : $_userName',
          subtitle: _userRole,
          onTap: () {
            final auth = context.read<AuthProvider>();
            if (auth.canManageUsers) {
              Navigator.pushNamed(context, '/admin/users');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact an admin to manage accounts'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRÉFÉRENCES',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildToggleItem(
          icon: Icons.notifications,
          iconColor: Colors.red,
          title: 'Notifications',
          subtitle: 'Alertes état équipement',
          value: notificationsEnabled,
          onChanged: (value) {
            NotificationService.instance.setMuted(!value);
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        _buildToggleItem(
          icon: Icons.dark_mode,
          iconColor: Colors.grey,
          title: 'Mode Sombre',
          subtitle: 'Thème interface',
          value: context.watch<ThemeProvider>().isDarkMode,
          onChanged: (value) {
            context.read<ThemeProvider>().setDarkMode(value);
          },
        ),
        const SizedBox(height: 12),
        _buildToggleItem(
          icon: Icons.fingerprint,
          iconColor: Colors.green,
          title: 'Authentication Biométrique',
          subtitle: 'Face ID / Empreinte digitale',
          value: biometricEnabled,
          onChanged: (value) {
            setState(() => biometricEnabled = value);
          },
        ),
        const SizedBox(height: 12),
        _buildLanguageItem(),
      ],
    );
  }

  Widget _buildLanguageItem() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.public,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Language',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'English',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }

  Widget _buildApplicationSection(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APPLICATION',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Notifications — all roles
        _buildNavigableItem(
          icon: Icons.notifications_outlined,
          iconColor: Colors.red,
          title: 'Notifications',
          subtitle: 'Item moves & alerts',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        const SizedBox(height: 12),

        // Equipment list — all roles
        _buildNavigableItem(
          icon: Icons.inventory_2_outlined,
          iconColor: Colors.teal,
          title: 'Equipment List',
          subtitle: 'Browse all inventory items',
          onTap: () => Navigator.pushNamed(context, '/list_equipment'),
        ),
        const SizedBox(height: 12),

        // QR scanner — all roles, but label differs
        _buildNavigableItem(
          icon: Icons.qr_code_scanner,
          iconColor: Colors.purple,
          title: 'QR Scanner',
          subtitle: auth.canViewMaps
              ? 'Scan items, rooms & departments'
              : 'Scan inventory items',
          onTap: () => Navigator.pushNamed(context, '/qrscanner'),
        ),

        // Hierarchical scanner — admin & technicien only
        if (auth.canViewMaps) ...[
          const SizedBox(height: 12),
          _buildNavigableItem(
            icon: Icons.account_tree_outlined,
            iconColor: Colors.indigo,
            title: 'Hierarchical Scanner',
            subtitle: 'ISET → Dept. → Room → Equipment',
            onTap: () => Navigator.pushNamed(context, '/scan_qr_hiearchique'),
          ),
        ],

        // Add equipment — magazinier only
        if (auth.canAddProduct) ...[
          const SizedBox(height: 12),
          _buildNavigableItem(
            icon: Icons.add_box_outlined,
            iconColor: Colors.teal,
            title: 'Add Equipment',
            subtitle: 'Register a new inventory item',
            onTap: () => Navigator.pushNamed(context, '/addproduct'),
          ),
        ],

        // Maps — admin & technicien only
        if (auth.canViewMaps) ...[
          const SizedBox(height: 12),
          _buildNavigableItem(
            icon: Icons.map_outlined,
            iconColor: Colors.green,
            title: 'Equipment Map 2D',
            subtitle: 'Interactive 2D room layout',
            onTap: () => Navigator.pushNamed(context, '/equipmentmap'),
          ),
          const SizedBox(height: 12),
          _buildNavigableItem(
            icon: Icons.view_in_ar_outlined,
            iconColor: Colors.blue,
            title: 'Equipment Map 3D',
            subtitle: 'Interactive 3D room layout',
            onTap: () => Navigator.pushNamed(context, '/3dmap'),
          ),
          const SizedBox(height: 12),
          _buildNavigableItem(
            icon: Icons.apartment_outlined,
            iconColor: Colors.indigo,
            title: 'Institute View 3D',
            subtitle: 'ISET Mahdia — all departments',
            onTap: () => Navigator.pushNamed(context, '/vueinstitut'),
          ),
          const SizedBox(height: 12),
          _buildNavigableItem(
            icon: Icons.swap_horiz_rounded,
            iconColor: Colors.orange,
            title: 'Move Log',
            subtitle: 'Track every item relocation',
            onTap: () => Navigator.pushNamed(context, '/movelog'),
          ),
        ],

        // User management — admin only
        if (auth.canManageUsers) ...[
          const SizedBox(height: 12),
          _buildNavigableItem(
            icon: Icons.manage_accounts_outlined,
            iconColor: Colors.red,
            title: 'Manage Users',
            subtitle: 'Roles, accounts, access control',
            onTap: () => Navigator.pushNamed(context, '/admin/users'),
          ),
        ],
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUPPORT',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildNavigableItem(
          icon: Icons.help_outline,
          iconColor: Colors.amber,
          title: 'Aide & FAQ',
          subtitle: 'Centre d\'aide ISET',
          onTap: () => _showFaqDialog(context),
        ),
        const SizedBox(height: 12),
        _buildNavigableItem(
          icon: Icons.info_outline,
          iconColor: Colors.grey,
          title: 'À propos',
          subtitle: 'Smart Inventory v2.4 — ISET Mahdia',
          trailing: 'v2.4',
          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Inventory ISET',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Version 2.4.0 · Build 2024.04',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'À jour',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  '4.9',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final screenContext = context;
          showDialog(
            context: screenContext,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Sign Out'),
                content:
                    const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.read<AuthProvider>().clear();
                      NotificationService.instance.reset();
                      WsService.disconnect();
                      Navigator.pushNamedAndRemoveUntil(
                        screenContext,
                        '/login',
                        (_) => false,
                      );
                      ApiService.logout();
                    },
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Color(0xFFEF4444), width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 8),
            Text(
              'Se Déconnecter',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigableItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  // ── Edit profile bottom sheet ────────────────────────────────────────────────

  void _showEditProfileSheet(BuildContext context) {
    final nameCtrl  = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Edit Profile',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailCtrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Email (read-only)',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7CFC),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated'),
                    backgroundColor: Color(0xFF22C55E),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save Changes',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── FAQ dialog ────────────────────────────────────────────────────────────────

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.help_outline, color: Colors.amber),
          SizedBox(width: 8),
          Text('Aide & FAQ'),
        ]),
        content: const SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _FaqItem(
              q: 'How do I scan an item?',
              a: 'Tap "QR Scanner" and point the camera at any QR code on equipment, rooms, or departments.',
            ),
            SizedBox(height: 12),
            _FaqItem(
              q: 'How do I move equipment on the map?',
              a: 'Open Equipment Map 2D, tap the move icon (↔) in the header, select an item, then tap the destination room.',
            ),
            SizedBox(height: 12),
            _FaqItem(
              q: 'Who gets notified when equipment moves?',
              a: 'All technicians and admins receive a notification when any item is relocated.',
            ),
            SizedBox(height: 12),
            _FaqItem(
              q: 'How do I change a user role?',
              a: 'Admin only: go to Manage Users and tap on the user to change their role.',
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── About dialog ─────────────────────────────────────────────────────────────

  void _showAboutDialog(BuildContext ctx) {
    showAboutDialog(
      context: ctx,
      applicationName: 'Smart Inventory ISET',
      applicationVersion: '2.4.0',
      applicationLegalese: '© 2024 ISET Mahdia — All rights reserved',
      children: [
        const SizedBox(height: 12),
        const Text(
          'Smart Inventory is a real-time equipment tracking system for ISET Mahdia. '
          'It allows technicians and administrators to locate, move, and manage institutional assets using QR codes and interactive maps.',
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      'Higher Institute of Technological Studies of Mahdia © 2024 — All rights reserved',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey[600],
      ),
    );
  }
}

class _BadgeItem {
  final String name;
  final IconData icon;
  final Color color;
  final bool unlocked;

  _BadgeItem(this.name, this.icon, this.color, this.unlocked);
}

class _FaqItem extends StatelessWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(q,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(a,
          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ]);
  }
}
