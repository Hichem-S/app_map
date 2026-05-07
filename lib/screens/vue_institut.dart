import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/department.dart';
import '../utils/app_colors.dart';
import '../utils/download_helper.dart';
import 'dept_rooms_screen.dart';

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
      backgroundColor: AppColors.bgPage,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroHeader(
                      totalDepts: _departments.length,
                      totalRooms: _totalRooms,
                      totalItems: _totalItems,
                      inStock:       _stats?['status_in_stock']       ?? 0,
                      inMaintenance: _stats?['status_in_maintenance'] ?? 0,
                      critical:      _stats?['status_critical_issue'] ?? 0,
                      onQrTap: () => _showIsetQR(context),
                    ),
                    _ContactCard(),
                    const SizedBox(height: 20),
                    if (_stats != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ParcSection(stats: _stats!),
                      ),
                    const SizedBox(height: 24),
                    _QrSection(departments: _departments),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Départements',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textH)),
                    ),
                    const SizedBox(height: 12),
                    ..._departments.map((d) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _DepartmentCard(
                            dept: d,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DeptRoomsScreen(department: d)),
                            ),
                          ),
                        )),
                    const SizedBox(height: 32),
                  ],
                ),
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
          SnackBar(content: Text('Saved: $savedPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void _showIsetQR(BuildContext context) {
    final url = ApiService.isetQrUrl();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ISET Mahdia QR Code',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 240, height: 240,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, p) =>
                p == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.error_outline, color: Colors.red)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _downloadQr(url, 'iset_qr.png'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, size: 16),
                SizedBox(width: 4),
                Text('Download'),
              ],
            ),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
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
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onQrTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.qr_code_2, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('QR Institut', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.menu_book_outlined, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 12),
            const Text('ISET Mahdia',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Higher Institute of Technological Studies of Mahdia',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(icon: Icons.business_outlined,       value: '$totalDepts',    label: 'Dépts',  iconColor: Colors.white70),
                  _StatChip(icon: Icons.meeting_room_outlined,   value: '$totalRooms',    label: 'Salles', iconColor: Colors.white70),
                  _StatChip(icon: Icons.inventory_2_outlined,    value: '$totalItems',    label: 'Équip.', iconColor: Colors.white70),
                  _StatChip(icon: Icons.check_circle_outline,    value: '$inStock',       label: 'Op.',    iconColor: const Color(0xFF6EE7B7)),
                  _StatChip(icon: Icons.warning_amber_outlined,  value: '$critical',      label: 'Défect.', iconColor: const Color(0xFFFCD34D)),
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
  final Color iconColor;
  const _StatChip({required this.icon, required this.value, required this.label, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
            SizedBox(width: 8),
            Expanded(child: Text('Route de Hiboun, BP 153 — Mahdia 5100, Tunisie',
                style: TextStyle(fontSize: 13, color: AppColors.textBody))),
          ]),
          const SizedBox(height: 10),
          Row(children: const [
            Icon(Icons.phone_outlined, size: 16, color: AppColors.textMuted),
            SizedBox(width: 8),
            Text('+216 73 675 100', style: TextStyle(fontSize: 13, color: AppColors.textBody)),
            SizedBox(width: 24),
            Icon(Icons.email_outlined, size: 16, color: AppColors.textMuted),
            SizedBox(width: 8),
            Text('contact@isetmahdia.rnu.tn', style: TextStyle(fontSize: 12, color: AppColors.textBody)),
          ]),
        ],
      ),
    );
  }
}

// ── État du Parc ──────────────────────────────────────────────────────────────

class _ParcSection extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _ParcSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('État du Parc Matériel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textH)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _ParcCard(count: '${stats['status_in_stock'] ?? 0}',       label: 'Opérationnel', dotColor: const Color(0xFF22C55E), bg: const Color(0xFFDCFCE7), textColor: const Color(0xFF15803D))),
          const SizedBox(width: 10),
          Expanded(child: _ParcCard(count: '${stats['status_in_maintenance'] ?? 0}', label: 'Maintenance',  dotColor: const Color(0xFFF59E0B), bg: const Color(0xFFFEF9C3), textColor: const Color(0xFFB45309))),
          const SizedBox(width: 10),
          Expanded(child: _ParcCard(count: '${stats['status_critical_issue'] ?? 0}', label: 'Défectueux',  dotColor: const Color(0xFFEF4444), bg: const Color(0xFFFEE2E2), textColor: const Color(0xFFDC2626))),
          const SizedBox(width: 10),
          Expanded(child: _ParcCard(count: '${stats['status_retired'] ?? 0}',        label: 'Réformé',     dotColor: const Color(0xFF9CA3AF), bg: const Color(0xFFF3F4F6), textColor: const Color(0xFF6B7280))),
        ]),
      ],
    );
  }
}

class _ParcCard extends StatelessWidget {
  final String count, label;
  final Color dotColor, bg, textColor;
  const _ParcCard({required this.count, required this.label, required this.dotColor, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(Icons.circle, size: 10, color: dotColor),
        const SizedBox(height: 6),
        Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
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
          const Row(children: [
            Icon(Icons.qr_code_2, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Department QR Codes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textH)),
          ]),
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
      final savedPath = await downloadFileLocally(res.bodyBytes, 'qr_dept_${dept.code}.png');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: $savedPath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Badge row + download button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: Text(dept.code,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              GestureDetector(
                onTap: () => _download(context),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.download_rounded, size: 16, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Real QR image — tappable to show full-size
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
                      : Center(child: CircularProgressIndicator(color: color, strokeWidth: 2)),
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.qr_code_2, color: color.withValues(alpha: 0.3), size: 48),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(dept.code,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textH)),
          Text(dept.name,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _showFullQR(BuildContext context, String url, Color color) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Dept ${dept.code} — ${dept.name}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 260, height: 260,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, p) =>
                p == null ? child : Center(child: CircularProgressIndicator(color: color)),
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.error_outline, color: Colors.red)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _download(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, size: 16),
                SizedBox(width: 4),
                Text('Download'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.75)],
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
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(dept.name,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.business_outlined, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _StatBox(value: '${dept.roomCount}', label: 'Salles')),
                    const SizedBox(width: 8),
                    Expanded(child: _StatBox(value: '${dept.productCount}', label: 'Équipements')),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Row(
                  children: [
                    Text('Voir les salles', style: TextStyle(fontSize: 13, color: AppColors.textBody, fontWeight: FontWeight.w500)),
                    Spacer(),
                    Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
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
  final String value, label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.bgMuted, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textH)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ]),
    );
  }
}
