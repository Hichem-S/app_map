import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/department.dart';
import '../utils/download_helper.dart';
import 'dept_rooms_screen.dart';

// ── Design tokens matching the rest of the app ────────────────────────────────
const _accent  = Color(0xFF4A7CFC);
const _accent2 = Color(0xFF6B5BFD);
const _bg      = Color(0xFFF5F6FA);
const _dark    = Color(0xFF1A1D2E);
const _muted   = Color(0xFFB0B7C3);
const _white   = Colors.white;

class IsetMahdiaScreen extends StatefulWidget {
  const IsetMahdiaScreen({Key? key}) : super(key: key);

  @override
  State<IsetMahdiaScreen> createState() => _IsetMahdiaScreenState();
}

class _IsetMahdiaScreenState extends State<IsetMahdiaScreen> {
  List<Department> _departments = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final depts = await ApiService.getDepartments();
      final stats = await ApiService.getStats();
      if (!mounted) return;
      setState(() {
        _departments = depts
            .map((d) => Department.fromJson(d as Map<String, dynamic>))
            .toList();
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalRooms => _departments.fold(0, (s, d) => s + d.roomCount);
  int get _totalItems => _departments.fold(0, (s, d) => s + d.productCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: _accent,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HeroHeader(
                      totalDepts: _departments.length,
                      totalRooms: _totalRooms,
                      totalItems: _totalItems,
                      inStock:       (_stats?['status_in_stock']       as num?)?.toInt() ?? 0,
                      inMaintenance: (_stats?['status_in_maintenance'] as num?)?.toInt() ?? 0,
                      critical:      (_stats?['status_critical_issue'] as num?)?.toInt() ?? 0,
                      onQrTap: () => _showIsetQR(context),
                    ),
                  ),
                  SliverToBoxAdapter(child: _ContactCard()),
                  if (_stats != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: _ParcSection(stats: _stats!),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _QrSection(departments: _departments)),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _SectionHeader(
                        icon: Icons.business_outlined,
                        title: 'Departments',
                        count: _departments.length,
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _DepartmentCard(
                          dept: _departments[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DeptRoomsScreen(department: _departments[i])),
                          ),
                        ),
                      ),
                      childCount: _departments.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  Future<void> _downloadQr(String url, String filename) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final savedPath = await downloadFileLocally(res.bodyBytes, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $savedPath'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showIsetQR(BuildContext context) {
    final url = ApiService.isetQrUrl();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ISET Mahdia QR Code',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
        content: SizedBox(
          width: 240,
          height: 240,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, p) =>
                p == null ? child : const Center(child: CircularProgressIndicator(color: _accent)),
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.error_outline, color: Color(0xFFEF4444))),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _downloadQr(url, 'iset_qr.png'),
            icon: const Icon(Icons.download_rounded, size: 16, color: _accent),
            label: const Text('Download', style: TextStyle(color: _accent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _muted)),
          ),
        ],
      ),
    );
  }
}

// ── Shared section header ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  const _SectionHeader({required this.icon, required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: _accent, size: 17),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: _dark)),
      if (count != null) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _accent)),
        ),
      ],
    ]);
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final int totalDepts, totalRooms, totalItems, inStock, inMaintenance, critical;
  final VoidCallback onQrTap;

  const _HeroHeader({
    required this.totalDepts,
    required this.totalRooms,
    required this.totalItems,
    required this.inStock,
    required this.inMaintenance,
    required this.critical,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, _accent2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x404A7CFC), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: _white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back, color: _white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onQrTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _white.withOpacity(0.4)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.qr_code_2, color: _white, size: 18),
                        SizedBox(width: 6),
                        Text('ISET QR',
                            style: TextStyle(
                                color: _white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            // Icon + title
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _white.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(Icons.apartment_rounded, color: _white, size: 36),
            ),
            const SizedBox(height: 12),
            const Text('ISET Mahdia',
                style: TextStyle(
                    color: _white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Higher Institute of Technological Studies',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _white.withOpacity(0.75), fontSize: 12)),
            const SizedBox(height: 20),
            // Stat chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(icon: Icons.business_outlined,     value: '$totalDepts',    label: 'Depts'),
                  _StatChip(icon: Icons.meeting_room_outlined, value: '$totalRooms',    label: 'Rooms'),
                  _StatChip(icon: Icons.inventory_2_outlined,  value: '$totalItems',    label: 'Items'),
                  _StatChip(icon: Icons.check_circle_outline,  value: '$inStock',       label: 'Active',
                      valueColor: const Color(0xFF86EFAC)),
                  _StatChip(icon: Icons.warning_amber_outlined, value: '$critical',     label: 'Critical',
                      valueColor: const Color(0xFFFCD34D)),
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
  final String value, label;
  final Color? valueColor;
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _white.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: _white.withOpacity(0.8), size: 17),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: valueColor ?? _white,
                fontWeight: FontWeight.w800,
                fontSize: 15)),
        Text(label,
            style: TextStyle(color: _white.withOpacity(0.7), fontSize: 10)),
      ]),
    );
  }
}

// ── Contact Card ──────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.location_on_outlined, size: 16, color: _accent),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Route de Hiboun, BP 153 — Mahdia 5100, Tunisia',
                style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF22C55E)),
          ),
          const SizedBox(width: 10),
          const Text('+216 73 675 100',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
          const Spacer(),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.email_outlined, size: 16, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text('contact@isetmahdia.rnu.tn',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
          ),
        ]),
      ]),
    );
  }
}

// ── Equipment Status Section ──────────────────────────────────────────────────

class _ParcSection extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _ParcSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    int _i(String k) => (stats[k] as num?)?.toInt() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _SectionHeader(icon: Icons.bar_chart_rounded, title: 'Equipment Status'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _StatusCard(
            count: _i('status_in_stock'),
            label: 'Operational',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF22C55E),
            bg: const Color(0xFFDCFCE7),
          )),
          const SizedBox(width: 10),
          Expanded(child: _StatusCard(
            count: _i('status_in_maintenance'),
            label: 'Maintenance',
            icon: Icons.build_outlined,
            color: const Color(0xFFF59E0B),
            bg: const Color(0xFFFFF8E6),
          )),
          const SizedBox(width: 10),
          Expanded(child: _StatusCard(
            count: _i('status_critical_issue'),
            label: 'Critical',
            icon: Icons.warning_amber_outlined,
            color: const Color(0xFFEF4444),
            bg: const Color(0xFFFFEEEE),
          )),
          const SizedBox(width: 10),
          Expanded(child: _StatusCard(
            count: _i('status_retired'),
            label: 'Retired',
            icon: Icons.archive_outlined,
            color: const Color(0xFF9CA3AF),
            bg: const Color(0xFFF3F4F6),
          )),
        ]),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color, bg;
  const _StatusCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(height: 8),
        Text('$count',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8)),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── QR Section ────────────────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  final List<Department> departments;
  const _QrSection({required this.departments});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              icon: Icons.qr_code_2,
              title: 'Department QR Codes',
              count: departments.length),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
            children: departments.map((d) => _QrCard(dept: d)).toList(),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final Department dept;
  const _QrCard({required this.dept});

  Future<void> _download(BuildContext context) async {
    final url = ApiService.departmentQrUrl(dept.id);
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final savedPath =
          await downloadFileLocally(res.bodyBytes, 'qr_dept_${dept.code}.png');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Saved: $savedPath'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = dept.flutterColor;
    final qrUrl = ApiService.departmentQrUrl(dept.id);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(dept.code,
                  style: const TextStyle(
                      color: _white, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            GestureDetector(
              onTap: () => _download(context),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.download_rounded, size: 16, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _showFullQR(context, qrUrl, color),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                qrUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : Center(
                        child: CircularProgressIndicator(color: color, strokeWidth: 2)),
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.qr_code_2,
                      color: color.withOpacity(0.3), size: 48),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(dept.code,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: _dark)),
        Text(dept.name,
            style: const TextStyle(fontSize: 10, color: _muted),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  void _showFullQR(BuildContext context, String url, Color color) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${dept.code} — ${dept.name}',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
        content: SizedBox(
          width: 260, height: 260,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, p) =>
                p == null ? child : Center(child: CircularProgressIndicator(color: color)),
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.error_outline, color: Color(0xFFEF4444))),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _download(context),
            icon: Icon(Icons.download_rounded, size: 16, color: color),
            label: Text('Download', style: TextStyle(color: color)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _muted)),
          ),
        ],
      ),
    );
  }
}

// ── Department Card ───────────────────────────────────────────────────────────

class _DepartmentCard extends StatelessWidget {
  final Department dept;
  final VoidCallback onTap;
  const _DepartmentCard({required this.dept, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = dept.flutterColor;
    final colorBg = color.withOpacity(0.08);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colour banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(dept.code,
                              style: const TextStyle(
                                  color: _white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 6),
                        Text(dept.name,
                            style: const TextStyle(
                                color: _white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business_outlined,
                        color: _white, size: 22),
                  ),
                ]),
              ),
              // Stats row
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(
                    child: _StatBox(
                      value: '${dept.roomCount}',
                      label: 'Rooms',
                      color: _accent,
                      bg: _accent.withOpacity(0.07),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      value: '${dept.productCount}',
                      label: 'Equipment',
                      color: const Color(0xFF22C55E),
                      bg: const Color(0xFF22C55E).withOpacity(0.07),
                    ),
                  ),
                ]),
              ),
              // Footer CTA
              Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: color.withOpacity(0.12))),
                  color: colorBg,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(children: [
                  Icon(Icons.meeting_room_outlined, size: 15, color: color),
                  const SizedBox(width: 8),
                  Text('View Rooms',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  const Spacer(),
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 14, color: color),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final Color color, bg;
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.75),
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
