import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class _Prod {
  final String id, name, sku, status;
  const _Prod({required this.id, required this.name, required this.sku, required this.status});

  factory _Prod.fromJson(Map j) => _Prod(
        id:     j['id']?.toString() ?? '',
        name:   j['name']?.toString() ?? '',
        sku:    j['sku']?.toString() ?? '',
        status: j['status']?.toString() ?? 'in_stock',
      );

  Color get dotColor => switch (status) {
        'in_stock'       => const Color(0xFF22C55E),
        'in_maintenance' => const Color(0xFFF59E0B),
        'critical_issue' => const Color(0xFFEF4444),
        _                => const Color(0xFF94A3B8),
      };

  String get tag {
    if (sku.isNotEmpty) return sku.length > 9 ? sku.substring(0, 9) : sku;
    return name.length > 9 ? '${name.substring(0, 8)}…' : name;
  }
}

class _Room {
  final String id, name, type;
  final int productCount, inStock, inMaintenance, criticalIssue;
  final List<_Prod> products;

  _Room({
    required this.id,
    required this.name,
    required this.type,
    required this.productCount,
    required this.inStock,
    required this.inMaintenance,
    required this.criticalIssue,
    List<_Prod>? products,
  }) : products = products ?? const [];

  factory _Room.fromJson(Map j) {
    List<_Prod> prods = const [];
    try {
      final raw = j['products'];
      if (raw is List && raw.isNotEmpty) {
        prods = raw.map<_Prod>((p) => _Prod.fromJson(p as Map)).toList();
      }
    } catch (_) {}
    return _Room(
      id:            j['id']?.toString() ?? '',
      name:          j['name']?.toString() ?? '',
      type:          j['type']?.toString() ?? 'classroom',
      productCount:  int.tryParse(j['product_count']?.toString() ?? '0') ?? 0,
      inStock:       int.tryParse(j['in_stock']?.toString() ?? '0') ?? 0,
      inMaintenance: int.tryParse(j['in_maintenance']?.toString() ?? '0') ?? 0,
      criticalIssue: int.tryParse(j['critical_issue']?.toString() ?? '0') ?? 0,
      products:      prods,
    );
  }
}

class _Dept {
  final String id, code, name;
  final Color color;
  final List<_Room> rooms;
  int get totalProducts => rooms.fold(0, (s, r) => s + r.productCount);

  const _Dept({
    required this.id,
    required this.code,
    required this.name,
    required this.color,
    required this.rooms,
  });

  factory _Dept.fromJson(Map j) {
    final hex = (j['color'] as String? ?? '#6366F1').replaceAll('#', '').padLeft(6, '0');
    List<_Room> rooms = const [];
    try {
      final raw = j['rooms'];
      if (raw is List) rooms = raw.map<_Room>((r) => _Room.fromJson(r as Map)).toList();
    } catch (_) {}
    return _Dept(
      id:    j['id']?.toString() ?? '',
      code:  j['code']?.toString() ?? '',
      name:  j['name']?.toString() ?? '',
      color: Color(int.parse('FF$hex', radix: 16)),
      rooms: rooms,
    );
  }
}

// ─── Zone layout constants ────────────────────────────────────────────────────

const _kCols      = 3;
const _kItemW     = 70.0;
const _kItemH     = 56.0;   // dot(22) + gap(6) + label(14) + vspace(14)
const _kZonePadX  = 12.0;
const _kZonePadY  = 10.0;
const _kZoneHdrH  = 36.0;
const _kZoneW     = _kCols * _kItemW + 2 * _kZonePadX; // 234

double _zoneH(int n) {
  final rows = ((n < 1 ? 1 : n) + _kCols - 1) ~/ _kCols;
  return _kZoneHdrH + _kZonePadY + rows * _kItemH + _kZonePadY;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class EquipmentMapScreen extends StatefulWidget {
  const EquipmentMapScreen({Key? key}) : super(key: key);
  @override
  State<EquipmentMapScreen> createState() => _EquipmentMapScreenState();
}

class _EquipmentMapScreenState extends State<EquipmentMapScreen> {
  List<_Dept> _depts = [];
  bool _loading = true;
  String? _filterDeptId;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final _txCtrl     = TransformationController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text.toLowerCase().trim()));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _txCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getMapData();
      if (mounted) setState(() {
        _depts   = raw.map((j) => _Dept.fromJson(j as Map)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalItems => _depts.fold(0, (s, d) => s + d.totalProducts);

  List<_Dept> get _visible =>
      _filterDeptId == null ? _depts : _depts.where((d) => d.id == _filterDeptId).toList();

  void _scaleBy(double f) {
    final m = _txCtrl.value.clone()..scale(f);
    _txCtrl.value = m;
  }

  void _openRoom(_Room r, _Dept d) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RoomSheet(room: r, dept: d),
      );

  void _openProd(_Prod p, _Room r, _Dept d) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ProdSheet(prod: p, room: r, dept: d),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              children: [
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                else if (_depts.isEmpty)
                  const Center(
                      child: Text('No departments found',
                          style: TextStyle(color: Color(0xFF94A3B8))))
                else
                  InteractiveViewer(
                    transformationController: _txCtrl,
                    minScale: 0.25,
                    maxScale: 3.5,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 60, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: _visible
                            .where((d) => d.rooms.isNotEmpty)
                            .map((d) => Padding(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: _DeptRow(
                                    dept: d,
                                    search: _search,
                                    onRoomTap: (r) => _openRoom(r, d),
                                    onProdTap: (p, r) => _openProd(p, r, d),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                // Zoom controls
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ZoomPanel(
                      onIn:    () => _scaleBy(1.25),
                      onOut:   () => _scaleBy(0.8),
                      onReset: () => _txCtrl.value = Matrix4.identity(),
                    ),
                  ),
                ),
                // Legend
                Positioned(
                  bottom: 12, left: 0, right: 0,
                  child: Center(child: _Legend()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

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
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('2D Facility Floor Plan',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  Text(
                    'ISET · ${_depts.length} departments · $_totalItems equipment markers',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ]),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('Live',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF22C55E))),
              ]),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 20),
                onPressed: _load,
              ),
            ]),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                  hintText: 'Search equipment, room…',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
          // Dept filter chips
          if (_depts.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(children: [
                _DeptChip(
                  label: 'All',
                  color: const Color(0xFF64748B),
                  selected: _filterDeptId == null,
                  onTap: () => setState(() => _filterDeptId = null),
                ),
                ..._depts.map((d) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _DeptChip(
                        label: '${d.code}  ${d.totalProducts}',
                        color: d.color,
                        selected: _filterDeptId == d.id,
                        onTap: () => setState(
                            () => _filterDeptId = _filterDeptId == d.id ? null : d.id),
                      ),
                    )),
              ]),
            ),
        ]),
      ),
    );
  }
}

// ─── Department row ───────────────────────────────────────────────────────────

class _DeptRow extends StatelessWidget {
  final _Dept dept;
  final String search;
  final void Function(_Room) onRoomTap;
  final void Function(_Prod, _Room) onProdTap;

  const _DeptRow({
    required this.dept,
    required this.search,
    required this.onRoomTap,
    required this.onProdTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = dept.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dept label bar
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
            child: Text(dept.code,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Text(dept.name,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('${dept.totalProducts}',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
        const SizedBox(height: 10),
        // Room zones
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: dept.rooms.map((room) {
            final matches = search.isEmpty ||
                room.name.toLowerCase().contains(search) ||
                room.products.any((p) =>
                    p.name.toLowerCase().contains(search) ||
                    p.sku.toLowerCase().contains(search));
            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: search.isNotEmpty && !matches ? 0.28 : 1.0,
                child: _ZoneWidget(
                  room: room,
                  dept: dept,
                  search: search,
                  onRoomTap: () => onRoomTap(room),
                  onProdTap: (p) => onProdTap(p, room),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Zone widget (one room) ───────────────────────────────────────────────────

class _ZoneWidget extends StatelessWidget {
  final _Room room;
  final _Dept dept;
  final String search;
  final VoidCallback onRoomTap;
  final void Function(_Prod) onProdTap;

  const _ZoneWidget({
    required this.room,
    required this.dept,
    required this.search,
    required this.onRoomTap,
    required this.onProdTap,
  });

  @override
  Widget build(BuildContext context) {
    final color  = dept.color;
    final n      = room.products.length;
    final height = _zoneH(n);

    return GestureDetector(
      onTap: onRoomTap,
      child: Container(
        width:  _kZoneW,
        height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.28), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone label header
            Container(
              height: _kZoneHdrH,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                    '${dept.code} – ${room.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                if (room.productCount > 0)
                  Text('${room.productCount}',
                      style: TextStyle(
                          fontSize: 10,
                          color: color.withOpacity(0.6),
                          fontWeight: FontWeight.w600)),
              ]),
            ),
            // Dot markers
            Expanded(
              child: room.products.isEmpty
                  ? Center(
                      child: Text('Empty',
                          style: TextStyle(fontSize: 11, color: color.withOpacity(0.35))))
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: _kZonePadX, vertical: _kZonePadY),
                      child: Wrap(
                        children: room.products
                            .map((p) => _DotMarker(
                                  prod: p,
                                  search: search,
                                  onTap: () => onProdTap(p),
                                ))
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dot marker (one equipment item) ─────────────────────────────────────────

class _DotMarker extends StatelessWidget {
  final _Prod prod;
  final String search;
  final VoidCallback onTap;

  const _DotMarker({required this.prod, required this.search, required this.onTap});

  bool get _hi =>
      search.isNotEmpty &&
      (prod.name.toLowerCase().contains(search) ||
          prod.sku.toLowerCase().contains(search));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width:  _kItemW,
        height: _kItemH,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width:  _hi ? 26 : 22,
            height: _hi ? 26 : 22,
            decoration: BoxDecoration(
              color: prod.dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: prod.dotColor.withOpacity(0.35),
                    blurRadius: _hi ? 10 : 4,
                    spreadRadius: _hi ? 2 : 0),
              ],
              border: _hi ? Border.all(color: Colors.white, width: 2.5) : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            prod.tag,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: _hi ? FontWeight.w800 : FontWeight.w500,
              color: _hi ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Product detail sheet ─────────────────────────────────────────────────────

class _ProdSheet extends StatelessWidget {
  final _Prod prod;
  final _Room room;
  final _Dept dept;
  const _ProdSheet({required this.prod, required this.room, required this.dept});

  @override
  Widget build(BuildContext context) {
    final color = dept.color;
    final statusLabel = switch (prod.status) {
      'in_stock'       => 'In Stock',
      'in_maintenance' => 'In Maintenance',
      'critical_issue' => 'Critical Issue',
      _                => 'Retired',
    };
    return Container(
      margin: const EdgeInsets.only(top: 120),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: prod.dotColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.devices_other, color: prod.dotColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(prod.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              if (prod.sku.isNotEmpty)
                Text(prod.sku,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: prod.dotColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: prod.dotColor)),
          ),
        ]),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Text(dept.code,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          Text(room.name,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Text('· ${dept.name}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ]),
      ]),
    );
  }
}

// ─── Room sheet ───────────────────────────────────────────────────────────────

class _RoomSheet extends StatelessWidget {
  final _Room room;
  final _Dept dept;
  const _RoomSheet({required this.room, required this.dept});

  @override
  Widget build(BuildContext context) {
    final color = dept.color;
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Center(
          child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration:
                  BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Text(dept.code,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(room.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                Text(dept.name,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('${room.productCount} items',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
        ),
        const Divider(height: 24),
        Expanded(
          child: room.products.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inbox_outlined, size: 52, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('No items in this room',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: room.products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p           = room.products[i];
                    final statusColor = p.dotColor;
                    final statusLabel = switch (p.status) {
                      'in_stock'       => 'In Stock',
                      'in_maintenance' => 'Maintenance',
                      'critical_issue' => 'Critical',
                      _                => 'Retired',
                    };
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.devices_other, size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B))),
                            if (p.sku.isNotEmpty)
                              Text(p.sku,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF94A3B8))),
                          ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(statusLabel,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor)),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ─── Zoom panel ───────────────────────────────────────────────────────────────

class _ZoomPanel extends StatelessWidget {
  final VoidCallback onIn, onOut, onReset;
  const _ZoomPanel({required this.onIn, required this.onOut, required this.onReset});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        _ZoomBtn(icon: Icons.add, onTap: onIn),
        const SizedBox(height: 8),
        _ZoomBtn(icon: Icons.remove, onTap: onOut),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onReset,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
            ),
            child: const Center(
              child: Text('1:1',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            ),
          ),
        ),
      ]);
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF475569)),
        ),
      );
}

// ─── Dept chip ────────────────────────────────────────────────────────────────

class _DeptChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _DeptChip(
      {required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : const Color(0xFFE2E8F0)),
            boxShadow: selected
                ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 6)]
                : [],
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF64748B))),
        ),
      );
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.93),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _LegendDot(const Color(0xFF22C55E), 'In Stock'),
          const SizedBox(width: 14),
          _LegendDot(const Color(0xFFF59E0B), 'Maintenance'),
          const SizedBox(width: 14),
          _LegendDot(const Color(0xFFEF4444), 'Critical'),
          const SizedBox(width: 14),
          _LegendDot(const Color(0xFF94A3B8), 'Retired'),
        ]),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ]);
}
