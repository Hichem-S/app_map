import 'package:flutter/material.dart';

class RecentActivity extends StatelessWidget {
  const RecentActivity({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const List<ActivityItem> activities = [
      ActivityItem(
        title: 'Added Wireless Mouse',
        time: '2h ago',
        icon: Icons.add_circle_outline,
        color: Color(0xFF3B82F6),
      ),
      ActivityItem(
        title: 'Scanned Laptop Stand',
        time: '5h ago',
        icon: Icons.qr_code_2,
        color: Color(0xFF3B82F6),
      ),
      ActivityItem(
        title: 'Updated USB-C Cable',
        time: '1d ago',
        icon: Icons.inventory_2_outlined,
        color: Color(0xFF3B82F6),
      ),
      ActivityItem(
        title: 'Ordered Monitor 27"',
        time: '2d ago',
        icon: Icons.shopping_cart_outlined,
        color: Color(0xFF3B82F6),
      ),
    ];

    return Column(
      children: List.generate(
        activities.length,
        (index) {
          final activity = activities[index];
          return Padding(
            padding:
                EdgeInsets.only(bottom: index < activities.length - 1 ? 12 : 0),
            child: _ActivityTile(activity: activity),
          );
        },
      ),
    );
  }
}

class ActivityItem {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const ActivityItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          // Arrow
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.outline,
            size: 20,
          ),
        ],
      ),
    );
  }
}
