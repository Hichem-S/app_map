import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner Hiérarchique',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A2340)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const ScannerHierarchique(),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────────────────────────

enum HierarchyLevel { iset, dept, salle, equip }

class QuickScanItem {
  final String label;
  final String icon;
  final HierarchyLevel level;
  final Color color;

  const QuickScanItem({
    required this.label,
    required this.icon,
    required this.level,
    required this.color,
  });
}

class QRTypeInfo {
  final String title;
  final String subtitle;
  final String emoji;
  final Color backgroundColor;

  const QRTypeInfo({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.backgroundColor,
  });
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class ScannerHierarchique extends StatefulWidget {
  const ScannerHierarchique({super.key});

  @override
  State<ScannerHierarchique> createState() => _ScannerHierarchiqueState();
}

class _ScannerHierarchiqueState extends State<ScannerHierarchique>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  HierarchyLevel _activeLevel = HierarchyLevel.iset;
  late AnimationController _scannerPulseController;
  late Animation<double> _scannerPulseAnim;

  // Colors
  static const Color _darkBg = Color(0xFF1A2340);
  static const Color _isetColor = Color(0xFF3B82F6);
  static const Color _deptColor = Color(0xFF6366F1);
  static const Color _salleColor = Color(0xFF10B981);
  static const Color _equipColor = Color(0xFFF97316);
  static const Color _scannerBlue = Color(0xFF3B82F6);

  final List<QuickScanItem> _quickScans = const [
    QuickScanItem(
        label: 'ISET',
        icon: '🏫',
        level: HierarchyLevel.iset,
        color: _isetColor),
    QuickScanItem(
        label: 'GI', icon: '🏢', level: HierarchyLevel.dept, color: _deptColor),
    QuickScanItem(
        label: 'GE', icon: '🏢', level: HierarchyLevel.dept, color: _deptColor),
    QuickScanItem(
        label: 'TC', icon: '🏢', level: HierarchyLevel.dept, color: _deptColor),
    QuickScanItem(
        label: 'ADM',
        icon: '🏢',
        level: HierarchyLevel.dept,
        color: _deptColor),
    QuickScanItem(
        label: 'A101',
        icon: '🚪',
        level: HierarchyLevel.salle,
        color: _salleColor),
    QuickScanItem(
        label: 'B102',
        icon: '🚪',
        level: HierarchyLevel.salle,
        color: _salleColor),
    QuickScanItem(
        label: 'LAB1',
        icon: '🔬',
        level: HierarchyLevel.equip,
        color: _equipColor),
  ];

  final List<QRTypeInfo> _qrTypes = const [
    QRTypeInfo(
      title: 'QR ISET',
      subtitle: 'Shows all departments',
      emoji: '🏫',
      backgroundColor: Color(0xFFEFF6FF),
    ),
    QRTypeInfo(
      title: 'QR Département',
      subtitle: 'Lists rooms and equipment',
      emoji: '🏢',
      backgroundColor: Color(0xFFF5F3FF),
    ),
    QRTypeInfo(
      title: 'QR Salle',
      subtitle: 'Inventaire complet de la salle',
      emoji: '🚪',
      backgroundColor: Color(0xFFECFDF5),
    ),
    QRTypeInfo(
      title: 'QR Équipement',
      subtitle: 'Fiche + journal de traçabilité',
      emoji: '📦',
      backgroundColor: Color(0xFFFFF7ED),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scannerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scannerPulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scannerPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerPulseController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Color _levelColor(HierarchyLevel level) {
    switch (level) {
      case HierarchyLevel.iset:
        return _isetColor;
      case HierarchyLevel.dept:
        return _deptColor;
      case HierarchyLevel.salle:
        return _salleColor;
      case HierarchyLevel.equip:
        return _equipColor;
    }
  }

  String _levelLabel(HierarchyLevel level) {
    switch (level) {
      case HierarchyLevel.iset:
        return 'ISET';
      case HierarchyLevel.dept:
        return 'Dépt.';
      case HierarchyLevel.salle:
        return 'Salle';
      case HierarchyLevel.equip:
        return 'Équip.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  _buildQuickScanSection(),
                  const SizedBox(height: 24),
                  _buildScannerWidget(),
                  const SizedBox(height: 24),
                  _buildQRTypesList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2340), Color(0xFF243058)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Top row
              Row(
                children: [
                  _headerIconButton(
                    Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Scanner Hiérarchique',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ISET · Dépt. · Salle · Équipement',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _headerIconButton(Icons.history_rounded),
                ],
              ),
              const SizedBox(height: 16),
              // Breadcrumb
              _buildBreadcrumb(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, {VoidCallback? onTap}) {
    final button = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: button) : button;
  }

  Widget _buildBreadcrumb() {
    final levels = HierarchyLevel.values;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(levels.length * 2 - 1, (i) {
        if (i.isOdd) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white38, size: 10),
          );
        }
        final level = levels[i ~/ 2];
        final isActive = level == _activeLevel;
        return GestureDetector(
          onTap: () => setState(() => _activeLevel = level),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? _levelColor(level)
                  : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _levelLabel(level),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Text('#',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w300)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Paste JSON payload or QR ID...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _scannerBlue,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _scannerBlue.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Scanner',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Scan ───────────────────────────────────────────────────────────

  Widget _buildQuickScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            'SCAN RAPIDE (DÉMO)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.black54,
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _quickScans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final item = _quickScans[i];
              return _QuickScanChip(item: item);
            },
          ),
        ),
      ],
    );
  }

  // ─── Scanner Widget ───────────────────────────────────────────────────────

  Widget _buildScannerWidget() {
    return Column(
      children: [
        ScaleTransition(
          scale: _scannerPulseAnim,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(52, 52),
                painter: _QRCornersPainter(color: _scannerBlue),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scanner un QR Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2340),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Use the quick scan buttons or enter a JSON payload to navigate the ISET hierarchy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black45,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ─── QR Types List ────────────────────────────────────────────────────────

  Widget _buildQRTypesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _qrTypes.map((info) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _QRTypeCard(info: info),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Quick Scan Chip ──────────────────────────────────────────────────────────

class _QuickScanChip extends StatelessWidget {
  final QuickScanItem item;
  const _QuickScanChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── QR Type Card ─────────────────────────────────────────────────────────────

class _QRTypeCard extends StatelessWidget {
  final QRTypeInfo info;
  const _QRTypeCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: info.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(info.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.black26),
        ],
      ),
    );
  }
}

// ─── QR Corners Painter ───────────────────────────────────────────────────────

class _QRCornersPainter extends CustomPainter {
  final Color color;
  const _QRCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const cornerLen = 14.0;
    const r = 4.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawPath(
        Path()
          ..moveTo(0, r + cornerLen)
          ..lineTo(0, r)
          ..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))
          ..lineTo(r + cornerLen, 0),
        paint);
    // Top-right
    canvas.drawPath(
        Path()
          ..moveTo(w - r - cornerLen, 0)
          ..lineTo(w - r, 0)
          ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
          ..lineTo(w, r + cornerLen),
        paint);
    // Bottom-right
    canvas.drawPath(
        Path()
          ..moveTo(w, h - r - cornerLen)
          ..lineTo(w, h - r)
          ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
          ..lineTo(w - r - cornerLen, h),
        paint);
    // Bottom-left
    canvas.drawPath(
        Path()
          ..moveTo(r + cornerLen, h)
          ..lineTo(r, h)
          ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
          ..lineTo(0, h - r - cornerLen),
        paint);
  }

  @override
  bool shouldRepaint(_QRCornersPainter old) => old.color != color;
}
