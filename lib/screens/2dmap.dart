import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────

const _accent  = Color(0xFF4A7CFC);
const _accent2 = Color(0xFF6B5BFD);
const _bg      = Color(0xFFF1F5F9);
const _dark    = Color(0xFF1E293B);
const _muted   = Color(0xFF94A3B8);

// ─── Models ──────────────────────────────────────────────────────────────────

class _Prod {
  final String id, name, sku, status;
  final String? movedByName, movedByRole, movedAt;

  const _Prod({
    required this.id,
    required this.name,
    required this.sku,
    required this.status,
    this.movedByName,
    this.movedByRole,
    this.movedAt,
  });

  factory _Prod.fromJson(Map j) => _Prod(
        id:          j['id']?.toString() ?? '',
        name:        j['name']?.toString() ?? '',
        sku:         j['sku']?.toString() ?? '',
        status:      j['status']?.toString() ?? 'in_stock',
        movedByName: j['moved_by_name'] as String?,
        movedByRole: j['moved_by_role'] as String?,
        movedAt:     j['last_moved_at']  as String?,
      );

  _Prod withMover(String name, String role) => _Prod(
        id: id, name: this.name, sku: sku, status: status,
        movedByName: name,
        movedByRole: role,
        movedAt: DateTime.now().toIso8601String(),
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
  final int productCount;
  List<_Prod> products;

  _Room({
    required this.id,
    required this.name,
    required this.type,
    required this.productCount,
    List<_Prod>? products,
  }) : products = products ?? [];

  factory _Room.fromJson(Map j) {
    List<_Prod> prods = [];
    try {
      final raw = j['products'];
      if (raw is List && raw.isNotEmpty) {
        prods = raw.map<_Prod>((p) => _Prod.fromJson(p as Map)).toList();
      }
    } catch (_) {}
    return _Room(
      id:           j['id']?.toString() ?? '',
      name:         j['name']?.toString() ?? '',
      type:         j['type']?.toString() ?? 'classroom',
      productCount: int.tryParse(j['product_count']?.toString() ?? '0') ?? 0,
      products:     prods,
    );
  }
}

class _Dept {
  final String id, code, name;
  final Color color;
  List<_Room> rooms;
  int get totalProducts => rooms.fold(0, (s, r) => s + r.products.length);

  _Dept({
    required this.id,
    required this.code,
    required this.name,
    required this.color,
    required this.rooms,
  });

  factory _Dept.fromJson(Map j) {
    final hex = (j['color'] as String? ?? '#6366F1').replaceAll('#', '').padLeft(6, '0');
    List<_Room> rooms = [];
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

const _kCols     = 3;
const _kItemW    = 70.0;
const _kItemH    = 56.0;
const _kZonePadX = 12.0;
const _kZonePadY = 10.0;
const _kZoneHdrH = 36.0;
const _kZoneW    = _kCols * _kItemW + 2 * _kZonePadX;

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

  // ── Move mode state ──────────────────────────────────────────────────────
  bool   _moveMode        = false;
  _Prod? _movingProd;
  String? _movingFromRoomId;
  bool   _saving          = false;

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
    _txCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getMapData();
      if (mounted) {
        setState(() {
          _depts   = raw.map((j) => _Dept.fromJson(j as Map)).toList();
          _loading = false;
        });
      }
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

  // ── Move mode logic ──────────────────────────────────────────────────────

  void _toggleMoveMode() {
    setState(() {
      _moveMode = !_moveMode;
      _movingProd      = null;
      _movingFromRoomId = null;
    });
  }

  void _selectItem(_Prod prod, String roomId) {
    setState(() {
      if (_movingProd?.id == prod.id) {
        // Tap same item → deselect
        _movingProd       = null;
        _movingFromRoomId = null;
      } else {
        _movingProd       = prod;
        _movingFromRoomId = roomId;
      }
    });
  }

  Future<void> _dropToRoom(String targetRoomId, String targetDeptId) async {
    final prod = _movingProd;
    if (prod == null) return;
    if (targetRoomId == _movingFromRoomId) {
      setState(() { _movingProd = null; _movingFromRoomId = null; });
      return;
    }

    setState(() => _saving = true);

    _Room? srcRoom;
    _Room? dstRoom;
    for (final d in _depts) {
      for (final r in d.rooms) {
        if (r.id == _movingFromRoomId) srcRoom = r;
        if (r.id == targetRoomId)      dstRoom = r;
      }
    }

    // Stamp current user onto the moved prod
    final auth = context.read<AuthProvider>();
    final movedProd = prod.withMover(
      auth.user?['name'] as String? ?? 'Unknown',
      auth.role,
    );

    // Optimistic update
    if (srcRoom != null && dstRoom != null) {
      setState(() {
        srcRoom!.products.removeWhere((p) => p.id == prod.id);
        dstRoom!.products.add(movedProd);
        _movingProd       = null;
        _movingFromRoomId = null;
      });
    }

    try {
      await ApiService.updateProductLocation(prod.id, roomId: targetRoomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${prod.name} moved to ${dstRoom?.name ?? targetRoomId}'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      // Revert on failure
      if (srcRoom != null && dstRoom != null) {
        setState(() {
          dstRoom!.products.removeWhere((p) => p.id == movedProd.id);
          srcRoom!.products.add(prod);
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Move failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openRoom(_Room r, _Dept d) {
    if (_moveMode) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomSheet(room: r, dept: d),
    );
  }

  void _openProd(_Prod p, _Room r, _Dept d) {
    if (_moveMode) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProdSheet(prod: p, room: r, dept: d),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _buildHeader(),
        // Move-mode banner
        if (_moveMode) _MoveBanner(
          movingProd: _movingProd,
          saving: _saving,
          onCancel: _toggleMoveMode,
        ),
        Expanded(
          child: Stack(children: [
            if (_loading)
              const Center(child: CircularProgressIndicator(color: _accent))
            else if (_depts.isEmpty)
              const Center(
                  child: Text('No departments found',
                      style: TextStyle(color: _muted)))
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
                                dept:          d,
                                search:        _search,
                                moveMode:      _moveMode,
                                movingProd:    _movingProd,
                                movingFromRoomId: _movingFromRoomId,
                                onRoomTap:     (r) => _openRoom(r, d),
                                onProdTap:     (p, r) => _openProd(p, r, d),
                                onSelectItem:  (p, r) => _selectItem(p, r.id),
                                onDropToRoom:  (r) => _dropToRoom(r.id, d.id),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            // Zoom controls
            Positioned(
              right: 12, top: 0, bottom: 0,
              child: Center(
                child: _ZoomPanel(
                  onIn:    () => _scaleBy(1.25),
                  onOut:   () => _scaleBy(0.8),
                  onReset: () => _txCtrl.value = Matrix4.identity(),
                ),
              ),
            ),
            // Legend
            if (!_moveMode)
              Positioned(
                bottom: 12, left: 0, right: 0,
                child: Center(child: _Legend()),
              ),
          ]),
        ),
      ]),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('2D Facility Floor Plan',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
                  Text(
                    'ISET · ${_depts.length} depts · $_totalItems items',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ]),
              ),
              // Live indicator
              Row(mainAxisSize: MainAxisSize.min, children: const [
                SizedBox(
                  width: 8, height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Color(0xFF22C55E), shape: BoxShape.circle),
                  ),
                ),
                SizedBox(width: 5),
                Text('Live',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF22C55E))),
              ]),
              const SizedBox(width: 4),
              // Move mode toggle
              GestureDetector(
                onTap: _toggleMoveMode,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _moveMode ? _accent : _bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _moveMode ? _accent : const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(Icons.open_with_rounded,
                      size: 19,
                      color: _moveMode ? Colors.white : _muted),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: _muted, size: 20),
                onPressed: _loading ? null : _load,
              ),
            ]),
          ),
          // Search bar
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
                  hintStyle: TextStyle(color: _muted, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: _muted, size: 18),
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
                        onTap: () => setState(() =>
                            _filterDeptId = _filterDeptId == d.id ? null : d.id),
                      ),
                    )),
              ]),
            ),
        ]),
      ),
    );
  }
}

// ─── Move mode banner ─────────────────────────────────────────────────────────

class _MoveBanner extends StatelessWidget {
  final _Prod? movingProd;
  final bool saving;
  final VoidCallback onCancel;

  const _MoveBanner({
    required this.movingProd,
    required this.saving,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accent, _accent2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.open_with_rounded, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: saving
              ? const Row(children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text('Moving item…',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ])
              : movingProd != null
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Moving: ${movingProd!.name}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('Tap a destination room to place it',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11)),
                    ])
                  : const Text('Tap any item to select it, then tap a room to move it',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
        ),
        GestureDetector(
          onTap: onCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Text('Done',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ─── Department row ───────────────────────────────────────────────────────────

class _DeptRow extends StatelessWidget {
  final _Dept dept;
  final String search;
  final bool moveMode;
  final _Prod? movingProd;
  final String? movingFromRoomId;
  final void Function(_Room) onRoomTap;
  final void Function(_Prod, _Room) onProdTap;
  final void Function(_Prod, _Room) onSelectItem;
  final void Function(_Room) onDropToRoom;

  const _DeptRow({
    required this.dept,
    required this.search,
    required this.moveMode,
    required this.movingProd,
    required this.movingFromRoomId,
    required this.onRoomTap,
    required this.onProdTap,
    required this.onSelectItem,
    required this.onDropToRoom,
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
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(7)),
            child: Text(dept.code,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Text(dept.name,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
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
            final isSource = room.id == movingFromRoomId;
            final isDropTarget = moveMode && movingProd != null && !isSource;

            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: search.isNotEmpty && !matches ? 0.28 : 1.0,
                child: _ZoneWidget(
                  room:         room,
                  dept:         dept,
                  search:       search,
                  moveMode:     moveMode,
                  movingProd:   movingProd,
                  isSource:     isSource,
                  isDropTarget: isDropTarget,
                  onRoomTap:    () => isDropTarget
                      ? onDropToRoom(room)
                      : onRoomTap(room),
                  onProdTap:    (p) => moveMode
                      ? onSelectItem(p, room)
                      : onProdTap(p, room),
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
  final bool moveMode;
  final _Prod? movingProd;
  final bool isSource;
  final bool isDropTarget;
  final VoidCallback onRoomTap;
  final void Function(_Prod) onProdTap;

  const _ZoneWidget({
    required this.room,
    required this.dept,
    required this.search,
    required this.moveMode,
    required this.movingProd,
    required this.isSource,
    required this.isDropTarget,
    required this.onRoomTap,
    required this.onProdTap,
  });

  @override
  Widget build(BuildContext context) {
    final color  = dept.color;
    // Dynamic height: account for possible incoming item preview
    final n      = room.products.length;
    final height = _zoneH(n);

    // Border style based on move state
    final borderColor = isSource
        ? _accent
        : isDropTarget
            ? const Color(0xFF22C55E)
            : color.withOpacity(0.28);
    final borderWidth = (isSource || isDropTarget) ? 2.0 : 1.5;
    final bgColor = isSource
        ? _accent.withOpacity(0.08)
        : isDropTarget
            ? const Color(0xFF22C55E).withOpacity(0.07)
            : color.withOpacity(0.07);

    return GestureDetector(
      onTap: onRoomTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width:  _kZoneW,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isDropTarget
              ? [BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 3))]
              : isSource
                  ? [BoxShadow(
                      color: _accent.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 3))]
                  : [BoxShadow(
                      color: color.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone header
            Container(
              height: _kZoneHdrH,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDropTarget
                    ? const Color(0xFF22C55E).withOpacity(0.15)
                    : isSource
                        ? _accent.withOpacity(0.15)
                        : color.withOpacity(0.13),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(children: [
                // Drop target indicator icon
                if (isDropTarget) ...[
                  const Icon(Icons.download_rounded,
                      size: 13, color: Color(0xFF22C55E)),
                  const SizedBox(width: 4),
                ] else if (isSource) ...[
                  const Icon(Icons.upload_rounded,
                      size: 13, color: _accent),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    '${dept.code} – ${room.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDropTarget
                            ? const Color(0xFF16A34A)
                            : isSource
                                ? _accent
                                : color),
                  ),
                ),
                Text('${room.products.length}',
                    style: TextStyle(
                        fontSize: 10,
                        color: (isDropTarget
                                ? const Color(0xFF22C55E)
                                : color)
                            .withOpacity(0.6),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            // Dots or "Drop here" placeholder
            Expanded(
              child: isDropTarget && room.products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline,
                              size: 22,
                              color: const Color(0xFF22C55E).withOpacity(0.6)),
                          const SizedBox(height: 4),
                          Text('Drop here',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: const Color(0xFF22C55E)
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : room.products.isEmpty
                      ? Center(
                          child: Text(
                            isDropTarget ? 'Drop here' : 'Empty',
                            style: TextStyle(
                                fontSize: 11,
                                color: isDropTarget
                                    ? const Color(0xFF22C55E).withOpacity(0.7)
                                    : color.withOpacity(0.35)),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: _kZonePadX, vertical: _kZonePadY),
                          child: Wrap(
                            children: room.products
                                .map((p) => _DotMarker(
                                      prod:     p,
                                      search:   search,
                                      moveMode: moveMode,
                                      selected: movingProd?.id == p.id,
                                      onTap:    () => onProdTap(p),
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _roleColor(String? role) => switch (role) {
      'admin'      => const Color(0xFF4A7CFC),
      'technicien' => const Color(0xFF8B5CF6),
      'magazinier' => const Color(0xFF22C55E),
      _            => const Color(0xFF94A3B8),
    };

String _roleLabel(String? role) => switch (role) {
      'admin'      => 'Admin',
      'technicien' => 'Tech',
      'magazinier' => 'Mag',
      _            => 'User',
    };

String _timeAgo(String iso) {
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

// ─── Dot marker ───────────────────────────────────────────────────────────────

class _DotMarker extends StatelessWidget {
  final _Prod prod;
  final String search;
  final bool moveMode;
  final bool selected;
  final VoidCallback onTap;

  const _DotMarker({
    required this.prod,
    required this.search,
    required this.moveMode,
    required this.selected,
    required this.onTap,
  });

  bool get _hi =>
      search.isNotEmpty &&
      (prod.name.toLowerCase().contains(search) ||
          prod.sku.toLowerCase().contains(search));

  @override
  Widget build(BuildContext context) {
    final showSelected = moveMode && selected;
    final dotSize = showSelected ? 28.0 : (_hi ? 26.0 : 22.0);
    final hasMover = prod.movedByName != null && !showSelected;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width:  _kItemW,
        height: _kItemH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:  dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: showSelected ? _accent : prod.dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (showSelected ? _accent : prod.dotColor)
                          .withOpacity(showSelected ? 0.55 : 0.35),
                      blurRadius: showSelected ? 14 : (_hi ? 10 : 4),
                      spreadRadius: showSelected ? 3 : (_hi ? 2 : 0),
                    ),
                  ],
                  border: (showSelected || _hi)
                      ? Border.all(
                          color: Colors.white,
                          width: showSelected ? 3.0 : 2.5)
                      : null,
                ),
                child: showSelected
                    ? const Icon(Icons.open_with_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 5),
              Text(
                prod.tag,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: (showSelected || _hi)
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: showSelected
                      ? _accent
                      : _hi
                          ? _dark
                          : const Color(0xFF64748B),
                ),
              ),
            ]),
            // Tiny mover-initial badge (top-right of dot)
            if (hasMover)
              Positioned(
                top:   5.0,
                right: 19.0,
                child: Container(
                  width: 13, height: 13,
                  decoration: BoxDecoration(
                    color:  _roleColor(prod.movedByRole),
                    shape:  BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _roleColor(prod.movedByRole).withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      prod.movedByName![0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Product detail sheet ─────────────────────────────────────────────────────

class _ProdSheet extends StatelessWidget {
  final _Prod prod;
  final _Room room;
  final _Dept dept;
  const _ProdSheet(
      {required this.prod, required this.room, required this.dept});

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
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: prod.dotColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.devices_other,
                    color: prod.dotColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prod.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _dark)),
                      if (prod.sku.isNotEmpty)
                        Text(prod.sku,
                            style: const TextStyle(
                                fontSize: 12, color: _muted)),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: prod.dotColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: prod.dotColor)),
              ),
            ]),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 16, color: _muted),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(dept.code,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Text(room.name,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Text('· ${dept.name}',
                  style: const TextStyle(fontSize: 12, color: _muted)),
            ]),
            if (prod.movedByName != null) ...[
              const SizedBox(height: 16),
              _MoverRow(
                name:    prod.movedByName!,
                role:    prod.movedByRole,
                movedAt: prod.movedAt,
              ),
            ],
          ]),
    );
  }
}

// ─── Mover row ────────────────────────────────────────────────────────────────

class _MoverRow extends StatelessWidget {
  final String name;
  final String? role;
  final String? movedAt;

  const _MoverRow({required this.name, this.role, this.movedAt});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    final label = _roleLabel(role);
    final time  = movedAt != null ? _timeAgo(movedAt!) : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(children: [
        // User initial avatar
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:  color.withOpacity(0.14),
            shape:  BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('Moved by ',
                    style: TextStyle(fontSize: 11, color: _muted)),
                Flexible(
                  child: Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _dark)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
              ]),
              if (time.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(time,
                    style: const TextStyle(fontSize: 11, color: _muted)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.swap_horiz_rounded, size: 18, color: color.withOpacity(0.5)),
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(8)),
              child: Text(dept.code,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _dark)),
                    Text(dept.name,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('${room.products.length} items',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ]),
        ),
        const Divider(height: 24),
        Expanded(
          child: room.products.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inbox_outlined,
                        size: 52, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('No items in this room',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: room.products.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = room.products[i];
                    final sc = p.dotColor;
                    final sl = switch (p.status) {
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
                          child: Icon(Icons.devices_other,
                              size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _dark)),
                                if (p.sku.isNotEmpty)
                                  Text(p.sku,
                                      style: const TextStyle(
                                          fontSize: 11, color: _muted)),
                              ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: sc.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(sl,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: sc)),
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
  const _ZoomPanel(
      {required this.onIn, required this.onOut, required this.onReset});

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8)
              ],
            ),
            child: const Center(
              child: Text('1:1',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569))),
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
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8)
            ],
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
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? color : const Color(0xFFE2E8F0)),
            boxShadow: selected
                ? [BoxShadow(
                    color: color.withOpacity(0.25), blurRadius: 6)]
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 8)
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _LegendDot(const Color(0xFF22C55E), 'In Stock'),
          const SizedBox(width: 8),
          _LegendDot(const Color(0xFFF59E0B), 'Maintenance'),
          const SizedBox(width: 8),
          _LegendDot(const Color(0xFFEF4444), 'Critical'),
          const SizedBox(width: 8),
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
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500)),
      ]);
}
