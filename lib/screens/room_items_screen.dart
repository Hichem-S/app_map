import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';
import '../services/notification_service.dart';
import '../models/product.dart';
import '../models/room.dart';
import '../models/department.dart';
import '../utils/app_colors.dart';

class RoomItemsScreen extends StatefulWidget {
  final Room room;
  final Department department;

  const RoomItemsScreen({Key? key, required this.room, required this.department}) : super(key: key);

  @override
  State<RoomItemsScreen> createState() => _RoomItemsScreenState();
}

class _RoomItemsScreenState extends State<RoomItemsScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  // For move-to-room sheet
  List<dynamic> _departments = [];

  // WebSocket
  StreamSubscription? _wsSub;
  OverlayEntry? _notifOverlay;

  static const _statusLabels  = {'operational': 'Operational', 'in_stock': 'In Stock', 'in_maintenance': 'Maintenance', 'critical_issue': 'Critical', 'retired': 'Retired', 'lost': 'Lost'};
  static const _statusColors  = {'operational': Color(0xFF4F46E5), 'in_stock': Color(0xFF10B981), 'in_maintenance': Color(0xFFF59E0B), 'critical_issue': Color(0xFFEF4444), 'retired': Color(0xFF6B7280), 'lost': Color(0xFF8B5CF6)};
  static const _statusBg      = {'operational': Color(0xFFEEF2FF), 'in_stock': Color(0xFFE6F9F2), 'in_maintenance': Color(0xFFFFF8E6), 'critical_issue': Color(0xFFFFEEEE), 'retired': Color(0xFFF3F4F6), 'lost': Color(0xFFF3E8FF)};
  static const _statusIcons   = {'operational': Icons.check_circle, 'in_stock': Icons.inventory_2, 'in_maintenance': Icons.build, 'critical_issue': Icons.warning_amber, 'retired': Icons.archive, 'lost': Icons.search_off};

  @override
  void initState() {
    super.initState();
    _load();
    _loadDepts();
    _subscribeWs();
  }

  void _subscribeWs() {
    _wsSub = WsService.stream.listen((event) {
      try {
        final msg = jsonDecode(event as String) as Map<String, dynamic>;
        if (msg['type'] == 'product_moved') _onProductMoved(msg);
      } catch (_) {}
    });
  }

  void _onProductMoved(Map<String, dynamic> msg) {
    if (!mounted) return;
    final name     = msg['productName'] as String? ?? 'Équipement';
    final fromRoom = msg['fromRoom']    as String?;
    final toRoom   = msg['toRoom']      as String? ?? 'â€”';
    final color    = widget.department.flutterColor;

    _notifOverlay?.remove();
    _notifOverlay = _buildNotifOverlay(name, fromRoom, toRoom, color);
    Overlay.of(context).insert(_notifOverlay!);

    Future.delayed(const Duration(seconds: 4), () {
      _notifOverlay?.remove();
      _notifOverlay = null;
    });
  }

  OverlayEntry _buildNotifOverlay(
      String name, String? from, String to, Color color) {
    return OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: _MoveNotifBanner(
          productName: name,
          fromRoom: from,
          toRoom: to,
          color: color,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _notifOverlay?.remove();
    super.dispose();
  }

  Future<void> _loadDepts() async {
    try {
      final depts = await ApiService.getDepartments();
      if (mounted) setState(() => _departments = depts);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getProducts(roomId: widget.room.id, limit: 200);
      if (!mounted) return;
      final rows = (res['data'] as List<dynamic>? ?? [])
          .map((r) => Product.fromJson(r as Map<String, dynamic>))
          .toList();
      setState(() { _products = rows; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _downloadPdf(String type, Color color) async {
    final label = type == 'fiche' ? 'Fiche inventaire' : 'Journal de traçabilité';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Génération du $label en cours…'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
    try {
      final path = type == 'fiche'
          ? await ApiService.downloadRoomFiche(widget.room.id, widget.room.name)
          : await ApiService.downloadRoomJournal(widget.room.id, widget.room.name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(path != null
            ? '$label enregistré : ${path.split('/').last}'
            : 'Échec du téléchargement'),
        backgroundColor: path != null ? color : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildActionBar(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.card(context),
      child: Row(
        children: [
          Expanded(
            child: _pdfButton(
              icon: Icons.description_outlined,
              label: 'Fiche inventaire',
              color: color,
              onTap: () => _downloadPdf('fiche', color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _pdfButton(
              icon: Icons.history_edu_outlined,
              label: 'Journal traçabilité',
              color: color,
              onTap: () => _downloadPdf('journal', color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _pdfButton(
              icon: Icons.domain_outlined,
              label: 'Rapport dept',
              color: color,
              onTap: () => _downloadDeptReport(color),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadDeptReport(Color color) async {
    final dept = widget.department;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Generating department report…'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
    try {
      final path = await ApiService.downloadDeptReport(dept.id, dept.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(path != null ? 'Saved: ${path.split('/').last}' : 'Download failed'),
        backgroundColor: path != null ? color : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {}
  }

  Widget _pdfButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.download_rounded, size: 14, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoveSheet(Product product) async {
    String? selectedDeptId;
    String? selectedDeptName;
    List<dynamic> rooms = [];
    String? selectedRoomId;
    String? selectedRoomName;
    bool roomsLoading = false;
    bool moving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> loadRooms(String deptId) async {
            setSheet(() { roomsLoading = true; rooms = []; selectedRoomId = null; selectedRoomName = null; });
            try {
              final list = await ApiService.getDepartmentRooms(deptId);
              setSheet(() { rooms = list; roomsLoading = false; });
            } catch (_) {
              setSheet(() { roomsLoading = false; });
            }
          }

          return Container(
            margin: const EdgeInsets.only(top: 60),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text('Move "${product.name}"',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text('Select a destination room',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ),

                // Department picker
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: InputBorder.none,
                      ),
                      value: selectedDeptId,
                      items: _departments.map((d) {
                        final id = d['id'].toString();
                        final name = d['name'] as String? ?? id;
                        return DropdownMenuItem(value: id, child: Text(name, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        final dept = _departments.firstWhere((d) => d['id'].toString() == val, orElse: () => {});
                        selectedDeptId = val;
                        selectedDeptName = dept['name'] as String?;
                        loadRooms(val);
                      },
                    ),
                  ),
                ),

                // Room picker
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: roomsLoading
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Room',
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: InputBorder.none,
                            ),
                            value: selectedRoomId,
                            items: rooms.map((r) {
                              final id = r['id'].toString();
                              final name = r['name'] as String? ?? id;
                              return DropdownMenuItem(value: id, child: Text(name, style: const TextStyle(fontSize: 14)));
                            }).toList(),
                            onChanged: rooms.isEmpty ? null : (val) {
                              if (val == null) return;
                              final room = rooms.firstWhere((r) => r['id'].toString() == val, orElse: () => {});
                              setSheet(() {
                                selectedRoomId = val;
                                selectedRoomName = room['name'] as String?;
                              });
                            },
                          ),
                  ),
                ),

                // Confirm button
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.department.flutterColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (selectedRoomId == null || moving)
                          ? null
                          : () async {
                              setSheet(() => moving = true);
                              try {
                                await ApiService.updateProductLocation(product.id, roomId: selectedRoomId);
                                if (mounted) {
                                  final pName     = product.name;
                                  final tRoom     = selectedRoomName;
                                  final deptColor = widget.department.flutterColor;

                                  Navigator.of(ctx).pop();
                                  setState(() => _products.removeWhere((x) => x.id == product.id));

                                  // WS event from server will add the notification to the list
                                  // (with server UUID for deduplication). Just show the snackbar here.
                                  Future.delayed(const Duration(milliseconds: 400), () {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '$pName → ${tRoom ?? 'â€”'}',
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: deptColor,
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        margin: const EdgeInsets.all(12),
                                      ),
                                    );
                                  });
                                }
                              } catch (e) {
                                setSheet(() => moving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                      child: moving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Move Item', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dept = widget.department;
    final color = dept.flutterColor;
    final baseHost = ApiService.baseUrl.replaceAll('/api', '');

    return Scaffold(
      backgroundColor: AppColors.bg(context),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${dept.code} · ${widget.room.name}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(widget.room.name,
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      tooltip: 'Scan QR / Barcode',
                      onPressed: () => Navigator.pushNamed(context, '/qrscanner'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _load,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action bar (PDF downloads)
          _buildActionBar(color),

          // Count + capacity warning
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('${_products.length} item${_products.length != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  if (widget.room.capacity != null) ...[
                    const SizedBox(width: 6),
                    Text('/ ${widget.room.capacity} capacity',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ]),
                if (widget.room.capacity != null &&
                    _products.length > widget.room.capacity!) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Room over capacity â€” ${_products.length} items, limit ${widget.room.capacity}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309)),
                      )),
                    ]),
                  ),
                ],
              ]),
            ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text('No items in this room',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: color,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _products.length,
                              itemBuilder: (ctx, i) {
                                final p = _products[i];
                                final sColor = _statusColors[p.status] ?? const Color(0xFF6B7280);
                                final sBg    = _statusBg[p.status]     ?? const Color(0xFFF3F4F6);
                                final sIcon  = _statusIcons[p.status]  ?? Icons.help_outline;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(
                                    children: [
                                      // Photo
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: p.photoUrl != null
                                            ? Image.network('$baseHost${p.photoUrl}',
                                                width: 48, height: 48, fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => _thumb(color))
                                            : _thumb(color),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH)),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(p.sku,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                                ),
                                                if (p.categoryName != null) ...[
                                                  const Text('  ·  ', style: TextStyle(color: AppColors.textMuted)),
                                                  Flexible(
                                                    child: Text(p.categoryName!,
                                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (p.barcode != null) ...[
                                              const SizedBox(height: 2),
                                              Text(p.barcode!,
                                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: sBg,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: sColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(sIcon, size: 11, color: sColor),
                                            const SizedBox(width: 3),
                                            Text(_statusLabels[p.status] ?? p.status,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sColor)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Move button
                                      GestureDetector(
                                        onTap: () => _showMoveSheet(p),
                                        child: Container(
                                          width: 32, height: 32,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.swap_horiz_rounded, size: 18, color: color),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(Color color) => Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.devices_other, color: color.withValues(alpha: 0.5), size: 22),
      );
}

// â”€â”€â”€ In-app move notification banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MoveNotifBanner extends StatefulWidget {
  final String productName;
  final String? fromRoom;
  final String toRoom;
  final Color color;

  const _MoveNotifBanner({
    required this.productName,
    required this.fromRoom,
    required this.toRoom,
    required this.color,
  });

  @override
  State<_MoveNotifBanner> createState() => _MoveNotifBannerState();
}

class _MoveNotifBannerState extends State<_MoveNotifBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.fromRoom;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: widget.color.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6)),
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
              border: Border.all(color: widget.color.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.swap_horiz_rounded,
                      color: widget.color, size: 22),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Déplacement effectué',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.color)),
                      const SizedBox(height: 3),
                      Text(
                        widget.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2340)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (from != null) ...[
                            Icon(Icons.meeting_room_outlined,
                                size: 11, color: Colors.black38),
                            const SizedBox(width: 3),
                            Text(from,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black45)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.arrow_forward_rounded,
                                  size: 11, color: Colors.black38),
                            ),
                          ],
                          Icon(Icons.meeting_room_rounded,
                              size: 11, color: widget.color),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(widget.toRoom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: widget.color)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Green dot
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF22C55E), shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


