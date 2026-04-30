import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecentActivity extends StatefulWidget {
  const RecentActivity({Key? key}) : super(key: key);

  @override
  State<RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<RecentActivity> {
  List<_ActivityItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = await ApiService.getScanHistory();
      if (!mounted) return;
      setState(() {
        _items = history.take(5).map((e) {
          final item = e as Map<String, dynamic>;
          final scannedAt = DateTime.tryParse(item['scanned_at'] ?? '');
          return _ActivityItem(
            icon: Icons.qr_code_scanner,
            color: const Color(0xFF3B82F6),
            action: 'QR Scanned',
            description: item['name'] ?? '—',
            subtitle: item['category_name'] ?? item['sku'] ?? '',
            timestamp: scannedAt != null ? _timeAgo(scannedAt) : '',
          );
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No recent activity',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _items.length; i++)
          _ActivityRow(item: _items[i], isLast: i == _items.length - 1),
      ],
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String action;
  final String description;
  final String subtitle;
  final String timestamp;

  _ActivityItem({
    required this.icon,
    required this.color,
    required this.action,
    required this.description,
    required this.subtitle,
    required this.timestamp,
  });
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;
  final bool isLast;

  const _ActivityRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Theme.of(context).colorScheme.outline,
                margin: const EdgeInsets.only(top: 8),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.action,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.6),
                        ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  item.timestamp,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
