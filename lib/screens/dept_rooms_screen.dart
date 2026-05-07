import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/department.dart';
import '../models/room.dart';
import '../utils/app_colors.dart';
import 'room_items_screen.dart';

class DeptRoomsScreen extends StatefulWidget {
  final Department department;
  const DeptRoomsScreen({Key? key, required this.department}) : super(key: key);

  @override
  State<DeptRoomsScreen> createState() => _DeptRoomsScreenState();
}

class _DeptRoomsScreenState extends State<DeptRoomsScreen> {
  List<Room> _rooms = [];
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
      final raw = await ApiService.getDepartmentRooms(widget.department.id);
      setState(() {
        _rooms = raw.map((r) => Room.fromJson(r as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dept = widget.department;
    final color = dept.flutterColor;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dept.code,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(dept.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        // QR code image for this dept
                        GestureDetector(
                          onTap: () => _showQR(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_2, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _chip(Icons.meeting_room_outlined, '${dept.roomCount} salles'),
                        const SizedBox(width: 10),
                        _chip(Icons.inventory_2_outlined, '${dept.productCount} équipements'),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // Rooms list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _rooms.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.meeting_room_outlined, size: 56, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text('No rooms found', style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: color,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _rooms.length,
                              itemBuilder: (ctx, i) => _RoomCard(
                                room: _rooms[i],
                                deptColor: color,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RoomItemsScreen(
                                      room: _rooms[i],
                                      department: dept,
                                    ),
                                  ),
                                ),
                                onQr: () => _showRoomQrDialog(context, _rooms[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showRoomQrDialog(BuildContext context, Room room) {
    final color = widget.department.flutterColor;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.meeting_room_outlined, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(widget.department.code,
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  ApiService.roomQrUrl(room.id),
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : Center(child: CircularProgressIndicator(color: color)),
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 32)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('ISET://room/${room.id}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download'),
            onPressed: () async {
              final path = await ApiService.saveRoomQrLocally(room.id, room.name);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(path != null ? 'Saved: ${path.split('/').last}' : 'Failed to save QR'),
                  backgroundColor: path != null ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  void _showQR(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('QR — ${widget.department.name}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 240,
          height: 240,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              ApiService.departmentQrUrl(widget.department.id),
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.error_outline, color: Colors.red)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ─── Room card ────────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  final Room room;
  final Color deptColor;
  final VoidCallback onTap;
  final VoidCallback onQr;

  const _RoomCard({required this.room, required this.deptColor, required this.onTap, required this.onQr});

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

  @override
  Widget build(BuildContext context) {
    final typeLabel = _typeLabels[room.type] ?? room.type;
    final typeIcon  = _typeIcons[room.type]  ?? Icons.meeting_room_outlined;

    // subtitle line: code · bloc · floor
    final parts = <String>[
      if (room.roomCode != null && room.roomCode!.isNotEmpty) room.roomCode!,
      if (room.bloc != null && room.bloc!.isNotEmpty) room.bloc!,
      if (room.floor != null && room.floor!.isNotEmpty) room.floor!,
    ];
    final subtitle = parts.join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── QR panel ───────────────────────────────────────────────────
              GestureDetector(
                onTap: onQr,
                child: Container(
                  width: 90,
                  decoration: BoxDecoration(
                    color: deptColor.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    border: Border(right: BorderSide(color: deptColor.withValues(alpha: 0.12))),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ApiService.roomQrUrl(room.id),
                          width: 64, height: 64, fit: BoxFit.cover,
                          loadingBuilder: (_, child, p) => p == null
                              ? child
                              : SizedBox(
                                  width: 64, height: 64,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: deptColor)),
                                ),
                          errorBuilder: (_, __, ___) => Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: deptColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.qr_code_2, color: deptColor, size: 32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, size: 12, color: deptColor),
                          const SizedBox(width: 3),
                          Text('QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: deptColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Details panel ──────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Row(
                        children: [
                          Icon(typeIcon, size: 12, color: deptColor.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(typeLabel,
                              style: TextStyle(fontSize: 11, color: deptColor.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Room name
                      Text(room.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textH),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 6),
                      // Equipment count + status icons
                      _EquipRow(room: room, deptColor: deptColor),
                      // Capacity
                      if (room.capacity != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 13, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text('Capacité: ${room.capacity} pers.',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Chevron
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(child: Icon(Icons.chevron_right, color: Colors.grey[350], size: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipRow extends StatelessWidget {
  final Room room;
  final Color deptColor;
  const _EquipRow({required this.room, required this.deptColor});

  @override
  Widget build(BuildContext context) {
    if (room.productCount == 0) {
      return Text('Vide', style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500));
    }
    return Row(
      children: [
        Text('${room.productCount} équip.',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        if (room.inStock > 0) ...[
          const SizedBox(width: 6),
          _badge(Icons.check_circle, '${room.inStock}', const Color(0xFF10B981)),
        ],
        if (room.inMaintenance > 0) ...[
          const SizedBox(width: 4),
          _badge(Icons.warning_amber_rounded, '${room.inMaintenance}', const Color(0xFFF59E0B)),
        ],
        if (room.criticalIssue > 0) ...[
          const SizedBox(width: 4),
          _badge(Icons.error_outline, '${room.criticalIssue}', const Color(0xFFEF4444)),
        ],
        if (room.retired > 0) ...[
          const SizedBox(width: 4),
          _badge(Icons.archive_outlined, '${room.retired}', const Color(0xFF9CA3AF)),
        ],
      ],
    );
  }

  Widget _badge(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      );
}
