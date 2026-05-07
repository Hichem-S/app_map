import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  static const _roles = ['admin', 'magazinier', 'technicien'];

  static const _roleColors = {
    'admin':      Color(0xFFEF4444),
    'magazinier': Color(0xFF4F46E5),
    'technicien': Color(0xFF10B981),
    'user':       Color(0xFF10B981),
  };

  static const _roleLabels = {
    'admin':      'Administrateur',
    'magazinier': 'Magazinier',
    'technicien': 'Technicien',
    'user':       'Technicien',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getUsers();
      if (!mounted) return;
      setState(() {
        _users = raw.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(Map<String, dynamic> user, String newRole) async {
    final res = await ApiService.updateUserRole(user['id'] as String, newRole);
    if (res['success'] == true && mounted) {
      setState(() {
        final idx = _users.indexWhere((u) => u['id'] == user['id']);
        if (idx != -1) _users[idx] = {..._users[idx], 'role': newRole};
      });
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    final res = await ApiService.toggleUserStatus(user['id'] as String);
    if (res['success'] == true && mounted) {
      final updated = res['data'] as Map<String, dynamic>;
      setState(() {
        final idx = _users.indexWhere((u) => u['id'] == user['id']);
        if (idx != -1) _users[idx] = {..._users[idx], 'is_active': updated['is_active']};
      });
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Voulez-vous vraiment supprimer ${user['name']} ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final res = await ApiService.deleteUser(user['id'] as String);
    if (res['success'] == true && mounted) {
      setState(() => _users.removeWhere((u) => u['id'] == user['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user['name']} supprimé'),
            backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showRolePicker(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Changer le rôle de ${user['name']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._roles.map((r) {
              final selected = (user['role'] as String?) == r;
              final color = _roleColors[r] ?? AppColors.primary;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (!selected) _changeRole(user, r);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? color.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? color : Colors.grey[300]!, width: selected ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Icon(_roleIcon(r), color: color, size: 20),
                    const SizedBox(width: 12),
                    Text(_roleLabels[r] ?? r,
                        style: TextStyle(fontSize: 14,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? color : Colors.black87)),
                    const Spacer(),
                    if (selected) Icon(Icons.check_circle, color: color, size: 18),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':      return Icons.shield;
      case 'magazinier': return Icons.inventory_2;
      default:           return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestion Utilisateurs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textH)),
            Text('Gérer les rôles et accès',
                style: TextStyle(fontSize: 12, color: AppColors.textBody)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (_, i) => _UserCard(
                  user: _users[i],
                  roleColors: _roleColors,
                  roleLabels: _roleLabels,
                  roleIcon: _roleIcon,
                  onRoleTap: () => _showRolePicker(_users[i]),
                  onToggleStatus: () => _toggleStatus(_users[i]),
                  onDelete: () => _confirmDelete(_users[i]),
                ),
              ),
            ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map<String, Color> roleColors;
  final Map<String, String> roleLabels;
  final IconData Function(String) roleIcon;
  final VoidCallback onRoleTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.roleColors,
    required this.roleLabels,
    required this.roleIcon,
    required this.onRoleTap,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final role     = user['role'] as String? ?? 'technicien';
    final isActive = user['is_active'] as bool? ?? true;
    final color    = roleColors[role] ?? AppColors.primary;
    final avatar   = user['avatar'] as String?;
    final name     = user['name'] as String? ?? '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.15),
          backgroundImage: avatar != null && avatar.isNotEmpty
              ? NetworkImage(ApiService.avatarUrl(avatar))
              : null,
          child: (avatar == null || avatar.isEmpty)
              ? Text(name[0].toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))
              : null,
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH)),
              ),
              const SizedBox(width: 6),
              if (!isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Inactif', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ),
            ]),
            const SizedBox(height: 2),
            Text(user['email'] as String? ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
        const SizedBox(width: 8),
        // Role chip (tap to change)
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          GestureDetector(
            onTap: onRoleTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(roleIcon(role), size: 12, color: color),
                const SizedBox(width: 4),
                Text(roleLabels[role] ?? role,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(width: 2),
                Icon(Icons.expand_more, size: 12, color: color),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          // Active toggle
          GestureDetector(
            onTap: onToggleStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE6F9F2) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Actif' : 'Bloquer',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF10B981) : Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Delete button
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.delete_outline, size: 11, color: Color(0xFFEF4444)),
                SizedBox(width: 3),
                Text('Supprimer',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}
