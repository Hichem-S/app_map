import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/api_service.dart';

class LiveRoomCard extends StatelessWidget {
  final Room room;
  final Color deptColor;
  /// Called with the updated Room after a successful edit save.
  final ValueChanged<Room>? onRoomUpdated;
  /// Called when the card body is tapped (navigate to room items).
  final VoidCallback? onTap;

  const LiveRoomCard({
    super.key,
    required this.room,
    required this.deptColor,
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

  // ─── Edit room sheet ────────────────────────────────────────────────────────

  void _showEditSheet(BuildContext context) {
    final nameCtrl     = TextEditingController(text: room.name);
    final codeCtrl     = TextEditingController(text: room.roomCode ?? '');
    final blocCtrl     = TextEditingController(text: room.bloc ?? '');
    final floorCtrl    = TextEditingController(text: room.floor ?? '');
    final capacityCtrl = TextEditingController(
        text: room.capacity != null ? '${room.capacity}' : '');
    String selectedType = room.type;
    bool saving = false;

    final types = const [
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
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),

                  // Title
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: deptColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.edit_outlined, color: deptColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text('Modifier la salle',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Room name
                  _field('Nom de la salle', nameCtrl, deptColor),
                  const SizedBox(height: 12),

                  // Type selector
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
                            color: selected ? deptColor : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selected ? deptColor : Colors.grey[200]!),
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

                  // Code + Bloc side by side
                  Row(
                    children: [
                      Expanded(child: _field('Code salle (ex: I101)', codeCtrl, deptColor)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('Bloc (ex: Bloc A)', blocCtrl, deptColor)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Floor + Capacity side by side
                  Row(
                    children: [
                      Expanded(child: _field('Étage (ex: Étage 1)', floorCtrl, deptColor)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('Capacité (pers.)', capacityCtrl, deptColor,
                          keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deptColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving ? null : () async {
                        setSheet(() => saving = true);
                        try {
                          final cap = int.tryParse(capacityCtrl.text.trim());
                          final res = await ApiService.updateRoom(
                            room.id,
                            name:     nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                            type:     selectedType,
                            roomCode: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
                            bloc:     blocCtrl.text.trim().isEmpty ? null : blocCtrl.text.trim(),
                            floor:    floorCtrl.text.trim().isEmpty ? null : floorCtrl.text.trim(),
                            capacity: cap,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            if (res['success'] == true && onRoomUpdated != null) {
                              final updated = room.copyWith(
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
                              onRoomUpdated!(updated);
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    final typeLabel = _typeLabels[room.type] ?? room.type;
    final typeIcon  = _typeIcons[room.type]  ?? Icons.meeting_room_outlined;
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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR panel — tap to view dialog
            GestureDetector(
              onTap: () => showQrDialog(context, room, deptColor),
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  color: deptColor.withOpacity(0.06),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(18)),
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
                                child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5, color: deptColor))),
                        errorBuilder: (_, __, ___) => Container(
                          width: 62, height: 62,
                          decoration: BoxDecoration(
                              color: deptColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.qr_code_2, color: deptColor, size: 30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.zoom_in_rounded, size: 12, color: deptColor),
                        const SizedBox(width: 3),
                        Text('QR',
                            style: TextStyle(
                                fontSize: 11,
                                color: deptColor,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Details panel — tap to view room items
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Row(children: [
                        Icon(typeIcon, size: 12, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(typeLabel,
                            style: const TextStyle(fontSize: 12, color: Colors.black45)),
                      ]),
                      const SizedBox(height: 4),
                      // Room name
                      Row(
                        children: [
                          Expanded(
                            child: Text(room.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2340))),
                          ),
                          if (onTap != null)
                            Icon(Icons.chevron_right_rounded,
                                size: 18, color: Colors.black26),
                        ],
                      ),
                      // Subtitle: code · bloc · floor
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: const TextStyle(fontSize: 12, color: Colors.black45)),
                      ] else ...[
                        const SizedBox(height: 2),
                        Text('Appuyer ✏️ pour renseigner les détails',
                            style: TextStyle(fontSize: 11, color: Colors.grey[400],
                                fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 8),
                      // Equipment counts
                      if (room.productCount > 0)
                        Row(children: [
                          Text('${room.productCount} équip.',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          if (room.inStock > 0) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle_outline,
                                size: 14, color: Color(0xFF22C55E)),
                            const SizedBox(width: 2),
                            Text('${room.inStock}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.w600)),
                          ],
                          if (room.inMaintenance > 0) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.warning_amber_rounded,
                                size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text('${room.inMaintenance}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w600)),
                          ],
                          if (room.criticalIssue > 0) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.error_outline,
                                size: 14, color: Color(0xFFEF4444)),
                            const SizedBox(width: 2),
                            Text('${room.criticalIssue}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ])
                      else
                        Text('Vide',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      // Capacity
                      if (room.capacity != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.people_outline_rounded,
                              size: 13, color: Colors.black38),
                          const SizedBox(width: 4),
                          Text('Capacité: ${room.capacity} pers.',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45)),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Edit button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: GestureDetector(
                  onTap: () => _showEditSheet(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: deptColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_outlined, size: 16, color: deptColor),
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
