import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../screens/room_items_screen.dart';
import '../models/department.dart';

class LiveRoomCard extends StatefulWidget {
  final Room room;
  final Color deptColor;
  final Department? department;
  final ValueChanged<Room>? onRoomUpdated;
  final VoidCallback? onTap;

  const LiveRoomCard({
    super.key,
    required this.room,
    required this.deptColor,
    this.department,
    this.onRoomUpdated,
    this.onTap,
  });

  static const _typeLabels = {
    'laboratory':  'Laboratoire',
    'classroom':   'Salle de cours',
    'office':      'Bureau',
    'storage':     'Stockage',
    'workshop':    'Atelier',
    'server_room': 'Salle Serveurs',
  };
  static const _typeIcons = {
    'laboratory':  Icons.biotech_outlined,
    'classroom':   Icons.school_outlined,
    'office':      Icons.work_outline,
    'storage':     Icons.inventory_2_outlined,
    'workshop':    Icons.construction_outlined,
    'server_room': Icons.dns_outlined,
  };

  // ─── QR dialog ─────────────────────────────────────────────────────────────

  static void showQrDialog(BuildContext context, Room room, Color deptColor) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: deptColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.meeting_room_outlined, color: deptColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(room.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ApiService.roomQrUrl(room.id),
                  width: 220, height: 220, fit: BoxFit.contain,
                  loadingBuilder: (_, child, p) => p == null
                      ? child
                      : SizedBox(
                          width: 220, height: 220,
                          child: Center(child: CircularProgressIndicator(color: deptColor))),
                  errorBuilder: (_, __, ___) => const SizedBox(
                      width: 220, height: 220,
                      child: Center(child: Icon(Icons.error_outline, color: Colors.red, size: 40))),
                ),
              ),
              const SizedBox(height: 8),
              Text('ISET://room/${room.id}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final path = await ApiService.saveRoomQrLocally(room.id, room.name);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(path != null
                            ? 'Saved: ${path.split('/').last}'
                            : 'Failed to save QR'),
                        backgroundColor: path != null ? Colors.green : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deptColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  State<LiveRoomCard> createState() => _LiveRoomCardState();
}

class _LiveRoomCardState extends State<LiveRoomCard> {
  bool _expanded = false;
  bool _loadingItems = false;
  List<Product> _items = [];

  Future<void> _toggleExpand() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    setState(() { _expanded = true; _loadingItems = true; });
    try {
      final res = await ApiService.getProducts(roomId: widget.room.id, limit: 100);
      final rows = (res['data'] as List<dynamic>? ?? [])
          .map((r) => Product.fromJson(r as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _items = rows; _loadingItems = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingItems = false; });
    }
  }

  void _openFullScreen(BuildContext context) {
    final dept = widget.department ??
        Department(
          id: '',
          code: '?',
          name: widget.room.name,
          color: widget.deptColor.value.toRadixString(16).padLeft(8, '0').substring(2),
        );
    final target = widget.onTap;
    if (target != null) {
      target();
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => RoomItemsScreen(room: widget.room, department: dept),
      ));
    }
  }

  // ─── Edit room sheet ────────────────────────────────────────────────────────

  void _showEditSheet(BuildContext context) {
    final nameCtrl     = TextEditingController(text: widget.room.name);
    final codeCtrl     = TextEditingController(text: widget.room.roomCode ?? '');
    final blocCtrl     = TextEditingController(text: widget.room.bloc ?? '');
    final floorCtrl    = TextEditingController(text: widget.room.floor ?? '');
    final capacityCtrl = TextEditingController(
        text: widget.room.capacity != null ? '${widget.room.capacity}' : '');
    String selectedType = widget.room.type;
    bool saving = false;

    const types = [
      ('classroom',   'Salle de cours',  Icons.school_outlined),
      ('laboratory',  'Laboratoire',     Icons.biotech_outlined),
      ('office',      'Bureau',          Icons.work_outline),
      ('storage',     'Stockage',        Icons.inventory_2_outlined),
      ('workshop',    'Atelier',         Icons.construction_outlined),
      ('server_room', 'Salle Serveurs',  Icons.dns_outlined),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: widget.deptColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.edit_outlined, color: widget.deptColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text('Modifier la salle',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _field('Nom de la salle', nameCtrl, widget.deptColor),
                  const SizedBox(height: 12),
                  const Text('Type', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: types.map((t) {
                      final selected = selectedType == t.$1;
                      return GestureDetector(
                        onTap: () => setSheet(() => selectedType = t.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? widget.deptColor : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? widget.deptColor : Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.$3, size: 14,
                                  color: selected ? Colors.white : Colors.grey[600]),
                              const SizedBox(width: 5),
                              Text(t.$2,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected ? Colors.white : Colors.grey[700])),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field('Code salle (ex: I101)', codeCtrl, widget.deptColor)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('Bloc (ex: Bloc A)', blocCtrl, widget.deptColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field('Étage (ex: Étage 1)', floorCtrl, widget.deptColor)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('Capacité (pers.)', capacityCtrl, widget.deptColor,
                          keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.deptColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving ? null : () async {
                        setSheet(() => saving = true);
                        try {
                          final cap = int.tryParse(capacityCtrl.text.trim());
                          final res = await ApiService.updateRoom(
                            widget.room.id,
                            name:     nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                            type:     selectedType,
                            roomCode: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                            bloc:     blocCtrl.text.trim().isEmpty ? null : blocCtrl.text.trim(),
                            floor:    floorCtrl.text.trim().isEmpty ? null : floorCtrl.text.trim(),
                            capacity: cap,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            if (res['success'] == true && widget.onRoomUpdated != null) {
                              final updated = widget.room.copyWith(
                                name:     nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                                type:     selectedType,
                                roomCode: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                                bloc:     blocCtrl.text.trim().isEmpty ? null : blocCtrl.text.trim(),
                                floor:    floorCtrl.text.trim().isEmpty ? null : floorCtrl.text.trim(),
                                capacity: cap,
                                clearRoomCode: codeCtrl.text.trim().isEmpty,
                                clearBloc:     blocCtrl.text.trim().isEmpty,
                                clearFloor:    floorCtrl.text.trim().isEmpty,
                                clearCapacity: cap == null,
                              );
                              widget.onRoomUpdated!(updated);
                            }
                          }
                        } catch (e) {
                          setSheet(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        }
                      },
                      child: saving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Enregistrer',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _field(String label, TextEditingController ctrl, Color color,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color, width: 1.5)),
          ),
        ),
      ],
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final room      = widget.room;
    final color     = widget.deptColor;
    final typeLabel = LiveRoomCard._typeLabels[room.type] ?? room.type;
    final typeIcon  = LiveRoomCard._typeIcons[room.type]  ?? Icons.meeting_room_outlined;
    final subtitle  = [
      if (room.roomCode != null && room.roomCode!.isNotEmpty) room.roomCode!,
      if (room.bloc != null && room.bloc!.isNotEmpty) room.bloc!,
      if (room.floor != null && room.floor!.isNotEmpty) room.floor!,
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // ── Main row ──────────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // QR panel
                GestureDetector(
                  onTap: () => LiveRoomCard.showQrDialog(context, room, color),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.06),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        bottomLeft: Radius.circular(_expanded ? 0 : 18),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiService.roomQrUrl(room.id),
                            width: 62, height: 62, fit: BoxFit.cover,
                            loadingBuilder: (_, child, p) => p == null
                                ? child
                                : SizedBox(
                                    width: 62, height: 62,
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: color))),
                            errorBuilder: (_, __, ___) => Container(
                              width: 62, height: 62,
                              decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.qr_code_2, color: color, size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.zoom_in_rounded, size: 12, color: color),
                            const SizedBox(width: 3),
                            Text('QR', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Details panel
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openFullScreen(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(typeIcon, size: 12, color: Colors.black45),
                            const SizedBox(width: 4),
                            Text(typeLabel, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            Expanded(
                              child: Text(room.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A2340))),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.black26),
                          ]),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                          ] else ...[
                            const SizedBox(height: 2),
                            Text('Appuyer ✏️ pour renseigner les détails',
                                style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 8),
                          if (room.productCount > 0)
                            Row(children: [
                              Text('${room.productCount} équip.',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              if (room.inStock > 0) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF22C55E)),
                                const SizedBox(width: 2),
                                Text('${room.inStock}', style: const TextStyle(fontSize: 12, color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                              ],
                              if (room.inMaintenance > 0) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 2),
                                Text('${room.inMaintenance}', style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                              ],
                              if (room.criticalIssue > 0) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444)),
                                const SizedBox(width: 2),
                                Text('${room.criticalIssue}', style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                              ],
                            ])
                          else
                            Text('Vide', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                          if (room.capacity != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.people_outline_rounded, size: 13, color: Colors.black38),
                              const SizedBox(width: 4),
                              Text('Capacité: ${room.capacity} pers.', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Right buttons column
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Edit
                      GestureDetector(
                        onTap: () => _showEditSheet(context),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.edit_outlined, size: 16, color: color),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Expand toggle (only if has items)
                      if (room.productCount > 0)
                        GestureDetector(
                          onTap: _toggleExpand,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: _expanded ? color.withOpacity(0.15) : color.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AnimatedRotation(
                              turns: _expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: color),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Expanded items list ────────────────────────────────────────────
          if (_expanded) _buildItemsList(color),
        ],
      ),
    );
  }

  Widget _buildItemsList(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        border: Border(top: BorderSide(color: color.withOpacity(0.12))),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadingItems)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text('Aucun équipement trouvé',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ),
            )
          else ...[
            ..._items.take(6).map((item) => _ItemRow(item: item, color: color)),
            if (_items.length > 6) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _openFullScreen(context),
                child: Center(
                  child: Text(
                    'Voir les ${_items.length} équipements →',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _openFullScreen(context),
                child: Center(
                  child: Text(
                    'Voir le détail →',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Single item row inside expanded section ──────────────────────────────────

class _ItemRow extends StatelessWidget {
  final Product item;
  final Color color;
  const _ItemRow({required this.item, required this.color});

  static const _statusColors = {
    'in_stock':       Color(0xFF10B981),
    'in_maintenance': Color(0xFFF59E0B),
    'critical_issue': Color(0xFFEF4444),
    'retired':        Color(0xFF9CA3AF),
  };
  static const _statusBg = {
    'in_stock':       Color(0xFFE6F9F2),
    'in_maintenance': Color(0xFFFFF8E6),
    'critical_issue': Color(0xFFFFEEEE),
    'retired':        Color(0xFFF3F4F6),
  };
  static const _statusLabels = {
    'in_stock':       'En stock',
    'in_maintenance': 'Maintenance',
    'critical_issue': 'Critique',
    'retired':        'Retraité',
  };
  static const _statusIcons = {
    'in_stock':       Icons.check_circle_outline,
    'in_maintenance': Icons.build_outlined,
    'critical_issue': Icons.warning_amber_outlined,
    'retired':        Icons.archive_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final sColor = _statusColors[item.status] ?? const Color(0xFF6B7280);
    final sBg    = _statusBg[item.status]     ?? const Color(0xFFF3F4F6);
    final sIcon  = _statusIcons[item.status]  ?? Icons.help_outline;
    final sLabel = _statusLabels[item.status] ?? item.status;
    final baseHost = ApiService.baseUrl.replaceAll('/api', '');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: item.photoUrl != null
                ? Image.network(
                    '$baseHost${item.photoUrl}',
                    width: 36, height: 36, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumb(),
                  )
                : _thumb(),
          ),
          const SizedBox(width: 10),
          // Name + SKU
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2340))),
                Text(item.sku,
                    style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: sBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(sIcon, size: 10, color: sColor),
                const SizedBox(width: 3),
                Text(sLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb() => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(7)),
        child: const Icon(Icons.devices_other, color: Color(0xFF818CF8), size: 18),
      );
}
