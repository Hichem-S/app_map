import 'package:flutter/material.dart';

void main() {
  runApp(const EquipmentMapApp());
}

class EquipmentMapApp extends StatelessWidget {
  const EquipmentMapApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equipment Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const EquipmentMapScreen(),
    );
  }
}

class Equipment {
  final String id;
  final String name;
  final String type;
  final Offset position; // Position on the map (0-1 range for simplicity)
  final Color color;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.color,
  });
}

class EquipmentMapScreen extends StatefulWidget {
  const EquipmentMapScreen({Key? key}) : super(key: key);

  @override
  State<EquipmentMapScreen> createState() => _EquipmentMapScreenState();
}

class _EquipmentMapScreenState extends State<EquipmentMapScreen> {
  String selectedType = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<Equipment> allEquipment = [
    Equipment(
      id: '1',
      name: 'Laptop',
      type: 'Computer',
      position: const Offset(0.25, 0.3),
      color: const Color(0xFFEF4444),
    ),
    Equipment(
      id: '2',
      name: 'Server Rack',
      type: 'Server',
      position: const Offset(0.55, 0.25),
      color: const Color(0xFF10B981),
    ),
    Equipment(
      id: '3',
      name: 'Monitor',
      type: 'Display',
      position: const Offset(0.85, 0.28),
      color: const Color(0xFFFA8500),
    ),
    Equipment(
      id: '4',
      name: 'Network Switch',
      type: 'Network Device',
      position: const Offset(0.35, 0.5),
      color: const Color(0xFF3B82F6),
    ),
    Equipment(
      id: '5',
      name: 'Printer',
      type: 'Printer/Scanner',
      position: const Offset(0.65, 0.55),
      color: const Color(0xFF8B5CF6),
    ),
    Equipment(
      id: '6',
      name: 'Projector',
      type: 'Projector',
      position: const Offset(0.45, 0.65),
      color: const Color(0xFFF59E0B),
    ),
  ];

  late List<Equipment> filteredEquipment;

  @override
  void initState() {
    super.initState();
    _filterEquipment();
  }

  void _filterEquipment() {
    setState(() {
      if (selectedType == 'All') {
        filteredEquipment = allEquipment;
      } else {
        filteredEquipment =
            allEquipment.where((e) => e.type == selectedType).toList();
      }
    });
  }

  void _showEquipmentDetails(Equipment equipment) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: equipment.color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equipment.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          equipment.type,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Position: ${(equipment.position.dx * 100).toStringAsFixed(0)}%, ${(equipment.position.dy * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equipment Map',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              '${filteredEquipment.length} items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background map area
          Container(
            color: Colors.grey[100],
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                // Search bar and filters section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search equipment or location...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(Icons.search),
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Type filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final t in ['All', 'Computer', 'Server', 'Network Device', 'Peripheral', 'Printer/Scanner', 'Display', 'Projector', 'Machine Tool']) ...[
                              _CategoryChip(
                                label: t,
                                isSelected: selectedType == t,
                                onTap: () => setState(() {
                                  selectedType = t;
                                  _filterEquipment();
                                }),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Map area with equipment markers
                Expanded(
                  child: Stack(
                    children: [
                      // Map background
                      Container(
                        color: Colors.grey[200],
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      // Equipment markers
                      ...filteredEquipment.map((equipment) {
                        return Positioned(
                          left: equipment.position.dx *
                              (MediaQuery.of(context).size.width - 100),
                          top: equipment.position.dy *
                              (MediaQuery.of(context).size.height - 300),
                          child: GestureDetector(
                            onTap: () => _showEquipmentDetails(equipment),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: equipment.color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: equipment.color.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right side control buttons
          Positioned(
            right: 12,
            top: 100,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.layers,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Layers button tapped')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.near_me,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location button tapped')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.fullscreen,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fullscreen button tapped')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.grey[700],
          size: 20,
        ),
      ),
    );
  }
}
