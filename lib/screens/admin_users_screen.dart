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
    'admin':      Color(0xFF6D28D9),   // violet — elevated authority
    'magazinier': AppColors.primary,   // indigo
    'technicien': AppColors.accent,    // sky
    'user':       AppColors.accent,
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
        SnackBar(content: Text('${user['name']} deleted'),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showRolePicker(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Change role — ${user['name']}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textH)),
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
                    color: selected ? color.withOpacity(0.08) : AppColors.bgMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? color : AppColors.border,
                        width: selected ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(_roleIcon(r), color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(_roleLabels[r] ?? r,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? color : AppColors.textH)),
                    const Spacer(),
                    if (selected) Icon(Icons.check_circle_rounded, color: color, size: 18),
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradHeader),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Management',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Roles & access control',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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

  void _showAddUserSheet(BuildContext context) {
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl  = TextEditingController();
    String selectedRole = 'technicien';
    bool obscure = true;
    bool saving  = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
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
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('New User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textH)),
                  Text('Account active immediately', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ]),
              ]),
              const SizedBox(height: 20),
              // Name
              _sheetField(nameCtrl,  'Full name',  Icons.person_outline_rounded),
              const SizedBox(height: 12),
              // Email
              _sheetField(emailCtrl, 'Email address', Icons.email_outlined,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              // Password
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                style: const TextStyle(fontSize: 14, color: AppColors.textH),
                decoration: InputDecoration(
                  hintText: 'Password (min. 6 chars)',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18, color: AppColors.textMuted),
                    onPressed: () => setSheet(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Role selector
              const Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(children: _roles.map((r) {
                final sel = selectedRole == r;
                final color = _roleColors[r] ?? AppColors.primary;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setSheet(() => selectedRole = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: r != _roles.last ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? color.withOpacity(0.1) : AppColors.bgMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? color : AppColors.border,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_roleIcon(r), size: 18, color: sel ? color : AppColors.textMuted),
                        const SizedBox(height: 4),
                        Text(_roleLabels[r] ?? r,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel ? color : AppColors.textBody)),
                      ]),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 20),
              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: saving
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.gradPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        ),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Create Account',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        onPressed: () async {
                          final name  = nameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final pass  = passCtrl.text;
                          if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All fields are required'),
                                  behavior: SnackBarBehavior.floating),
                            );
                            return;
                          }
                          setSheet(() => saving = true);
                          try {
                            final res = await ApiService.createUser(name, email, pass, selectedRole);
                            if (!context.mounted) return;
                            if (res['success'] == true) {
                              Navigator.pop(ctx);
                              await _load();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name added successfully'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Failed to create user'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating),
                              );
                            }
                          } finally {
                            setSheet(() => saving = false);
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TextField _sheetField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? type,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontSize: 14, color: AppColors.textH),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowSm,
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
                    color: AppColors.bgMuted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Inactive', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
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
                color: isActive ? const Color(0xFFEEF2FF) : AppColors.bgMuted,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.border),
              ),
              child: Text(
                isActive ? 'Active' : 'Blocked',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.primary : AppColors.textMuted),
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
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.error.withOpacity(0.25)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.delete_outline, size: 11, color: AppColors.error),
                SizedBox(width: 3),
                Text('Delete',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}
