import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  static const _statusColor = {
    'in_stock':       Color(0xFF10B981),
    'operational':    Color(0xFF4F46E5),
    'in_maintenance': Color(0xFFF59E0B),
    'critical_issue': Color(0xFFEF4444),
    'retired':        Color(0xFF6B7280),
    'lost':           Color(0xFF8B5CF6),
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getAnalyticsDashboard();
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() { _data = res['data'] as Map<String, dynamic>; _loading = false; });
      } else {
        setState(() { _error = res['message'] ?? 'Failed'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.card(context), elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Analytics', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryRow(),
                      const SizedBox(height: 16),
                      _buildStatusPie(),
                      const SizedBox(height: 16),
                      _buildDeptBar(),
                      const SizedBox(height: 16),
                      _buildMaintenanceTrend(),
                      const SizedBox(height: 16),
                      _buildTopMaintained(),
                      const SizedBox(height: 16),
                      _buildWarrantyCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryRow() {
    final warranty = _data!['warranty'] as Map<String, dynamic>;
    final scans    = _data!['scans_7d'] as int;
    final byStatus = _data!['by_status'] as List;
    final total    = byStatus.fold<int>(0, (s, r) => s + (r['count'] as int));

    return Row(children: [
      _statCard('Total Items', total.toString(), Icons.inventory_2_outlined, AppColors.primary),
      const SizedBox(width: 10),
      _statCard('Scans (7d)', scans.toString(), Icons.qr_code_scanner_outlined, const Color(0xFF0EA5E9)),
      const SizedBox(width: 10),
      _statCard('Warranty\nExpiring', warranty['expiring_soon'].toString(),
          Icons.verified_outlined, const Color(0xFFF59E0B)),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context), borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    ),
  );

  Widget _buildStatusPie() {
    final byStatus = _data!['by_status'] as List<dynamic>;
    if (byStatus.isEmpty) return const SizedBox.shrink();

    final sections = byStatus.map((r) {
      final status = r['status'] as String;
      final count  = (r['count'] as int).toDouble();
      final color  = _statusColor[status] ?? AppColors.textMuted;
      return PieChartSectionData(
        value: count, color: color,
        title: count.toInt().toString(),
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        radius: 60,
      );
    }).toList();

    return _card(
      title: 'Equipment by Status',
      child: Column(children: [
        SizedBox(
          height: 200,
          child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 36)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12, runSpacing: 6,
          children: byStatus.map((r) {
            final status = r['status'] as String;
            final color  = _statusColor[status] ?? AppColors.textMuted;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('${status.replaceAll('_', ' ')} (${r['count']})',
                  style: const TextStyle(fontSize: 11, color: AppColors.textBody)),
            ]);
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildDeptBar() {
    final byDept = _data!['by_department'] as List<dynamic>;
    if (byDept.isEmpty) return const SizedBox.shrink();

    final maxVal = byDept.fold<int>(1, (m, r) => (r['count'] as int) > m ? r['count'] as int : m);

    return _card(
      title: 'Equipment by Department',
      child: SizedBox(
        height: 200,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal.toDouble() * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= byDept.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(byDept[i]['code'] as String,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                );
              },
            )),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: byDept.asMap().entries.map((e) {
            final colorHex = e.value['color'] as String? ?? '#6366F1';
            final color = _hexColor(colorHex);
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: (e.value['count'] as int).toDouble(),
                color: color, width: 28,
                borderRadius: BorderRadius.circular(6),
              ),
            ]);
          }).toList(),
        )),
      ),
    );
  }

  Widget _buildMaintenanceTrend() {
    final trend = _data!['maintenance_trend'] as List<dynamic>;
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxVal = trend.fold<int>(1, (m, r) => (r['total'] as int) > m ? r['total'] as int : m);

    return _card(
      title: 'Maintenance Trend (6 months)',
      child: SizedBox(
        height: 180,
        child: LineChart(LineChartData(
          minY: 0, maxY: maxVal.toDouble() * 1.3,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 24,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                return Text(trend[i]['month'] as String,
                    style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
              },
            )),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((e) =>
                  FlSpot(e.key.toDouble(), (e.value['total'] as int).toDouble())).toList(),
              isCurved: true, color: AppColors.primary, barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
            ),
            LineChartBarData(
              spots: trend.asMap().entries.map((e) =>
                  FlSpot(e.key.toDouble(), (e.value['done'] as int).toDouble())).toList(),
              isCurved: true, color: const Color(0xFF22C55E), barWidth: 2,
              dotData: const FlDotData(show: false),
              dashArray: [4, 4],
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildTopMaintained() {
    final top = _data!['top_maintained'] as List<dynamic>;
    if (top.isEmpty) return const SizedBox.shrink();

    return _card(
      title: 'Most Maintained Items',
      child: Column(
        children: top.asMap().entries.map((e) {
          final rank = e.key + 1;
          final item = e.value;
          final pct  = (item['count'] as int) / (top.first['count'] as int);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: rank == 1 ? const Color(0xFFF59E0B) : AppColors.bgMuted,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('$rank',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                        color: rank == 1 ? Colors.white : AppColors.textMuted))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textH)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pct, minHeight: 5,
                  backgroundColor: AppColors.bgMuted,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ])),
              const SizedBox(width: 10),
              Text('${item['count']}×', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWarrantyCard() {
    final warranty = _data!['warranty'] as Map<String, dynamic>;
    return _card(
      title: 'Warranty Status',
      child: Row(children: [
        _warrantyTile('Expiring Soon', warranty['expiring_soon'].toString(), const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _warrantyTile('Already Expired', warranty['expired'].toString(), const Color(0xFFEF4444)),
      ]),
    );
  }

  Widget _warrantyTile(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _card({required String title, required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card(context), borderRadius: BorderRadius.circular(16),
      boxShadow: AppColors.shadowMd,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textH)),
      const SizedBox(height: 14),
      child,
    ]),
  );

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
