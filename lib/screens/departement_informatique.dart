import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GI Department',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B5BDB)),
        useMaterial3: true,
      ),
      home: const DepartementGIScreen(),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

enum RoomType { laboratoire, bureau, salle }

enum EquipStatus { operationnel, maintenance, defectueux, reforme, reserve }

class RoomItem {
  final String id;
  final String name;
  final String bloc;
  final int etage;
  final int equipCount;
  final RoomType type;
  final Map<EquipStatus, int> equipStats;
  final int capacity;

  const RoomItem({
    required this.id,
    required this.name,
    required this.bloc,
    required this.etage,
    required this.equipCount,
    required this.type,
    required this.equipStats,
    required this.capacity,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class DepartementGIScreen extends StatelessWidget {
  const DepartementGIScreen({super.key});

  static const Color _headerBlue = Color(0xFF3B5BDB);
  static const Color _headerBlueDark = Color(0xFF2F4AC0);

  final List<RoomItem> rooms = const [
    RoomItem(
      id: 'A101',
      name: 'Lab Informatique 1',
      bloc: 'Bloc A',
      etage: 1,
      equipCount: 3,
      type: RoomType.laboratoire,
      equipStats: {
        EquipStatus.operationnel: 2,
        EquipStatus.defectueux: 1,
      },
      capacity: 30,
    ),
    RoomItem(
      id: 'A102',
      name: 'Lab Réseaux & Sécurité',
      bloc: 'Bloc A',
      etage: 1,
      equipCount: 2,
      type: RoomType.laboratoire,
      equipStats: {
        EquipStatus.operationnel: 2,
      },
      capacity: 20,
    ),
    RoomItem(
      id: 'A201',
      name: 'GI Department Office',
      bloc: 'Bloc A',
      etage: 2,
      equipCount: 1,
      type: RoomType.bureau,
      equipStats: {
        EquipStatus.reserve: 1,
      },
      capacity: 8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_headerBlue, _headerBlueDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  _iconBtn(Icons.arrow_back_ios_new_rounded, () {
                    Navigator.pop(context);
                  }),
                  const Spacer(),
                  _qrDeptButton(),
                ],
              ),
              const SizedBox(height: 16),
              // Dept info
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('GI',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Génie Informatique',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'هندسة المعلوماتية',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats row
              Row(
                children: [
                  _statCard('3', 'Salles'),
                  const SizedBox(width: 8),
                  _statCard('6', 'Équip.'),
                  const SizedBox(width: 8),
                  _statCard('320', 'Étud.'),
                  const SizedBox(width: 8),
                  _statCard('18', 'Ens.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _qrDeptButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: const Row(
        children: [
          Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text('QR Dépt.',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ─── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildEtatMateriel(),
          const SizedBox(height: 24),
          _buildSallesSection(),
          const SizedBox(height: 24),
          _buildResponsable(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── État du Matériel ────────────────────────────────────────────────────

  Widget _buildEtatMateriel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ÉTAT DU MATÉRIEL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statusCard(
                value: '4',
                label: 'Op.',
                dotColor: const Color(0xFF22C55E),
                bg: const Color(0xFFDCFCE7),
                valueColor: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statusCard(
                value: '1',
                label: 'Maint.',
                dotColor: const Color(0xFFF59E0B),
                bg: const Color(0xFFFEF9C3),
                valueColor: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statusCard(
                value: '1',
                label: 'Défect.',
                dotColor: const Color(0xFFEF4444),
                bg: const Color(0xFFFFE4E4),
                valueColor: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statusCard(
                value: '0',
                label: 'Réformé',
                dotColor: Colors.grey,
                bg: const Color(0xFFF3F4F6),
                valueColor: Colors.black87,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statusCard(
                value: '0',
                label: 'Réservé',
                dotColor: const Color(0xFF3B82F6),
                bg: const Color(0xFFDBEAFE),
                valueColor: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusCard({
    required String value,
    required String label,
    required Color dotColor,
    required Color bg,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Salles ───────────────────────────────────────────────────────────────

  Widget _buildSallesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Department Rooms',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2340)),
            ),
            Text(
              '${rooms.length} salle(s)',
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...rooms.map((room) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RoomCard(room: room),
            )),
      ],
    );
  }

  // ─── Responsable ─────────────────────────────────────────────────────────

  Widget _buildResponsable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Department Head',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B5BDB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'TJ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarek Jellad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2340),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Department Head — GI',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Room Card ────────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  final RoomItem room;
  const _RoomCard({required this.room});

  String get _typeLabel {
    switch (room.type) {
      case RoomType.laboratoire:
        return 'Laboratoire';
      case RoomType.bureau:
        return 'Bureau';
      case RoomType.salle:
        return 'Salle';
    }
  }

  IconData get _typeIcon {
    switch (room.type) {
      case RoomType.laboratoire:
        return Icons.science_outlined;
      case RoomType.bureau:
        return Icons.work_outline_rounded;
      case RoomType.salle:
        return Icons.door_front_door_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // QR placeholder
          Container(
            width: 90,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  size: const Size(56, 56),
                  painter: _FakeQRPainter(),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_rounded,
                        size: 12, color: Color(0xFF3B5BDB)),
                    const SizedBox(width: 3),
                    const Text('QR',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF3B5BDB),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_typeIcon, size: 13, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(_typeLabel,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(room.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2340))),
                  const SizedBox(height: 2),
                  Text(
                    '${room.id} · ${room.bloc} · Étage ${room.etage}',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${room.equipCount} équip.',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      const SizedBox(width: 8),
                      ..._buildEquipBadges(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded,
                          size: 13, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text('Capacité: ${room.capacity} pers.',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Colors.black26),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEquipBadges() {
    return room.equipStats.entries.map((e) {
      final color = _statusColor(e.key);
      final icon = _statusIcon(e.key);
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 2),
            Text('${e.value}',
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }).toList();
  }

  Color _statusColor(EquipStatus s) {
    switch (s) {
      case EquipStatus.operationnel:
        return const Color(0xFF22C55E);
      case EquipStatus.maintenance:
        return const Color(0xFFF59E0B);
      case EquipStatus.defectueux:
        return const Color(0xFFEF4444);
      case EquipStatus.reforme:
        return Colors.grey;
      case EquipStatus.reserve:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _statusIcon(EquipStatus s) {
    switch (s) {
      case EquipStatus.operationnel:
        return Icons.check_circle_outline_rounded;
      case EquipStatus.maintenance:
        return Icons.build_outlined;
      case EquipStatus.defectueux:
        return Icons.warning_amber_rounded;
      case EquipStatus.reforme:
        return Icons.remove_circle_outline;
      case EquipStatus.reserve:
        return Icons.key_outlined;
    }
  }
}

// ─── Fake QR Painter ─────────────────────────────────────────────────────────

class _FakeQRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2340)
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 7;

    // Draw a simple fake QR pattern
    final pattern = [
      [1, 1, 1, 1, 1, 1, 1],
      [1, 0, 0, 0, 0, 0, 1],
      [1, 0, 1, 0, 1, 0, 1],
      [1, 0, 0, 1, 0, 0, 1],
      [1, 0, 1, 0, 1, 0, 1],
      [1, 0, 0, 0, 0, 0, 1],
      [1, 1, 1, 1, 1, 1, 1],
    ];

    for (int row = 0; row < 7; row++) {
      for (int col = 0; col < 7; col++) {
        if (pattern[row][col] == 1) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                col * cellSize + 1,
                row * cellSize + 1,
                cellSize - 2,
                cellSize - 2,
              ),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_FakeQRPainter old) => false;
}
