import 'package:flutter/material.dart';

class OverviewStats extends StatelessWidget {
  const OverviewStats({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatCard(
          title: 'Total items',
          value: '1,234',
          badge: '+12%',
          badgeColor: const Color(0xFFDBEAFE),
          badgeTextColor: const Color(0xFF0284C7),
          iconColor: const Color(0xFF3B82F6),
          iconBgColor: const Color(0xFFDBEAFE),
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'Low stock',
          value: '23',
          badge: 'Urgent',
          badgeColor: const Color(0xFFFED7AA),
          badgeTextColor: const Color(0xFFC2410C),
          iconColor: const Color(0xFFF97316),
          iconBgColor: const Color(0xFFFED7AA),
          icon: Icons.warning_outlined,
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'Categories',
          value: '8',
          badge: 'Active',
          badgeColor: const Color(0xFFDCFCE7),
          badgeTextColor: const Color(0xFF166534),
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFDCFCE7),
          icon: Icons.category_outlined,
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
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Content
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
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 12,
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
