import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/ws_service.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';

// â”€â”€ Models â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class IotScanEvent {
  final String   scanType;
  final String   productName;
  final String   identifier;
  final String   roomName;
  final String?  fromRoom;
  final String?  readerId;
  final bool     moved;
  final DateTime timestamp;

  IotScanEvent.fromJson(Map<String, dynamic> j)
      : scanType    = j['scan_type']    as String? ?? 'rfid',
        productName = j['product_name'] as String? ?? 'Unknown',
        identifier  = j['uid_or_mac']   as String? ?? '',
        roomName    = j['room_name']    as String? ?? '',
        fromRoom    = j['from_room']    as String?,
        readerId    = j['reader_id']    as String?,
        moved       = (j['from_room'] != null && j['from_room'] != j['room_name']),
        timestamp   = DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now();
}

class UnregisteredScan {
  final String   id;
  final String   uid;
  final String   scanType;
  final String?  roomId;
  final String   roomName;
  final String?  readerId;
  final DateTime scannedAt;

  UnregisteredScan.fromJson(Map<String, dynamic> j)
      : id        = j['id']        as String,
        uid       = j['uid']       as String,
        scanType  = j['scan_type'] as String? ?? 'rfid',
        roomId    = j['room_id']   as String?,
        roomName  = j['room_name'] as String? ?? '',
        readerId  = j['reader_id'] as String?,
        scannedAt = DateTime.tryParse(j['scanned_at'] as String? ?? '') ?? DateTime.now();
}

// â”€â”€ Main screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class IotLiveFeedScreen extends StatefulWidget {
  const IotLiveFeedScreen({Key? key}) : super(key: key);

  @override
  State<IotLiveFeedScreen> createState() => _IotLiveFeedScreenState();
}

class _IotLiveFeedScreenState extends State<IotLiveFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final List<IotScanEvent>     _events      = [];
  final List<UnregisteredScan> _unregistered = [];
  StreamSubscription? _wsSub;
  bool _loadingUnreg = false;

  @override
  void initState() {
    super.initState();
    _tabs  = TabController(length: 2, vsync: this);
    _wsSub = WsService.stream.listen(_onWsMessage);
    _loadUnregistered();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  void _onWsMessage(dynamic raw) {
    try {
      final msg = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      if (!mounted) return;

      if (msg['type'] == 'iot_scan') {
        setState(() {
          _events.insert(0, IotScanEvent.fromJson(msg));
          if (_events.length > 100) _events.removeLast();
        });
      } else if (msg['type'] == 'unregistered_scan') {
        final scan = UnregisteredScan.fromJson({
          'id':        '',
          'uid':       msg['uid'],
          'scan_type': msg['scan_type'],
          'room_id':   msg['room_id'],
          'room_name': msg['room_name'],
          'reader_id': msg['reader_id'],
          'scanned_at': msg['timestamp'],
        });
        setState(() => _unregistered.insert(0, scan));
        // Refresh from server to get the real id
        _loadUnregistered();
      } else if (msg['type'] == 'tag_assigned') {
        setState(() => _unregistered.removeWhere((s) => s.uid == msg['uid']));
      }
    } catch (_) {}
  }

  Future<void> _loadUnregistered() async {
    if (_loadingUnreg) return;
    setState(() => _loadingUnreg = true);
    try {
      final res = await ApiService.getUnregisteredScans();
      if (!mounted) return;
      setState(() {
        _unregistered
          ..clear()
          ..addAll((res['data'] as List<dynamic>? ?? [])
              .map((e) => UnregisteredScan.fromJson(e as Map<String, dynamic>)));
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingUnreg = false);
    }
  }

  String _rel(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60)  return '${d.inSeconds}s ago';
    if (d.inMinutes < 60)  return '${d.inMinutes}m ago';
    if (d.inHours   < 24)  return '${d.inHours}h ago';
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabs,
        children: [_buildLiveFeed(), _buildUnregistered()],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textH),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IoT Live Feed',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
          Row(children: [
            Container(width: 7, height: 7,
                decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            const Text('Live — ESP32 RFID events',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ],
      ),
      bottom: TabBar(
        controller: _tabs,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        tabs: [
          const Tab(text: 'Live Events'),
          Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Unassigned'),
              if (_unregistered.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${_unregistered.length}',
                      style: const TextStyle(fontSize: 10, color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Tab 1: Live events â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildLiveFeed() {
    if (_events.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 90, height: 90,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.sensors, size: 44, color: AppColors.primary)),
          const SizedBox(height: 20),
          const Text('Waiting for scans…',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textH)),
          const SizedBox(height: 8),
          const Text('ESP32 events appear here in real time.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _LiveEventCard(event: _events[i], rel: _rel(_events[i].timestamp)),
    );
  }

  // â”€â”€ Tab 2: Unassigned tags â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildUnregistered() {
    if (_loadingUnreg && _unregistered.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_unregistered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 90, height: 90,
              decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline, size: 44, color: Color(0xFF22C55E))),
          const SizedBox(height: 20),
          const Text('All tags assigned',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textH)),
          const SizedBox(height: 8),
          const Text('Every scanned tag is linked to a product.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadUnregistered,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _unregistered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _UnregisteredCard(
          scan: _unregistered[i],
          rel:  _rel(_unregistered[i].scannedAt),
          onAssigned: (uid) {
            setState(() => _unregistered.removeWhere((s) => s.uid == uid));
          },
        ),
      ),
    );
  }
}

// â”€â”€ Live event card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LiveEventCard extends StatelessWidget {
  final IotScanEvent event;
  final String rel;
  const _LiveEventCard({required this.event, required this.rel});

  @override
  Widget build(BuildContext context) {
    final moved       = event.moved;
    final accent      = moved ? AppColors.primary : const Color(0xFF22C55E);
    final bg          = moved ? const Color(0xFFEEF2FF) : const Color(0xFFF0FDF4);
    final border      = moved ? AppColors.primary.withOpacity(0.25) : const Color(0xFF86EFAC);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6),
                border: Border.all(color: border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(event.scanType == 'rfid' ? Icons.nfc_rounded : Icons.bluetooth,
                  size: 12, color: accent),
              const SizedBox(width: 4),
              Text(event.scanType.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
              if (moved) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                      color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                  child: const Text('MOVED',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ]),
          ),
          const Spacer(),
          Text(rel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.inventory_2_outlined, size: 18, color: accent)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.productName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textH)),
            Text(event.identifier,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted,
                    letterSpacing: 0.5)),
          ])),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 6),
          if (moved && event.fromRoom != null) ...[
            Flexible(child: Text(event.fromRoom!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textBody))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary)),
            Flexible(child: Text(event.roomName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.primary))),
          ] else
            Flexible(child: Text(event.roomName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent))),
          const Spacer(),
          if (event.readerId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: AppColors.bgMuted,
                  borderRadius: BorderRadius.circular(5)),
              child: Text(event.readerId!,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
        ]),
      ]),
    );
  }
}

// â”€â”€ Unregistered tag card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _UnregisteredCard extends StatelessWidget {
  final UnregisteredScan scan;
  final String rel;
  final void Function(String uid) onAssigned;
  const _UnregisteredCard({required this.scan, required this.rel, required this.onAssigned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.help_outline_rounded, size: 12, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(scan.scanType.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.warning)),
            ]),
          ),
          const SizedBox(width: 8),
          const Text('UNASSIGNED',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning)),
          const Spacer(),
          Text(rel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E6), borderRadius: BorderRadius.circular(9)),
              child: Icon(
                scan.scanType == 'ble' ? Icons.bluetooth : Icons.nfc_rounded,
                size: 18, color: AppColors.warning)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(scan.uid,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textH, letterSpacing: 0.5)),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(child: Text(scan.roomName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textBody))),
              if (scan.readerId != null) ...[
                const Text('  ·  ', style: TextStyle(color: AppColors.textMuted)),
                Flexible(child: Text(scan.readerId!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
              ],
            ]),
          ])),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAssignSheet(context),
            icon: const Icon(Icons.link_rounded, size: 16),
            label: const Text('Assign to Product',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }

  void _showAssignSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignSheet(scan: scan, onAssigned: onAssigned),
    );
  }
}

// â”€â”€ Assign bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AssignSheet extends StatefulWidget {
  final UnregisteredScan scan;
  final void Function(String uid) onAssigned;
  const _AssignSheet({required this.scan, required this.onAssigned});

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool          _loading  = true;
  bool          _saving   = false;
  String?       _selected; // product id
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      // Load products in the room where the tag was scanned
      final res  = await ApiService.getProducts(
          limit: 200, roomId: widget.scan.roomId);
      if (!mounted) return;
      final rows = (res['data'] as List<dynamic>? ?? []);
      final isBle = widget.scan.scanType == 'ble';
      final list = rows
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .where((p) => isBle
              ? (p.bleDevice == null || p.bleDevice!.isEmpty)
              : (p.rfidTag   == null || p.rfidTag!.isEmpty))
          .toList();
      setState(() { _products = list; _filtered = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _products
          : _products.where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _assign() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      await ApiService.assignUnregisteredTag(widget.scan.id, _selected!);
      if (!mounted) return;
      widget.onAssigned(widget.scan.uid);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tag assigned successfully'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle
        Center(child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2)))),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Assign Tag to Product',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textH)),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.scan.uid,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: Color(0xFF6D28D9), letterSpacing: 0.6)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 2),
              Flexible(
                child: Text(widget.scan.roomName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
            const SizedBox(height: 4),
            const Text('Showing products currently in this room',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            // Search
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search product name or SKU…',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgPage,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.border),

        // Product list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('No untagged products found',
                          style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border, indent: 20),
                      itemBuilder: (_, i) {
                        final p = _filtered[i];
                        final sel = _selected == p.id;
                        return ListTile(
                          onTap: () => setState(() => _selected = p.id),
                          leading: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary.withOpacity(0.12)
                                  : AppColors.bgMuted,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(Icons.inventory_2_outlined, size: 19,
                                color: sel ? AppColors.primary : AppColors.textMuted),
                          ),
                          title: Text(p.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: sel ? AppColors.primary : AppColors.textH)),
                          subtitle: Text(p.sku,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          trailing: sel
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 22)
                              : null,
                        );
                      },
                    ),
        ),

        // Confirm button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected == null || _saving ? null : _assign,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.border,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Assignment',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ]),
    );
  }
}


