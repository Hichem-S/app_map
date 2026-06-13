import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/ws_service.dart';
import '../utils/app_colors.dart';
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
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.photo_library, color: AppColors.primary)),
            title: const Text('Choose from gallery',
                style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.camera_alt, color: AppColors.primary)),
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
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed, please try again'),
              backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
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

  String get _userName => _user?['name'] ?? 'â€”';
  String get _userEmail => _user?['email'] ?? 'â€”';
  String get _userRole => _user?['role'] ?? 'â€”';

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
      backgroundColor: AppColors.bg(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildInstitutionCard(context),
                  const SizedBox(height: 24),
                  _buildBadgesSection(),
                  const SizedBox(height: 24),
                  _buildPersonalInfoSection(context),
                  const SizedBox(height: 24),
                  _buildRecentActivitySection(context),
                  const SizedBox(height: 24),
                  _buildUserChangeSection(context),
                  const SizedBox(height: 24),
                  _buildPreferencesSection(context),
                  const SizedBox(height: 24),
                  _buildApplicationSection(context),
                  const SizedBox(height: 24),
                  _buildSupportSection(context),
                  const SizedBox(height: 24),
                  _buildAppInfoCard(context),
                  const SizedBox(height: 24),
                  _buildSignOutButton(context),
                  const SizedBox(height: 32),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.gradHeader,
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
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
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditProfileSheet(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: AppColors.gradPrimary,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
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
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: AppColors.shadowColored(AppColors.primary),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 17),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _buildRoleBadge(_userRole),
          ],
        ),
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
        width: 120, height: 120,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // â”€â”€ Stats cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildStatsSection() {
    final totalScans    = _stats?['total_scans']    ?? _scanHistory.length;
    final totalProducts = _stats?['total_products'] ?? 0;
    final categoriesUsed = _stats?['categories_used'] ?? 0;

    return Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: Icons.qr_code_scanner,
          count: totalScans.toString(),
          label: 'Scans',
          color: AppColors.primary,
          bg: const Color(0xFFEEF2FF),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.inventory_2,
          count: totalProducts.toString(),
          label: 'Items',
          color: AppColors.accent,
          bg: const Color(0xFFE0F2FE),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.category,
          count: categoriesUsed.toString(),
          label: 'Types',
          color: AppColors.primaryLight,
          bg: const Color(0xFFEEF2FF),
        )),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // â”€â”€ Institution card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildInstitutionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowColored(AppColors.primary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Institution',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'ISET Mahdia',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Higher Institute of Technological Studies',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
              ),
            ],
          ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/vueinstitut'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: const Text(
                'View →',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Badges â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildBadgesSection() {
    final badges = [
      _BadgeItem('First Scan',       Icons.search,        AppColors.primary,      true),
      _BadgeItem('Pro Technician',   Icons.build,         AppColors.primaryLight, true),
      _BadgeItem('100 Inventories',  Icons.inventory_2,   AppColors.textMuted,    false),
      _BadgeItem('ISET Expert',      Icons.star,          AppColors.accent,       true),
      _BadgeItem('Active 30 days',   Icons.fitness_center, AppColors.primary,     true),
      _BadgeItem('Maintenance+',     Icons.settings,      AppColors.textMuted,    false),
      _BadgeItem('Top Manager',      Icons.person,        AppColors.textMuted,    false),
      _BadgeItem('Max Security',     Icons.lock,          AppColors.primaryLight, true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('BADGES & ACHIEVEMENTS'),
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badge.unlocked ? AppColors.primary.withOpacity(0.25) : AppColors.border,
          width: badge.unlocked ? 1.5 : 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge.icon,
                color: badge.unlocked ? badge.color : AppColors.textMuted.withOpacity(0.5),
                size: 28,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badge.unlocked ? AppColors.textH : AppColors.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (badge.unlocked)
            Positioned(
              bottom: 6, right: 6,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
            ),
        ],
      ),
    );
  }

  // â”€â”€ Personal info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPersonalInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('PERSONAL INFORMATION'),
        const SizedBox(height: 12),
        _buildInfoItem(icon: Icons.person,   iconColor: AppColors.primary,      label: 'Full Name',        value: _userName),
        const SizedBox(height: 10),
        _buildInfoItem(icon: Icons.badge,    iconColor: AppColors.primaryLight,  label: 'Badge / ID',      value: 'ADM-001'),
        const SizedBox(height: 10),
        _buildInfoItem(icon: Icons.security, iconColor: AppColors.primaryLight,  label: 'Role',            value: _userRole),
        const SizedBox(height: 10),
        _buildInfoItem(icon: Icons.domain,   iconColor: AppColors.accent,        label: 'Department',      value: 'Administration'),
        const SizedBox(height: 10),
        _buildInfoItem(icon: Icons.email,    iconColor: AppColors.primary,       label: 'Email',           value: _userEmail),
        const SizedBox(height: 10),
        _buildInfoItem(icon: Icons.phone,    iconColor: AppColors.accent,        label: 'Phone',           value: '+216 73 675 101'),
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Recent activity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('RECENT ACTIVITY'),
        const SizedBox(height: 12),
        if (_scanHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text('No recent activity',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
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
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? 'â€”',
                                style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['category_name'] ?? item['sku'] ?? '',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(timeAgo,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // â”€â”€ User change â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildUserChangeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SWITCH USER'),
        const SizedBox(height: 12),
        _buildCollapsibleItem(
          icon: Icons.person,
          iconColor: AppColors.primaryLight,
          title: 'Active profile: $_userName',
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

  // â”€â”€ Preferences â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('PREFERENCES'),
        const SizedBox(height: 12),
        _buildToggleItem(
          icon: Icons.notifications,
          iconColor: AppColors.error,
          title: 'Notifications',
          subtitle: 'Equipment status alerts',
          value: notificationsEnabled,
          onChanged: (value) {
            NotificationService.instance.setMuted(!value);
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        _buildLanguagePicker(context),
        const SizedBox(height: 10),
        _buildToggleItem(
          icon: Icons.dark_mode,
          iconColor: AppColors.textBody,
          title: 'Dark Mode',
          subtitle: 'Interface theme',
          value: context.watch<ThemeProvider>().isDarkMode,
          onChanged: (value) {
            context.read<ThemeProvider>().setDarkMode(value);
          },
        ),
        const SizedBox(height: 10),
        _buildToggleItem(
          icon: Icons.fingerprint,
          iconColor: AppColors.accent,
          title: 'Biometric Auth',
          subtitle: 'Face ID / Fingerprint',
          value: biometricEnabled,
          onChanged: (value) {
            setState(() => biometricEnabled = value);
          },
        ),
      ],
    );
  }

  // â”€â”€ Application â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildApplicationSection(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('APPLICATION'),
        const SizedBox(height: 12),
        _buildNavigableItem(
          icon: Icons.notifications_outlined,
          iconColor: AppColors.error,
          title: 'Notifications',
          subtitle: 'Item moves & alerts',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        const SizedBox(height: 10),
        _buildNavigableItem(
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.accent,
          title: 'Equipment List',
          subtitle: 'Browse all inventory items',
          onTap: () => Navigator.pushNamed(context, '/list_equipment'),
        ),
        const SizedBox(height: 10),
        _buildNavigableItem(
          icon: Icons.qr_code_scanner,
          iconColor: AppColors.primaryLight,
          title: 'QR Scanner',
          subtitle: auth.canViewMaps
              ? 'Scan items, rooms & departments'
              : 'Scan inventory items',
          onTap: () => Navigator.pushNamed(context, '/qrscanner'),
        ),
        if (auth.canViewMaps) ...[
          const SizedBox(height: 10),
          _buildNavigableItem(
            icon: Icons.account_tree_outlined,
            iconColor: AppColors.primary,
            title: 'Hierarchical Scanner',
            subtitle: 'ISET → Dept. → Room → Equipment',
            onTap: () => Navigator.pushNamed(context, '/scan_qr_hiearchique'),
          ),
        ],
        if (auth.canAddProduct) ...[
          const SizedBox(height: 10),
          _buildNavigableItem(
            icon: Icons.add_box_outlined,
            iconColor: AppColors.accent,
            title: 'Add Equipment',
            subtitle: 'Register a new inventory item',
            onTap: () => Navigator.pushNamed(context, '/addproduct'),
          ),
        ],
        if (auth.canViewMaps) ...[
          const SizedBox(height: 10),
          _buildNavigableItem(
            icon: Icons.map_outlined,
            iconColor: AppColors.accent,
            title: 'Equipment Map 2D',
            subtitle: 'Interactive 2D room layout',
            onTap: () => Navigator.pushNamed(context, '/equipmentmap'),
          ),
          const SizedBox(height: 10),
          _buildNavigableItem(
            icon: Icons.view_in_ar_outlined,
            iconColor: AppColors.primary,
            title: 'Equipment Map 3D',
            subtitle: 'Interactive 3D room layout',
            onTap: () => Navigator.pushNamed(context, '/3dmap'),
          ),
          const SizedBox(height: 10),
          _buildNavigableItem(
            icon: Icons.apartment_outlined,
            iconColor: AppColors.primary,
            title: 'Institute View',
            subtitle: 'ISET Mahdia â€” all departments',
            onTap: () => Navigator.pushNamed(context, '/vueinstitut'),
          ),
          const SizedBox(height: 10),
          _buildNavigableItem(
            icon: Icons.swap_horiz_rounded,
            iconColor: AppColors.primaryLight,
            title: 'Move Log',
            subtitle: 'Track every item relocation',
            onTap: () => Navigator.pushNamed(context, '/movelog'),
          ),
        ],
        if (auth.canManageUsers) ...[
          const SizedBox(height: 10),
          _buildNavigableItem(
            icon: Icons.manage_accounts_outlined,
            iconColor: AppColors.error,
            title: 'Manage Users',
            subtitle: 'Roles, accounts, access control',
            onTap: () => Navigator.pushNamed(context, '/admin/users'),
          ),
          const SizedBox(height: 10),
          _buildNavigableItem(
            icon: Icons.summarize_outlined,
            iconColor: const Color(0xFF059669),
            title: 'ISET Global Report',
            subtitle: 'Download full inventory PDF — all departments',
            onTap: () => _downloadIsetReport(),
          ),
        ],
      ],
    );
  }

  Future<void> _downloadIsetReport() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Generating ISET report…'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
    try {
      final path = await ApiService.downloadIsetReport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(path != null
            ? 'Report saved: ${path.split('/').last}'
            : 'Download failed'),
        backgroundColor: path != null ? const Color(0xFF059669) : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // â”€â”€ Support â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SUPPORT'),
        const SizedBox(height: 12),
        _buildNavigableItem(
          icon: Icons.help_outline,
          iconColor: AppColors.primaryLight,
          title: 'Help & FAQ',
          subtitle: 'ISET help center',
          onTap: () => _showFaqDialog(context),
        ),
        const SizedBox(height: 10),
        _buildNavigableItem(
          icon: Icons.info_outline,
          iconColor: AppColors.textMuted,
          title: 'About',
          subtitle: 'Smart Inventory v2.4 â€” ISET Mahdia',
          trailing: 'v2.4',
          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  // â”€â”€ App info card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAppInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.gradPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inventory_2, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart Inventory ISET',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textH)),
                const Text('Version 2.4.0 · Build 2024.04',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 13, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text('Up to date',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text('4.9',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Sign out â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final screenContext = context;
          showDialog(
            context: screenContext,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
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
                        screenContext, '/login', (_) => false);
                    ApiService.logout();
                  },
                  child: const Text('Sign Out',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Sign Out',
                style: TextStyle(
                    color: AppColors.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Shared list item widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildCollapsibleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePicker(BuildContext context) {
    final lang     = context.watch<LanguageProvider>();
    final current  = lang.locale.languageCode;
    final langs    = LanguageProvider.languages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH)),
          Text('App display language', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ])),
        DropdownButton<String>(
          value: current,
          underline: const SizedBox.shrink(),
          icon: const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textMuted),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textH),
          items: langs.map((l) => DropdownMenuItem<String>(
            value: l['code']!,
            child: Text('${l['flag']} ${l['native']}'),
          )).toList(),
          onChanged: (code) {
            if (code != null) context.read<LanguageProvider>().setLanguage(code);
          },
        ),
      ]),
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
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
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500))
            else
              const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildFooter() => const Text(
        'Higher Institute of Technological Studies of Mahdia © 2026 â€” All rights reserved',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
      );

  // â”€â”€ Edit profile sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showEditProfileSheet(BuildContext context) {
    final nameCtrl  = TextEditingController(text: _userName);
    final emailCtrl = TextEditingController(text: _userEmail);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Edit Profile',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textH)),
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
              fillColor: AppColors.bgMuted,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated'),
                    backgroundColor: AppColors.accent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save Changes',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  // â”€â”€ FAQ dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.help_outline, color: AppColors.primaryLight),
          SizedBox(width: 8),
          Text('Help & FAQ'),
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

  // â”€â”€ About dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showAboutDialog(BuildContext ctx) {
    showAboutDialog(
      context: ctx,
      applicationName: 'Smart Inventory ISET',
      applicationVersion: '2.4.0',
      applicationLegalese: '© 2026 ISET Mahdia â€” All rights reserved',
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
}

// â”€â”€ Data classes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      Text(q, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textH)),
      const SizedBox(height: 4),
      Text(a, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
    ]);
  }
}


