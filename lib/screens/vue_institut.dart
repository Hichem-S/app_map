import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISET Mahdia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      home: const IsetMahdiaScreen(),
    );
  }
}

// ── Data models ──────────────────────────────────────────────────────────────

class DepartmentData {
  final String code;
  final String name;
  final String description;
  final Color color;
  final int salles;
  final int equipements;
  final int? etudiants;
  final int opCount;
  final int maintCount;
  final int defectCount;
  final String chef;

  const DepartmentData({
    required this.code,
    required this.name,
    required this.description,
    required this.color,
    required this.salles,
    required this.equipements,
    this.etudiants,
    required this.opCount,
    this.maintCount = 0,
    this.defectCount = 0,
    required this.chef,
  });
}

final _departments = [
  const DepartmentData(
    code: 'GI',
    name: 'Génie Informatique',
    description:
        'Computer Engineering — Networks, Software, AI & Database Systems',
    color: Color(0xFF4F46E5),
    salles: 3,
    equipements: 6,
    etudiants: 320,
    opCount: 4,
    maintCount: 1,
    defectCount: 1,
    chef: 'Dr. Karim Mansouri',
  ),
  const DepartmentData(
    code: 'GE',
    name: 'Génie Électrique',
    description:
        'Electrical Engineering — Electronics, Power Systems & Automation',
    color: Color(0xFFF97316),
    salles: 2,
    equipements: 4,
    etudiants: 280,
    opCount: 3,
    defectCount: 1,
    chef: 'Dr. Leila Gharbi',
  ),
  const DepartmentData(
    code: 'TC',
    name: 'Techniques de Commerce',
    description:
        'Business & Commerce Techniques — Marketing, Finance & Logistics',
    color: Color(0xFF059669),
    salles: 2,
    equipements: 3,
    etudiants: 240,
    opCount: 2,
    chef: 'Dr. Youssef Slimi',
  ),
  const DepartmentData(
    code: 'ADM',
    name: 'Administration Générale',
    description: 'General Administration — Direction, Secretary & Library',
    color: Color(0xFF7C3AED),
    salles: 2,
    equipements: 2,
    etudiants: null,
    opCount: 2,
    chef: 'Mohamed Ben Ali',
  ),
];

// ── Main Screen ───────────────────────────────────────────────────────────────

class IsetMahdiaScreen extends StatelessWidget {
  const IsetMahdiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header
            _HeroHeader(),
            // Contact info
            _ContactCard(),
            const SizedBox(height: 20),
            // État du Parc
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ParcSection(),
            ),
            const SizedBox(height: 24),
            // QR Codes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _QrSection(),
            ),
            const SizedBox(height: 24),
            // Départements
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Départements',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E2E)),
              ),
            ),
            const SizedBox(height: 12),
            ..._departments.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DepartmentCard(dept: d),
                )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.qr_code_2, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('QR Institut',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Institute icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.menu_book_outlined,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'ISET Mahdia',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Institut Supérieur des Études Technologiques de Mahdia',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 20),
            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                      icon: Icons.business_outlined,
                      value: '4',
                      label: 'Dépts',
                      iconColor: Colors.white70),
                  _StatChip(
                      icon: Icons.meeting_room_outlined,
                      value: '9',
                      label: 'Salles',
                      iconColor: Colors.white70),
                  _StatChip(
                      icon: Icons.inventory_2_outlined,
                      value: '15',
                      label: 'Équip.',
                      iconColor: Colors.white70),
                  _StatChip(
                      icon: Icons.check_circle_outline,
                      value: '11',
                      label: 'Op.',
                      iconColor: const Color(0xFF6EE7B7)),
                  _StatChip(
                      icon: Icons.warning_amber_outlined,
                      value: '2',
                      label: 'Défect.',
                      iconColor: const Color(0xFFFCD34D)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  const _StatChip(
      {required this.icon,
      required this.value,
      required this.label,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Contact Card ──────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_outlined,
                  size: 16, color: Color(0xFF9090A0)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Route de Hiboun, BP 153 — Mahdia 5100, Tunisie',
                  style: TextStyle(fontSize: 13, color: Color(0xFF444455)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Row(
                children: const [
                  Icon(Icons.phone_outlined,
                      size: 16, color: Color(0xFF9090A0)),
                  SizedBox(width: 8),
                  Text('+216 73 675 100',
                      style: TextStyle(fontSize: 13, color: Color(0xFF444455))),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: const [
                  Icon(Icons.email_outlined,
                      size: 16, color: Color(0xFF9090A0)),
                  SizedBox(width: 8),
                  Text('contact@isetmahdia.rnu.tn',
                      style: TextStyle(fontSize: 12, color: Color(0xFF444455))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── État du Parc ──────────────────────────────────────────────────────────────

class _ParcSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('État du Parc Matériel',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E2E))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _ParcCard(
                    count: '11',
                    label: 'Opérationnel',
                    dotColor: const Color(0xFF22C55E),
                    bg: const Color(0xFFDCFCE7),
                    textColor: const Color(0xFF15803D))),
            const SizedBox(width: 10),
            Expanded(
                child: _ParcCard(
                    count: '1',
                    label: 'Maintenance',
                    dotColor: const Color(0xFFF59E0B),
                    bg: const Color(0xFFFEF9C3),
                    textColor: const Color(0xFFB45309))),
            const SizedBox(width: 10),
            Expanded(
                child: _ParcCard(
                    count: '2',
                    label: 'Défectueux',
                    dotColor: const Color(0xFFEF4444),
                    bg: const Color(0xFFFEE2E2),
                    textColor: const Color(0xFFDC2626))),
            const SizedBox(width: 10),
            Expanded(
                child: _ParcCard(
                    count: '1',
                    label: 'Réformé',
                    dotColor: const Color(0xFF9CA3AF),
                    bg: const Color(0xFFF3F4F6),
                    textColor: const Color(0xFF6B7280))),
          ],
        ),
      ],
    );
  }
}

class _ParcCard extends StatelessWidget {
  final String count;
  final String label;
  final Color dotColor;
  final Color bg;
  final Color textColor;
  const _ParcCard(
      {required this.count,
      required this.label,
      required this.dotColor,
      required this.bg,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(Icons.circle, size: 10, color: dotColor),
          const SizedBox(height: 6),
          Text(count,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: textColor, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── QR Section ────────────────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final qrDepts = [
      _QrItem(
          code: 'GI',
          name: 'Génie Informatique',
          color: const Color(0xFF4F46E5)),
      _QrItem(
          code: 'GE', name: 'Génie Électrique', color: const Color(0xFFF97316)),
      _QrItem(
          code: 'TC',
          name: 'Techniques de Commerce',
          color: const Color(0xFF059669)),
      _QrItem(
          code: 'ADM',
          name: 'Administration Générale',
          color: const Color(0xFF7C3AED)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.qr_code_2, color: Color(0xFF4F46E5), size: 20),
            SizedBox(width: 8),
            Text('QR Codes Départements',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E2E))),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
          children: qrDepts.map((q) => _QrCard(item: q)).toList(),
        ),
      ],
    );
  }
}

class _QrItem {
  final String code;
  final String name;
  final Color color;
  const _QrItem({required this.code, required this.name, required this.color});
}

class _QrCard extends StatelessWidget {
  final _QrItem item;
  const _QrCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Badge
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: item.color, borderRadius: BorderRadius.circular(8)),
              child: Text(item.code,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ),
          const SizedBox(height: 10),
          // QR placeholder
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(
                  painter: _QrPainter(color: item.color),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(item.code,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1E1E2E))),
          Text(item.name,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9090A0)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download_outlined, size: 13, color: item.color),
              const SizedBox(width: 4),
              Text('Télécharger QR',
                  style: TextStyle(
                      fontSize: 11,
                      color: item.color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final Color color;
  const _QrPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = color.withOpacity(0.12);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cellSize = size.width / 22;
    final rounding = Radius.circular(cellSize * 0.35);

    // Background grid for a smoother QR style.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      background,
    );

    final rng = math.Random(color.value);
    for (int row = 0; row < 21; row++) {
      for (int col = 0; col < 21; col++) {
        final offset = Offset(col * cellSize + 1.5, row * cellSize + 1.5);
        final rect =
            Rect.fromLTWH(offset.dx, offset.dy, cellSize - 3, cellSize - 3);

        bool isFinder = _isFinderPattern(row, col);
        bool draw = isFinder || rng.nextInt(100) < 34;
        if (draw) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, rounding), paint);
        }
      }
    }
  }

  bool _isFinderPattern(int row, int col) {
    // Top-left
    if (row < 7 && col < 7) return _finderCell(row, col);
    // Top-right
    if (row < 7 && col >= 14) return _finderCell(row, col - 14);
    // Bottom-left
    if (row >= 14 && col < 7) return _finderCell(row - 14, col);
    return false;
  }

  bool _finderCell(int r, int c) {
    if (r == 0 || r == 6 || c == 0 || c == 6) return true;
    if (r >= 2 && r <= 4 && c >= 2 && c <= 4) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Department Card ───────────────────────────────────────────────────────────

class _DepartmentCard extends StatelessWidget {
  final DepartmentData dept;
  const _DepartmentCard({required this.dept});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        String route;
        switch (dept.code) {
          case 'GI':
            route = '/departement_gi';
            break;
          case 'GE':
            route = '/departement_ge';
            break;
          case 'TC':
            route = '/departement_tc';
            break;
          case 'ADM':
            route = '/departement_adm';
            break;
          default:
            return;
        }
        Navigator.pushNamed(context, route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [dept.color, dept.color.withOpacity(0.75)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dept.code,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(dept.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.business_outlined,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dept.description,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 14),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                            child: _StatBox(
                                value: '${dept.salles}', label: 'Salles')),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _StatBox(
                                value: '${dept.equipements}',
                                label: 'Équipements')),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            value: dept.etudiants != null
                                ? '${dept.etudiants}'
                                : '—',
                            label: dept.etudiants != null ? 'Étudiants' : 'Pers.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (dept.opCount > 0)
                          _StatusBadge(
                            icon: Icons.check_circle_outline,
                            label: '${dept.opCount} Op.',
                            color: const Color(0xFF16A34A),
                            bg: const Color(0xFFDCFCE7),
                          ),
                        if (dept.maintCount > 0)
                          _StatusBadge(
                            icon: Icons.build_outlined,
                            label: '${dept.maintCount} Maint.',
                            color: const Color(0xFFD97706),
                            bg: const Color(0xFFFEF9C3),
                          ),
                        if (dept.defectCount > 0)
                          _StatusBadge(
                            icon: Icons.warning_amber_outlined,
                            label: '${dept.defectCount} Défect.',
                            color: const Color(0xFFDC2626),
                            bg: const Color(0xFFFEE2E2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chef row
              Container(
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF0F0F5)))),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text('Chef: ${dept.chef}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF444455),
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: Color(0xFF9090A0), size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1E1E2E))),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9090A0))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _StatusBadge(
      {required this.icon,
      required this.label,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
