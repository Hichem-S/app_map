import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class RecentActivity extends StatefulWidget {
  const RecentActivity({Key? key}) : super(key: key);

  @override
  State<RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<RecentActivity> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final history = await ApiService.getScanHistory();
      if (!mounted) return;
      setState(() {
        _items = history.take(8).map((e) => e as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    final local = DateTime.tryParse(raw)?.toLocal();
    if (local == null) return '';
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(local.year, local.month, local.day);
    final hm    = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (day == today) return hm;
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday $hm';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} $hm';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return GestureDetector(
        onTap: _load,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                      color: AppColors.bgMuted, shape: BoxShape.circle),
                  child: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 24),
                ),
                const SizedBox(height: 10),
                const Text('Tap to retry',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.history_toggle_off_outlined,
                    size: 28, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              const Text('No recent activity',
                  style: TextStyle(
                      color: AppColors.textBody,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Scan a QR code to get started',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowMd,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 72, endIndent: 16, color: AppColors.border),
          itemBuilder: (ctx, i) => _ActivityTile(
            item: _items[i],
            timeAgo: _timeAgo(_items[i]['scanned_at'] as String?),
          ),
        ),
      ),
    );
  }
}

// ─── Single activity tile ─────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String timeAgo;

  const _ActivityTile({required this.item, required this.timeAgo});

  static const _typeConfig = {
    'product_added': (
      icon: Icons.add_box_rounded,
      color: Color(0xFF22C55E),
      bg: Color(0xFFDCFCE7),
      label: 'Added',
    ),
    'scan': (
      icon: Icons.qr_code_scanner,
      color: AppColors.primary,
      bg: AppColors.primaryGlow,
      label: 'Scanned',
    ),
    'dept_qr': (
      icon: Icons.account_balance_rounded,
      color: Color(0xFF0EA5E9),
      bg: Color(0xFFE0F2FE),
      label: 'Dept',
    ),
    'status_changed': (
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFFF59E0B),
      bg: Color(0xFFFFF8E6),
      label: 'Updated',
    ),
    'moved': (
      icon: Icons.drive_file_move_outlined,
      color: Color(0xFF8B5CF6),
      bg: Color(0xFFF5F3FF),
      label: 'Moved',
    ),
  };

  static const _statusLabels = {
    'in_stock':       'In Stock',
    'in_maintenance': 'Maintenance',
    'critical_issue': 'Critical',
    'retired':        'Retired',
  };

  String _contextLine(String type, String? actionDataRaw) {
    if (actionDataRaw == null || actionDataRaw.isEmpty) return '';
    try {
      final d = jsonDecode(actionDataRaw) as Map<String, dynamic>;
      if (type == 'moved') {
        final from = d['from_room'] as String?;
        final to   = d['to_room']   as String?;
        if (from != null && to != null) return '$from → $to';
        if (to != null) return '→ $to';
      }
      if (type == 'status_changed') {
        final oldS = _statusLabels[d['old_status']] ?? d['old_status'] as String? ?? '';
        final newS = _statusLabels[d['new_status']] ?? d['new_status'] as String? ?? '';
        if (oldS.isNotEmpty && newS.isNotEmpty) return '$oldS → $newS';
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String? ?? 'scan';
    final cfg  = _typeConfig[type] ?? _typeConfig['scan']!;

    final name         = item['name']            as String? ?? '—';
    final sku          = item['sku']             as String? ?? '';
    final categoryName = item['category_name']   as String? ?? '';
    final deptCode     = item['department_code'] as String?;
    final photoUrl     = item['photo_url']       as String?;
    final userName     = item['user_name']       as String?;
    final userRole     = item['user_role']       as String? ?? '';
    final actionData   = item['action_data']     as String?;
    final contextLine  = _contextLine(type, actionData);

    final baseHost = ApiService.baseUrl.replaceAll('/api', '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Thumbnail / icon ─────────────────────────────────────────────
          SizedBox(
            width: 44, height: 44,
            child: photoUrl != null && photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '$baseHost$photoUrl',
                      width: 44, height: 44, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconBox(cfg.icon, cfg.color, cfg.bg),
                    ),
                  )
                : _iconBox(cfg.icon, cfg.color, cfg.bg),
          ),

          const SizedBox(width: 12),

          // ── Text ─────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product / item name
                Text(name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textH)),
                const SizedBox(height: 4),

                // Badges row
                Row(children: [
                  _Badge(label: cfg.label, color: cfg.color, bg: cfg.bg),
                  if (deptCode != null) ...[
                    const SizedBox(width: 5),
                    _Badge(
                      label: deptCode,
                      color: const Color(0xFF0284C7),
                      bg: const Color(0xFFE0F2FE),
                    ),
                  ],
                  if (categoryName.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(categoryName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                    ),
                  ],
                ]),

                // Context line (move / status change)
                if (contextLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(
                      type == 'moved'
                          ? Icons.arrow_forward_rounded
                          : Icons.sync_alt_rounded,
                      size: 11, color: cfg.color,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(contextLine,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: cfg.color,
                              fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Right column: time + user avatar + trend ──────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(timeAgo,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400)),
              const SizedBox(height: 6),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (userName != null) ...[
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: cfg.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: cfg.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.trending_up_rounded,
                      size: 14, color: Color(0xFF22C55E)),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color, Color bg) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ─── Small badge chip ─────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
