import 'package:flutter/material.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/inventory_section.dart';
import '../widgets/overview_stats.dart';
import '../widgets/recent_activity.dart';
import '../widgets/profile_header.dart';
import '../widgets/inventaire_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            ProfileHeader(
              userName: 'John Doe',
              location: 'ISET Mahdia',
              onProfileTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              onNotificationTap: () {
                // Handle notifications tap
              },
              onSignOut: () {
                // Sign out functionality removed from UI
              },
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search inventory...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Section
                  Text(
                    'Quick actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          title: 'Scan QR',
                          subtitle: 'Barcode & QR support',
                          icon: Icons.qr_code_2,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/qrscanner');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickActionCard(
                          title: 'Add product',
                          subtitle: 'Manual entry',
                          icon: Icons.add,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/addproduct');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ISET Mahdia Section
                  const InventaireCard(),
                  const SizedBox(height: 32),

                  // Department Buttons
                  Text(
                    'Departments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _DepartmentButton(
                        label: 'GI',
                        color: const Color(0xFF3B82F6),
                        onTap: () =>
                            Navigator.pushNamed(context, '/departement_gi'),
                      ),
                      _DepartmentButton(
                        label: 'GE',
                        color: const Color(0xFFF97316),
                        onTap: () =>
                            Navigator.pushNamed(context, '/departement_ge'),
                      ),
                      _DepartmentButton(
                        label: 'TC',
                        color: const Color(0xFF16A34A),
                        onTap: () =>
                            Navigator.pushNamed(context, '/departement_tc'),
                      ),
                      _DepartmentButton(
                        label: 'ADM',
                        color: const Color(0xFFA855F7),
                        onTap: () =>
                            Navigator.pushNamed(context, '/departement_adm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Maps Section
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          title: 'Equipment map',
                          subtitle: '2D locations',
                          icon: Icons.location_on_outlined,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/equipmentmap');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickActionCard(
                          title: '3D map',
                          subtitle: 'Interactive 3D view',
                          icon: Icons.view_in_ar,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/3dmap');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Overview Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      InkWell(
                        onTap: () {},
                        child: Row(
                          children: [
                            Text(
                              'View all',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Color(0xFF3B82F6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const OverviewStats(),
                  const SizedBox(height: 32),

                  // Recent Activity
                  Text(
                    'Recent activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const RecentActivity(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Navigation routing
          switch (index) {
            case 0:
              // Home - already on home
              break;
            case 1:
              // Scan QR
              Navigator.pushNamed(context, '/qrscanner');
              break;
            case 2:
              // ISET
              Navigator.pushNamed(context, '/vueinstitut');
              break;
            case 3:
              // 3D Map
              Navigator.pushNamed(context, '/3dmap');
              break;
            case 4:
              // Add Product
              Navigator.pushNamed(context, '/addproduct');
              break;
            case 5:
              // Profile
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2_outlined),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'ISET',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_in_ar_outlined),
            label: '3D Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DepartmentButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _DepartmentButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
