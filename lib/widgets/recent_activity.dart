import 'package:flutter/material.dart';

class RecentActivity extends StatelessWidget {
  final List<Activity> activities;

  const RecentActivity({
    Key? key,
    this.activities = const [
      Activity(
        id: '1',
        action: 'Product Added',
        description: 'Dell Monitor 27" added to GI Department',
        timestamp: '2 hours ago',
        type: ActivityType.added,
        icon: Icons.add_circle_outlined,
      ),
      Activity(
        id: '2',
        action: 'Low Stock Alert',
        description: 'USB-C Cable stock level below threshold',
        timestamp: '4 hours ago',
        type: ActivityType.alert,
        icon: Icons.warning_outlined,
      ),
      Activity(
        id: '3',
        action: 'Product Updated',
        description: 'Wireless Mouse quantity updated to 45 units',
        timestamp: '6 hours ago',
        type: ActivityType.updated,
        icon: Icons.edit_outlined,
      ),
      Activity(
        id: '4',
        action: 'Product Removed',
        description: 'Old keyboard removed from inventory',
        timestamp: '1 day ago',
        type: ActivityType.removed,
        icon: Icons.delete_outline,
      ),
    ],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: activities.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isLast = index == activities.length - 1;

        return _ActivityItem(
          activity: activity,
          isLast: isLast,
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Activity activity;
  final bool isLast;

  const _ActivityItem({
    required this.activity,
    required this.isLast,
  });

  Color _getActivityColor() {
    switch (activity.type) {
      case ActivityType.added:
        return const Color(0xFF16A34A);
      case ActivityType.alert:
        return const Color(0xFFF97316);
      case ActivityType.updated:
        return const Color(0xFF3B82F6);
      case ActivityType.removed:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getActivityColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity.icon,
                    color: _getActivityColor(),
                    size: 18,
                  ),
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
            // Activity content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.action,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activity.timestamp,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.5),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum ActivityType {
  added,
  alert,
  updated,
  removed,
}

class Activity {
  final String id;
  final String action;
  final String description;
  final String timestamp;
  final ActivityType type;
  final IconData icon;

  const Activity({
    required this.id,
    required this.action,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.icon,
  });
}
