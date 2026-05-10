import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OverviewStats extends StatefulWidget {
  const OverviewStats({Key? key}) : super(key: key);

  @override
  State<OverviewStats> createState() => _OverviewStatsState();
}

class _OverviewStatsState extends State<OverviewStats> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stats = await ApiService.getStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF4A7CFC),
          ),
        ),
      );
    }

    if (_error != null || _stats == null) {
      return GestureDetector(
        onTap: _load,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Color(0xFFB0B7C3), size: 24),
                ),
                const SizedBox(height: 10),
                const Text('Tap to retry',
                    style: TextStyle(color: Color(0xFFB0B7C3), fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    final s     = _stats!;
    int _i(String k) => (s[k] as num?)?.toInt() ?? 0;
    final total = _i('total_products');
    final inStk = _i('status_in_stock');
    final inMnt = _i('status_in_maintenance');
    final crit  = _i('status_critical_issue');
    final retd  = _i('status_retired');
    final cats  = _i('categories_used');
    final scans = _i('total_scans');
    final value = (s['total_value'] as num?)?.toDouble() ?? 0.0;

    return Column(
      children: [
        // Top: Total (gradient) + Operational
        Row(children: [
          Expanded(child: _GradientCard(
            label: 'Total Items',
            value: total.toString(),
            icon: Icons.inventory_2_rounded,
          )),
          const SizedBox(width: 12),
          Expanded(child: _BigCard(
            label: 'Operational',
            value: inStk.toString(),
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFDCFCE7),
            accent: const Color(0xFF16A34A),
            percent: total > 0 ? inStk / total : null,
          )),
        ]),
        const SizedBox(height: 10),

        // Middle: Maintenance + Critical + Retired
        Row(children: [
          Expanded(child: _StatusCard(
            label: 'Maintenance',
            value: inMnt,
            icon: Icons.build_outlined,
            color: const Color(0xFFF59E0B),
            bg: const Color(0xFFFFF8E6),
          )),
          const SizedBox(width: 10),
          Expanded(child: _StatusCard(
            label: 'Critical',
            value: crit,
            icon: Icons.warning_amber_outlined,
            color: const Color(0xFFEF4444),
            bg: const Color(0xFFFFEEEE),
          )),
          const SizedBox(width: 10),
          Expanded(child: _StatusCard(
            label: 'Retired',
            value: retd,
            icon: Icons.archive_outlined,
            color: const Color(0xFF9CA3AF),
            bg: const Color(0xFFF3F4F6),
          )),
        ]),
        const SizedBox(height: 10),

        // Bottom: Categories + Scans + Value
        Row(children: [
          Expanded(child: _MiniCard(
            label: 'Categories',
            value: cats.toString(),
            icon: Icons.category_outlined,
            color: const Color(0xFF0EA5E9),
          )),
          const SizedBox(width: 10),
          Expanded(child: _MiniCard(
            label: 'Scans',
            value: scans.toString(),
            icon: Icons.qr_code_scanner,
            color: const Color(0xFF8B5CF6),
          )),
          const SizedBox(width: 10),
          Expanded(child: _MiniCard(
            label: 'Value',
            value: value >= 1000
                ? '${(value / 1000).toStringAsFixed(1)}k'
                : value.toStringAsFixed(0),
            icon: Icons.payments_outlined,
            color: const Color(0xFFD97706),
          )),
        ]),
      ],
    );
  }
}

// ─── Gradient hero card (Total) ───────────────────────────────────────────────

class _GradientCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _GradientCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A7CFC), Color(0xFF6B5BFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A7CFC).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Big card (Operational) ───────────────────────────────────────────────────

class _BigCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color accent;
  final double? percent;

  const _BigCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.accent,
    this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const Spacer(),
            if (percent != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(percent! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (percent != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent!,
                backgroundColor: iconBg,
                color: accent,
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Status card (Maintenance / Critical / Retired) ───────────────────────────

class _StatusCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatusCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 8),
          Text(value.toString(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withOpacity(0.75)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Mini card (Categories / Scans / Value) ──────────────────────────────────

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFFB0B7C3), fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
