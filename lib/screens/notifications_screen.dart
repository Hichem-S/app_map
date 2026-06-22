import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../models/app_notification.dart';
import '../utils/app_colors.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import 'maintenance_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _primary = Color(0xFF1A2340);

  @override
  void initState() {
    super.initState();
    NotificationService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  String _timeAgo(DateTime dt) => _fmtTime(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    final notifs = NotificationService.instance.all;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          if (notifs.isNotEmpty)
            TextButton(
              onPressed: () {
                NotificationService.instance.markAllRead();
                setState(() {});
              },
              child: const Text('Tout lire',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          if (notifs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 22),
              tooltip: 'Tout supprimer',
              onPressed: () {
                NotificationService.instance.clearAll();
                setState(() {});
              },
            ),
        ],
      ),
      body: notifs.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: notifs.length,
              itemBuilder: (_, i) => _NotifCard(
                notif: notifs[i],
                timeAgo: _timeAgo(notifs[i].createdAt),
                onTap: () {
                  NotificationService.instance.markRead(notifs[i].id);
                  setState(() {});
                },
                onDismiss: () {
                  NotificationService.instance.remove(notifs[i].id);
                  setState(() {});
                },
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 40, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text('Aucune notification',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2340))),
          const SizedBox(height: 6),
          const Text('Les déplacements d\'équipements\napparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black45)),
        ],
      ),
    );
  }
}

// ─── Notification card ────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifCard({
    required this.notif,
    required this.timeAgo,
    required this.onTap,
    required this.onDismiss,
  });

  static _TypeStyle _styleFor(String type) {
    switch (type) {
      case 'iot_rfid':
        return _TypeStyle(Icons.sensors_rounded,        const Color(0xFF0284C7), const Color(0xFFE0F2FE));
      case 'iot_ble':
        return _TypeStyle(Icons.bluetooth_rounded,      const Color(0xFF7C3AED), const Color(0xFFEDE9FE));
      case 'product_retired':
        return _TypeStyle(Icons.archive_outlined,       const Color(0xFFDC2626), const Color(0xFFFFE4E4));
      case 'product_critical':
        return _TypeStyle(Icons.warning_amber_rounded,  const Color(0xFFEF4444), const Color(0xFFFEE2E2));
      case 'low_stock':
        return _TypeStyle(Icons.inventory_2_outlined,   const Color(0xFFF59E0B), const Color(0xFFFEF3C7));
      case 'product_lost':
        return _TypeStyle(Icons.search_off_rounded,     const Color(0xFF8B5CF6), const Color(0xFFF3E8FF));
      case 'maintenance_assigned':
      case 'maintenance_scheduled':
        return _TypeStyle(Icons.build_rounded,          const Color(0xFFF59E0B), const Color(0xFFFEF3C7));
      case 'transfer_request':
      case 'transfer_approved':
      case 'transfer_rejected':
        return _TypeStyle(Icons.swap_horiz_rounded,     const Color(0xFF10B981), const Color(0xFFD1FAE5));
      case 'account_pending':
        return _TypeStyle(Icons.person_add_rounded,     const Color(0xFF4A7CFC), const Color(0xFFEEF2FF));
      case 'tracker_zone_alert':
        return _TypeStyle(Icons.location_off_rounded,   const Color(0xFFDC2626), const Color(0xFFFFEDED));
      default:
        return _TypeStyle(Icons.swap_horiz_rounded,     const Color(0xFF3B5BDB), const Color(0xFFEEF2FF));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notif.isRead;
    final style  = _styleFor(notif.type);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? AppColors.card(context) : style.bg,
            borderRadius: BorderRadius.circular(16),
            border: isRead
                ? Border.all(color: Colors.transparent)
                : Border.all(color: style.accent.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isRead ? 0.04 : 0.07),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: style.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.accent, size: 22),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.title,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: const Color(0xFF1A2340))),
                        ),
                        Text(timeAgo,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black38)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (notif.productName != null)
                      Text(notif.productName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A2340))),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (notif.fromRoom != null) ...[
                          const Icon(Icons.meeting_room_outlined,
                              size: 12, color: Colors.black38),
                          const SizedBox(width: 3),
                          Text(notif.fromRoom!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.arrow_forward_rounded,
                                size: 12, color: Colors.black38),
                          ),
                        ],
                        Icon(Icons.meeting_room_rounded,
                            size: 12, color: style.accent),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(notif.toRoom ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: style.accent)),
                        ),
                      ],
                    ),
                    if (notif.body.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(children: [
                        Icon(
                          notif.type == 'account_pending'
                              ? Icons.person_add_outlined
                              : notif.type == 'tracker_zone_alert'
                                  ? Icons.location_off_outlined
                                  : notif.type.startsWith('iot_')
                                      ? Icons.router_outlined
                                      : Icons.person_outline_rounded,
                          size: 12, color: Colors.black38),
                        const SizedBox(width: 4),
                        Flexible(child: Text(
                            (notif.type == 'account_pending' || notif.type == 'tracker_zone_alert')
                                ? (() { try { final m = jsonDecode(notif.body); return m['text'] as String? ?? notif.body; } catch (_) { return notif.body; } })()
                                : notif.body,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12,
                                color: Colors.black54, fontWeight: FontWeight.w500))),
                      ]),
                    ],
                    if (notif.type == 'account_pending') ...[
                      const SizedBox(height: 10),
                      _ApproveRejectButtons(notif: notif, onDone: onDismiss),
                    ],
                    if (notif.productId != null) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        if (notif.type != 'tracker_zone_alert')
                          _ActionBtn(
                            label: 'View Item',
                            icon: Icons.open_in_new_rounded,
                            color: style.accent,
                            onTap: () => _openProduct(context, notif),
                          ),
                        if (notif.type == 'tracker_zone_alert') ...[
                          _ActionBtn(
                            label: 'View Tracker',
                            icon: Icons.location_searching_rounded,
                            color: const Color(0xFFDC2626),
                            onTap: () => Navigator.pushNamed(context, '/tracker'),
                          ),
                        ],
                        if (notif.type == 'product_critical' ||
                            notif.type == 'product_moved') ...[
                          const SizedBox(width: 8),
                          _ActionBtn(
                            label: 'Maintenance',
                            icon: Icons.build_outlined,
                            color: const Color(0xFFF59E0B),
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const MaintenanceScreen())),
                          ),
                        ],
                      ]),
                    ],
                  ],
                ),
              ),
              // Unread dot
              if (!isRead)
                Container(
                  margin: const EdgeInsets.only(top: 4, left: 6),
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: style.accent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtTime(DateTime local) {
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day   = DateTime(local.year, local.month, local.day);
  final hm    = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  if (day == today) return hm;
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday $hm';
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} $hm';
}

Future<void> _openProduct(BuildContext context, AppNotification notif) async {
  if (notif.productId == null) return;
  try {
    final res = await ApiService.getProduct(notif.productId!);
    if (res['success'] == true && context.mounted) {
      final product = Product.fromJson(res['data'] as Map<String, dynamic>);
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product)));
    }
  } catch (_) {}
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );
}

// ─── Approve / Reject buttons for account_pending ────────────────────────────

class _ApproveRejectButtons extends StatefulWidget {
  final AppNotification notif;
  final VoidCallback onDone;
  const _ApproveRejectButtons({required this.notif, required this.onDone});

  @override
  State<_ApproveRejectButtons> createState() => _ApproveRejectButtonsState();
}

class _ApproveRejectButtonsState extends State<_ApproveRejectButtons> {
  bool _loading = false;

  String? get _pendingUserId {
    try {
      final m = jsonDecode(widget.notif.body) as Map;
      return m['pendingUserId'] as String?;
    } catch (_) { return null; }
  }

  Future<void> _approve() async {
    final uid = _pendingUserId;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      await ApiService.toggleUserStatus(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account approved')));
        widget.onDone();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final uid = _pendingUserId;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      await ApiService.deleteUser(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account rejected')));
        widget.onDone();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 24, width: 24,
        child: CircularProgressIndicator(strokeWidth: 2));
    return Row(children: [
      _ActionBtn(
        label: 'Approve',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF22C55E),
        onTap: _approve,
      ),
      const SizedBox(width: 8),
      _ActionBtn(
        label: 'Reject',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFEF4444),
        onTap: _reject,
      ),
    ]);
  }
}

// ─── Type style helper ────────────────────────────────────────────────────────

class _TypeStyle {
  final IconData icon;
  final Color accent;
  final Color bg;
  const _TypeStyle(this.icon, this.accent, this.bg);
}
