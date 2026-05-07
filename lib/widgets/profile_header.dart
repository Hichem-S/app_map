import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String? userName;
  final String? location;
  final String? avatarUrl;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSignOut;
  final int notificationCount;

  const ProfileHeader({
    Key? key,
    this.userName = 'John Doe',
    this.location = 'ISET Mahdia',
    this.avatarUrl,
    this.onProfileTap,
    this.onNotificationTap,
    this.onSignOut,
    this.notificationCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Section - Profile Avatar and Info
              Row(
                children: [
                  // Avatar
                  Tooltip(
                    message: 'View Profile',
                    child: GestureDetector(
                      onTap: onProfileTap ?? () {},
                      child: Hero(
                        tag: 'profile-avatar',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: avatarUrl != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(avatarUrl!),
                                )
                              : Center(
                                  child: Text(
                                    userName?.substring(0, 1).toUpperCase() ??
                                        'J',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Profile Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Inventory',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location ?? 'ISET Mahdia',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.6),
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                ],
              ),

              // Right Section - Notifications
              Row(
                children: [
                  // Notifications Icon Button
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onNotificationTap ?? () {},
                            borderRadius: BorderRadius.circular(20),
                            child: Icon(
                              notificationCount > 0
                                  ? Icons.notifications_rounded
                                  : Icons.notifications_outlined,
                              color: notificationCount > 0
                                  ? const Color(0xFF3B5BDB)
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      // Notification Badge with count
                      if (notificationCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0xFFEF4444),
                                    blurRadius: 4,
                                    spreadRadius: 0),
                              ],
                            ),
                            child: Text(
                              notificationCount > 99
                                  ? '99+'
                                  : '$notificationCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
