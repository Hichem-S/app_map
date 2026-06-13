import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class _Prod {
  final String id, name, sku, status;
  _Prod({required this.id, required this.name, required this.sku, required this.status});

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

  String get statusLabel => switch (status) {
        'in_stock'       => 'In Stock',
        'in_maintenance' => 'Maintenance',
        'critical_issue' => 'Critical',
        _                => 'Retired',
      };
}

class _Room {
  final String id, name, type;
  final int count, inStock, inMaintenance, critical;
  final List<_Prod> products;

  _Room({
    required this.id,
    required this.name,
    required this.type,
    required this.count,
    required this.inStock,
    required this.inMaintenance,
    required this.critical,
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
      count:         int.tryParse(j['product_count']?.toString() ?? '0') ?? 0,
      inStock:       int.tryParse(j['in_stock']?.toString() ?? '0') ?? 0,
      inMaintenance: int.tryParse(j['in_maintenance']?.toString() ?? '0') ?? 0,
      critical:      int.tryParse(j['critical_issue']?.toString() ?? '0') ?? 0,
      products:      prods,
    );
  }

  Color get statusColor {
    if (critical > 0)      return const Color(0xFFEF4444);
    if (inMaintenance > 0) return const Color(0xFFF59E0B);
    if (inStock > 0)       return const Color(0xFF22C55E);
    return const Color(0xFF94A3B8);
  }
}

class _Dept {
  final String id, code, name;
  final Color color;
  final List<_Room> rooms;
  int get total => rooms.fold(0, (s, r) => s + r.count);

  _Dept({required this.id, required this.code, required this.name,
         required this.color, required this.rooms});

  factory _Dept.fromJson(Map j) {
    final hex = (j['color']?.toString() ?? '#6366F1').replaceAll('#', '').padLeft(6, '0');
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

// ─── Isometric constants & geometry ──────────────────────────────────────────

const _tw = 210.0;   // tile width
const _th = 105.0;   // tile height = tw / 2
const _wh = 72.0;    // wall height
const _ox = 420.0;   // origin x
const _oy = 55.0;    // origin y
const _cw = 860.0;   // canvas width
const _ch = 530.0;   // canvas height

const _kGrid = <String, List<int>>{
  'I': [0, 0], 'M': [1, 0], 'G': [2, 0],
  'E': [0, 1], 'TC': [1, 1], 'ADM': [2, 1],
};

Offset _apex(int col, int row) => Offset(
  _ox + (col - row) * _tw / 2,
  _oy + (col + row) * _th / 2,
);

// Place a sub-cell (c, r) on the top face using isometric parametric coordinates
Offset _cellPos(Offset apex, int c, int r, int cols, int rows) {
  final u = 0.18 + (c + 0.5) / cols * 0.64;
  final v = 0.18 + (r + 0.5) / rows * 0.64;
  return Offset(
    apex.dx + (u - v) * _tw / 2,
    apex.dy + (u + v) * _th / 2,
  );
}

// Full isometric block silhouette for hit testing
Path _blockPath(Offset a) => Path()
  ..addPolygon([
    a,
    a + Offset(_tw / 2, _th / 2),
    a + Offset(_tw / 2, _th / 2 + _wh),
    a + Offset(0, _th + _wh),
    a + Offset(-_tw / 2, _th / 2 + _wh),
    a + Offset(-_tw / 2, _th / 2),
  ], true);

Color _cTop(Color c) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + 0.22).clamp(0.0, 1.0)).toColor();
}
Color _cLeft(Color c) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - 0.04).clamp(0.0, 1.0)).toColor();
}
Color _cRight(Color c) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - 0.20).clamp(0.0, 1.0)).toColor();
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class Product3DMapScreen extends StatefulWidget {
  const Product3DMapScreen({Key? key}) : super(key: key);
  @override
  State<Product3DMapScreen> createState() => _Product3DMapScreenState();
}

class _Product3DMapScreenState extends State<Product3DMapScreen> {
  List<_Dept> _depts  = [];
  bool        _loading = true;
  String?     _selId;
  final       _txCtrl  = TransformationController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _txCtrl.dispose(); super.dispose(); }

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

  int get _total => _depts.fold(0, (s, d) => s + d.total);

  Map<String, List<int>> _buildGrid() {
    final m = <String, List<int>>{};
    int fb = 0;
    for (final d in _depts) {
      m[d.code] = _kGrid.containsKey(d.code) ? _kGrid[d.code]! : [fb % 3, fb++ ~/ 3];
    }
    return m;
  }

  void _onTap(Offset pos) {
    final g = _buildGrid();
    // Test front-to-back
    final sorted = [..._depts]..sort((a, b) {
      final ga = g[a.code] ?? [0, 0];
      final gb = g[b.code] ?? [0, 0];
      return (gb[0] + gb[1]).compareTo(ga[0] + ga[1]);
    });
    for (final d in sorted) {
      final gp = g[d.code];
      if (gp == null) continue;
      if (_blockPath(_apex(gp[0], gp[1])).contains(pos)) {
        _openDept(d);
        return;
      }
    }
  }

  void _openDept(_Dept dept) {
    setState(() => _selId = dept.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeptSheet(dept: dept),
    ).then((_) { if (mounted) setState(() => _selId = null); });
  }

  void _scale(double f) => _txCtrl.value = _txCtrl.value.clone()..scale(f);

  @override
  Widget build(BuildContext context) {
    final g = _buildGrid();
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: Stack(children: [
            if (_loading)
              const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            else if (_depts.isEmpty)
              const Center(
                  child: Text('No departments', style: TextStyle(color: Color(0xFF94A3B8))))
            else
              InteractiveViewer(
                transformationController: _txCtrl,
                minScale: 0.28,
                maxScale: 3.5,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(220),
                child: GestureDetector(
                  onTapDown: (d) => _onTap(d.localPosition),
                  child: CustomPaint(
                    size: const Size(_cw, _ch),
                    painter: _IsoPainter(depts: _depts, grid: g, selId: _selId),
                  ),
                ),
              ),
            // Zoom controls
            Positioned(
              right: 14, top: 0, bottom: 0,
              child: Center(child: _ZoomPanel(
                onIn:    () => _scale(1.25),
                onOut:   () => _scale(0.8),
                onReset: () => _txCtrl.value = Matrix4.identity(),
              )),
            ),
            // Legend
            Positioned(
              bottom: 16, left: 0, right: 0,
              child: Center(child: _Legend()),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('3D Facility Map',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('ISET · ${_depts.length} departments · $_total equipment markers',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
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
              icon: const Icon(Icons.refresh, color: Color(0xFF64748B), size: 20),
              onPressed: _load,
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Isometric painter ────────────────────────────────────────────────────────

class _IsoPainter extends CustomPainter {
  final List<_Dept> depts;
  final Map<String, List<int>> grid;
  final String? selId;

  const _IsoPainter({required this.depts, required this.grid, this.selId});

  @override
  void paint(Canvas canvas, Size size) {
    _drawFloor(canvas, size);

    // Back to front: lower (col+row) first
    final order = [...depts]..sort((a, b) {
      final ga = grid[a.code] ?? [0, 0];
      final gb = grid[b.code] ?? [0, 0];
      final sa = ga[0] + ga[1], sb = gb[0] + gb[1];
      return sa != sb ? sa.compareTo(sb) : ga[1].compareTo(gb[1]);
    });

    for (final d in order) {
      final p = grid[d.code];
      if (p == null) continue;
      _paintBlock(canvas, d, p[0], p[1], d.id == selId);
    }
  }

  void _drawFloor(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0F172A));
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 0.8;
    final stepX = _tw / 2;
    final stepY = _th / 2;
    final ratio = stepX / stepY;
    for (double s = -_cw; s < _cw * 2; s += stepX) {
      canvas.drawLine(Offset(s, 0), Offset(s + size.height * ratio, size.height), paint);
      canvas.drawLine(Offset(s, 0), Offset(s - size.height * ratio, size.height), paint);
    }
  }

  void _paintBlock(Canvas canvas, _Dept dept, int col, int row, bool sel) {
    final a     = _apex(col, row);
    final color = dept.color;

    final vTop    = a;
    final vRight  = a + Offset(_tw / 2,  _th / 2);
    final vBottom = a + Offset(0,         _th);
    final vLeft   = a + Offset(-_tw / 2,  _th / 2);
    final vLeftBL = a + Offset(-_tw / 2,  _th / 2 + _wh);
    final vBottomB= a + Offset(0,          _th + _wh);
    final vRightBR= a + Offset(_tw / 2,   _th / 2 + _wh);

    final stroke = Paint()
      ..color = sel ? Colors.white.withOpacity(0.9) : color.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sel ? 1.8 : 1.0;

    // Right wall
    canvas.drawPath(
        Path()..addPolygon([vBottom, vRight, vRightBR, vBottomB], true),
        Paint()..color = _cRight(color));
    canvas.drawPath(Path()..addPolygon([vBottom, vRight, vRightBR, vBottomB], true), stroke);

    // Left wall
    canvas.drawPath(
        Path()..addPolygon([vLeft, vBottom, vBottomB, vLeftBL], true),
        Paint()..color = _cLeft(color));
    canvas.drawPath(Path()..addPolygon([vLeft, vBottom, vBottomB, vLeftBL], true), stroke);

    // Top face
    final topPath = Path()..addPolygon([vTop, vRight, vBottom, vLeft], true);
    canvas.drawPath(topPath, Paint()..color = _cTop(color));
    if (sel) {
      canvas.drawPath(topPath,
          Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.fill);
    }
    canvas.drawPath(topPath, stroke);

    // Room dots
    final rooms = dept.rooms.take(9).toList();
    if (rooms.isNotEmpty) {
      final cols = rooms.length <= 3 ? rooms.length : 3;
      final rows = (rooms.length / 3).ceil();
      for (int i = 0; i < rooms.length; i++) {
        _paintRoomDot(canvas, rooms[i], _cellPos(a, i % 3, i ~/ 3, cols, rows));
      }
    }

    // Dept code
    final center = a + Offset(0, _th / 2);
    _drawText(canvas, dept.code, center + const Offset(0, -9),
        const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900,
            shadows: [Shadow(blurRadius: 6, color: Colors.black54)]));

    // Item count badge
    if (dept.total > 0) {
      _drawBadge(canvas, '${dept.total} items', center + const Offset(0, 9), color);
    }

    // Dept name below block
    _drawText(canvas, dept.name, a + Offset(0, _th + _wh + 14),
        TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black)]));
  }

  void _paintRoomDot(Canvas canvas, _Room room, Offset pos) {
    final c = room.critical > 0
        ? const Color(0xFFEF4444)
        : room.inMaintenance > 0
            ? const Color(0xFFF59E0B)
            : room.inStock > 0
                ? const Color(0xFF22C55E)
                : const Color(0xFF94A3B8);
    // Glow
    canvas.drawCircle(pos, 9,
        Paint()..color = c.withOpacity(0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // White ring
    canvas.drawCircle(pos, 8, Paint()..color = Colors.white.withOpacity(0.85));
    // Color fill
    canvas.drawCircle(pos, 7, Paint()..color = c);
    // Initial letter
    if (room.name.isNotEmpty) {
      _drawText(canvas, room.name[0].toUpperCase(), pos,
          const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900));
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawBadge(Canvas canvas, String text, Offset center, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: _cTop(color), fontSize: 9, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: tp.width + 14, height: tp.height + 6),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.black45);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_IsoPainter old) => old.depts != depts || old.selId != selId;
}

// ─── Department sheet ─────────────────────────────────────────────────────────

class _DeptSheet extends StatefulWidget {
  final _Dept dept;
  const _DeptSheet({required this.dept});
  @override
  State<_DeptSheet> createState() => _DeptSheetState();
}

class _DeptSheetState extends State<_DeptSheet> {
  _Room? _openRoom;

  @override
  Widget build(BuildContext context) {
    final dept  = widget.dept;
    final color = dept.color;
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
              margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFF475569), borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Text(dept.code,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dept.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('${dept.rooms.length} rooms · ${dept.total} items',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ])),
            ]),
          ),
          const Divider(height: 24, color: Color(0xFF334155)),
          if (_openRoom == null) _buildRoomGrid(dept, color) else _buildProductList(_openRoom!, color),
        ]),
      ),
    );
  }

  Widget _buildRoomGrid(_Dept dept, Color color) {
    if (dept.rooms.isEmpty) {
      return Padding(padding: const EdgeInsets.all(32),
          child: Center(child: Text('No rooms', style: TextStyle(color: Colors.grey[600]))));
    }
    return Flexible(
      child: GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2),
        itemCount: dept.rooms.length,
        itemBuilder: (_, i) => _RoomCard(
            room: dept.rooms[i], color: color,
            onTap: () => setState(() => _openRoom = dept.rooms[i])),
      ),
    );
  }

  Widget _buildProductList(_Room room, Color color) {
    return Flexible(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() => _openRoom = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
              child: Text(room.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text('${room.count} items', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFF334155)),
        if (room.products.isEmpty)
          Padding(padding: const EdgeInsets.all(32),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[700]),
                const SizedBox(height: 8),
                Text('No items here', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ])))
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: room.products.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF334155)),
              itemBuilder: (_, i) {
                final p = room.products[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: p.dotColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.devices_other, size: 17, color: p.dotColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      if (p.sku.isNotEmpty)
                        Text(p.sku, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: p.dotColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(p.statusLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.dotColor)),
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

// ─── Room card ────────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  final _Room room;
  final Color color;
  final VoidCallback onTap;
  const _RoomCard({required this.room, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.25))),
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: room.statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('${room.count} items',
                  style: TextStyle(fontSize: 10, color: color.withOpacity(0.7), fontWeight: FontWeight.w500)),
            ])),
            const Icon(Icons.chevron_right, size: 14, color: Color(0xFF475569)),
          ]),
        ),
      );
}

// ─── Zoom panel ───────────────────────────────────────────────────────────────

class _ZoomPanel extends StatelessWidget {
  final VoidCallback onIn, onOut, onReset;
  const _ZoomPanel({required this.onIn, required this.onOut, required this.onReset});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        _ZBtn(icon: Icons.add, onTap: onIn),
        const SizedBox(height: 8),
        _ZBtn(icon: Icons.remove, onTap: onOut),
        const SizedBox(height: 8),
        _ZBtn(label: '1:1', onTap: onReset),
      ]);
}

class _ZBtn extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onTap;
  const _ZBtn({this.icon, this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)]),
          child: icon != null
              ? Icon(icon, size: 20, color: Colors.white70)
              : Center(child: Text(label!,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70))),
        ),
      );
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF334155))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _LDot(const Color(0xFF22C55E), 'In Stock'),
          const SizedBox(width: 8),
          _LDot(const Color(0xFFF59E0B), 'Maintenance'),
          const SizedBox(width: 8),
          _LDot(const Color(0xFFEF4444), 'Critical'),
          const SizedBox(width: 8),
          _LDot(const Color(0xFF94A3B8), 'Retired'),
        ]),
      );
}

class _LDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LDot(this.color, this.label);
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
      ]);
}
