import 'package:flutter/material.dart';
import '../services/api_service.dart';

// â”€â”€â”€ Design tokens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const _accent  = Color(0xFF4A7CFC);
const _accent2 = Color(0xFF6B5BFD);
const _bg      = Color(0xFFF5F6FA);
const _dark    = Color(0xFF1A1D2E);
const _muted   = Color(0xFFB0B7C3);

// â”€â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class MoveLogScreen extends StatefulWidget {
  const MoveLogScreen({Key? key}) : super(key: key);

  @override
  State<MoveLogScreen> createState() => _MoveLogScreenState();
}

class _MoveLogScreenState extends State<MoveLogScreen> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String _search = '';
  String _filter = 'all'; // 'all' | 'today' | 'week'
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
        () => setState(() => _search = _searchCtrl.text.toLowerCase().trim()));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getMoveLog();
      if (mounted) {
        setState(() {
          _all = raw.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final now        = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart  = todayStart.subtract(const Duration(days: 7));

    return _all.where((item) {
      if (_filter != 'all') {
        final raw = item['last_moved_at'];
        if (raw == null) return false;
        final dt = DateTime.tryParse(raw.toString())?.toLocal();
        if (dt == null) return false;
        if (_filter == 'today' && dt.isBefore(todayStart)) return false;
        if (_filter == 'week'  && dt.isBefore(weekStart))  return false;
      }
      if (_search.isNotEmpty) {
        final name  = (item['name']          ?? '').toString().toLowerCase();
        final sku   = (item['sku']           ?? '').toString().toLowerCase();
        final room  = (item['room_name']     ?? '').toString().toLowerCase();
        final dept  = (item['dept_name']     ?? '').toString().toLowerCase();
        final mover = (item['moved_by_name'] ?? '').toString().toLowerCase();
        if (!name.contains(_search)  && !sku.contains(_search) &&
            !room.contains(_search)  && !dept.contains(_search) &&
            !mover.contains(_search)) return false;
      }
      return true;
    }).toList();
  }

  int _countSince(DateTime since) => _all.where((item) {
        final raw = item['last_moved_at'];
        if (raw == null) return false;
        final dt = DateTime.tryParse(raw.toString())?.toLocal();
        return dt != null && dt.isAfter(since);
      }).length;

  int get _todayCount {
    final n = DateTime.now();
    return _countSince(DateTime(n.year, n.month, n.day));
  }

  int get _weekCount =>
      _countSince(DateTime.now().subtract(const Duration(days: 7)));

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _accent,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildStats()),
                      SliverToBoxAdapter(child: _buildFilters()),
                      if (items.isEmpty)
                        SliverFillRemaining(
                            hasScrollBody: false, child: _buildEmpty())
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: EdgeInsets.fromLTRB(
                                  16, i == 0 ? 0 : 10, 16, 0),
                              child: _MoveCard(item: items[i]),
                            ),
                            childCount: items.length,
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: _bg, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back, size: 20, color: _dark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Move Log',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _dark)),
                      Text(
                        '${_all.length} item${_all.length == 1 ? '' : 's'} relocated',
                        style:
                            const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ]),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: _muted, size: 20),
                onPressed: _loading ? null : _load,
              ),
            ]),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search item, room, department, mover…',
                  hintStyle: TextStyle(color: _muted, fontSize: 13),
                  prefixIcon:
                      Icon(Icons.search, color: _muted, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // â”€â”€ Stats row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        _StatPill(
          label: 'Total',
          value: _all.length,
          color: _accent,
          icon: Icons.swap_horiz_rounded,
        ),
        const SizedBox(width: 10),
        _StatPill(
          label: 'Today',
          value: _todayCount,
          color: const Color(0xFF22C55E),
          icon: Icons.today_rounded,
        ),
        const SizedBox(width: 10),
        _StatPill(
          label: 'This Week',
          value: _weekCount,
          color: const Color(0xFFF59E0B),
          icon: Icons.date_range_rounded,
        ),
      ]),
    );
  }

  // â”€â”€ Filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(children: [
        _FilterChip(
          label: 'All',
          selected: _filter == 'all',
          onTap: () => setState(() => _filter = 'all'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Today',
          selected: _filter == 'today',
          onTap: () => setState(() => _filter = 'today'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'This Week',
          selected: _filter == 'week',
          onTap: () => setState(() => _filter = 'week'),
        ),
      ]),
    );
  }

  // â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.swap_horiz_rounded,
              size: 36, color: _accent),
        ),
        const SizedBox(height: 16),
        const Text('No moves found',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _dark)),
        const SizedBox(height: 6),
        const Text(
          'Items relocated on the 2D map will appear here',
          style: TextStyle(fontSize: 13, color: _muted),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

// â”€â”€â”€ Stat pill â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 15, color: color),
            ),
            const Spacer(),
            Text('$value',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color)),
          ]),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: _muted,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// â”€â”€â”€ Filter chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? _accent : const Color(0xFFE2E8F0)),
            boxShadow: selected
                ? [BoxShadow(
                    color: _accent.withOpacity(0.25), blurRadius: 6)]
                : [],
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : const Color(0xFF64748B))),
        ),
      );
}

// â”€â”€â”€ Move card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MoveCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _MoveCard({required this.item});

  Color get _statusColor => switch (item['status']?.toString()) {
        'in_stock'       => const Color(0xFF22C55E),
        'in_maintenance' => const Color(0xFFF59E0B),
        'critical_issue' => const Color(0xFFEF4444),
        _                => const Color(0xFF94A3B8),
      };

  String get _statusLabel => switch (item['status']?.toString()) {
        'in_stock'       => 'In Stock',
        'in_maintenance' => 'Maintenance',
        'critical_issue' => 'Critical',
        _                => 'Retired',
      };

  Color get _deptColor {
    final hex = (item['dept_color']?.toString() ?? '#6366F1')
        .replaceAll('#', '')
        .padLeft(6, '0');
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  Color get _moverColor => _mlRoleColor(item['moved_by_role']?.toString());
  String get _moverLabel => _mlRoleLabel(item['moved_by_role']?.toString());

  @override
  Widget build(BuildContext context) {
    final deptColor   = _deptColor;
    final statusColor = _statusColor;
    final moverColor  = _moverColor;

    final name        = item['name']?.toString() ?? '';
    final sku         = item['sku']?.toString() ?? '';
    final roomName    = item['room_name']?.toString() ?? 'Unknown room';
    final deptCode    = item['dept_code']?.toString() ?? '';
    final deptName    = item['dept_name']?.toString() ?? '';
    final movedByName = item['moved_by_name']?.toString() ?? 'Unknown';
    final timeStr     = _mlTimeAgo(item['last_moved_at']?.toString() ?? '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          // Status stripe
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          const SizedBox(width: 14),
          // Icon
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: deptColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.devices_other,
                  size: 22, color: deptColor),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + time
                    Row(children: [
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _dark)),
                      ),
                      const SizedBox(width: 8),
                      Text(timeStr,
                          style: const TextStyle(
                              fontSize: 11, color: _muted)),
                    ]),
                    if (sku.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(sku,
                          style: const TextStyle(
                              fontSize: 11, color: _muted)),
                    ],
                    const SizedBox(height: 8),
                    // Location
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: _muted),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: deptColor,
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(deptCode,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(roomName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569))),
                      ),
                      if (deptName.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text('· $deptName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: _muted)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 8),
                    // Status + mover row
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(_statusLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor)),
                      ),
                      const Spacer(),
                      // Mover avatar
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: moverColor.withOpacity(0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: moverColor.withOpacity(0.3),
                              width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            movedByName.isNotEmpty
                                ? movedByName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: moverColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(movedByName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _dark)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: moverColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_moverLabel,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: moverColor)),
                      ),
                    ]),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// â”€â”€â”€ Helpers (file-local to avoid duplicate top-level names) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Color _mlRoleColor(String? role) => switch (role) {
      'admin'      => const Color(0xFF4A7CFC),
      'technicien' => const Color(0xFF8B5CF6),
      'magazinier' => const Color(0xFF22C55E),
      _            => const Color(0xFF94A3B8),
    };

String _mlRoleLabel(String? role) => switch (role) {
      'admin'      => 'Admin',
      'technicien' => 'Tech',
      'magazinier' => 'Mag',
      _            => 'User',
    };

String _mlTimeAgo(String iso) {
  if (iso.isEmpty) return '';
  try {
    final dt   = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return '';
  }
}


