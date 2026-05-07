import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/app_notification.dart';

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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    final notifs = NotificationService.instance.all;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
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

  @override
  Widget build(BuildContext context) {
    final isRead = notif.isRead;

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
            color: isRead ? Colors.white : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(16),
            border: isRead
                ? Border.all(color: Colors.transparent)
                : Border.all(color: const Color(0xFF3B5BDB).withOpacity(0.2)),
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
                  color: const Color(0xFF3B5BDB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: Color(0xFF3B5BDB), size: 22),
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
                        const Icon(Icons.meeting_room_rounded,
                            size: 12, color: Color(0xFF3B5BDB)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(notif.toRoom ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B5BDB))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (!isRead)
                Container(
                  margin: const EdgeInsets.only(top: 4, left: 6),
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF3B5BDB), shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
