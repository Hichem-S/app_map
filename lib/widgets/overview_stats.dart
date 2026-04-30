import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OverviewStats extends StatefulWidget {
  const OverviewStats({Key? key}) : super(key: key);

  @override
  State<OverviewStats> createState() => _OverviewStatsState();
}

class _OverviewStatsState extends State<OverviewStats> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await ApiService.getStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final s = _stats;
    final total      = s?['total_products'] ?? 0;
    final lowStock   = s?['low_stock'] ?? 0;
    final outOfStock = s?['out_of_stock'] ?? 0;
    final categories = s?['categories_used'] ?? 0;
    final scans      = s?['total_scans'] ?? 0;
    final value      = (s?['total_value'] ?? 0.0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Items',
                value: total.toString(),
                badge: total > 0 ? 'Active' : 'Empty',
                badgeColor: const Color(0xFFDBEAFE),
                badgeTextColor: const Color(0xFF0284C7),
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFDBEAFE),
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Low Stock',
                value: lowStock.toString(),
                badge: outOfStock > 0 ? '$outOfStock out' : 'OK',
                badgeColor: lowStock > 0 ? const Color(0xFFFED7AA) : const Color(0xFFDCFCE7),
                badgeTextColor: lowStock > 0 ? const Color(0xFFC2410C) : const Color(0xFF166534),
                iconColor: lowStock > 0 ? const Color(0xFFF97316) : const Color(0xFF16A34A),
                iconBgColor: lowStock > 0 ? const Color(0xFFFED7AA) : const Color(0xFFDCFCE7),
                icon: lowStock > 0 ? Icons.warning_outlined : Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Types',
                value: categories.toString(),
                badge: 'Used',
                badgeColor: const Color(0xFFDCFCE7),
                badgeTextColor: const Color(0xFF166534),
                iconColor: const Color(0xFF16A34A),
                iconBgColor: const Color(0xFFDCFCE7),
                icon: Icons.category_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'QR Scans',
                value: scans.toString(),
                badge: 'Total',
                badgeColor: const Color(0xFFEDE9FE),
                badgeTextColor: const Color(0xFF7C3AED),
                iconColor: const Color(0xFF7C3AED),
                iconBgColor: const Color(0xFFEDE9FE),
                icon: Icons.qr_code_scanner,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'Total Inventory Value',
          value: '${value.toStringAsFixed(2)} TND',
          badge: 'Estimated',
          badgeColor: const Color(0xFFFEF9C3),
          badgeTextColor: const Color(0xFF854D0E),
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFEF9C3),
          icon: Icons.payments_outlined,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;
  final Color iconColor;
  final Color iconBgColor;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
