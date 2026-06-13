import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../tracker/accessory/accessory_registry.dart';
import '../tracker/accessory/accessory_model.dart';

class TrackerManagementScreen extends StatefulWidget {
  const TrackerManagementScreen({Key? key}) : super(key: key);

  @override
  State<TrackerManagementScreen> createState() =>
      _TrackerManagementScreenState();
}

class _TrackerManagementScreenState extends State<TrackerManagementScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _selected;
  bool _syncing = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _load(autoSync: true);
  }

  Future<void> _load({bool autoSync = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getTrackers();
      if (mounted) setState(() { _products = List<Map<String, dynamic>>.from(data); _loading = false; });
      // Auto-sync on first load if any linked product has no coordinates yet
      if (autoSync) {
        final needsSync = _products.any((p) =>
            p['tracker_hashed_key'] != null &&
            (p['tracker_lat'] == null || p['tracker_lng'] == null));
        if (needsSync) _syncAll();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // Push all linked accessories' current locations to the backend
  Future<void> _syncAll() async {
    final registry = context.read<AccessoryRegistry>();
    setState(() => _syncing = true);
    int pushed = 0;
    for (final p in _products) {
      final key = p['tracker_hashed_key'] as String?;
      if (key == null) continue;
      try {
        final acc = registry.accessories.firstWhere(
          (a) => a.hashedPublicKey == key,
          orElse: () => throw StateError('not found'),
        );
        final loc = acc.lastLocation;
        if (loc == null) continue;
        final battery = _batteryInt(acc);
        await ApiService.checkInTracker(
            p['id'] as String, loc.latitude, loc.longitude, battery);
        pushed++;
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _syncing = false);
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$pushed tracker location(s) synced'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  int? _batteryInt(Accessory acc) {
    if (acc.lastBatteryStatus == null) return null;
    switch (acc.lastBatteryStatus!.name) {
      case 'full':    return 100;
      case 'medium':  return 60;
      case 'low':     return 20;
      case 'veryLow': return 5;
      default:        return null;
    }
  }

  Future<void> _toggle(Map<String, dynamic> p) async {
    final newActive = !(p['tracker_active'] as bool? ?? false);
    // Optimistic update
    setState(() {
      final idx = _products.indexWhere((x) => x['id'] == p['id']);
      if (idx != -1) _products[idx] = {..._products[idx], 'tracker_active': newActive};
      if (_selected?['id'] == p['id']) _selected = {..._selected!, 'tracker_active': newActive};
    });
    try {
      await ApiService.toggleTracker(p['id'].toString(), newActive);
    } catch (e) {
      // Revert on failure
      setState(() {
        final idx = _products.indexWhere((x) => x['id'] == p['id']);
        if (idx != -1) _products[idx] = {..._products[idx], 'tracker_active': !newActive};
        if (_selected?['id'] == p['id']) _selected = {..._selected!, 'tracker_active': !newActive};
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Toggle failed: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _ping(Map<String, dynamic> p) async {
    try {
      await ApiService.pingTracker(p['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ping sent to ${p['name']}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ping failed: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _unlink(Map<String, dynamic> p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink AirTag'),
        content: Text('Remove AirTag from "${p['name']}"? Location data will be cleared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ApiService.unlinkTracker(p['id'].toString());
    await _load();
  }

  void _showLinkSheet(Map<String, dynamic>? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _LinkAirTagSheet(
        preselectedProduct: product,
        onLinked: _load,
      ),
    );
  }

  List<Marker> get _markers {
    final markers = <Marker>[];
    for (final p in _products) {
      final lat = double.tryParse(p['tracker_lat']?.toString() ?? '');
      final lng = double.tryParse(p['tracker_lng']?.toString() ?? '');
      if (lat == null || lng == null) continue;
      final linked   = p['tracker_hashed_key'] != null;
      final isActive = p['tracker_active'] as bool? ?? false;
      final isSel    = _selected?['id'] == p['id'];
      markers.add(Marker(
        point: LatLng(lat, lng),
        width: 40, height: 40,
        child: GestureDetector(
          onTap: () { setState(() => _selected = p); _mapController.move(LatLng(lat, lng), 16); },
          child: Container(
            decoration: BoxDecoration(
              color: isSel ? AppColors.primary : linked && isActive ? AppColors.success : AppColors.textMuted,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
        ),
      ));
    }
    return markers;
  }

  LatLng get _mapCenter {
    for (final p in _products) {
      final lat = double.tryParse(p['tracker_lat']?.toString() ?? '');
      final lng = double.tryParse(p['tracker_lng']?.toString() ?? '');
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return const LatLng(35.5, 11.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        title: const Text('Tracker Management',
            style: TextStyle(color: AppColors.textH, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.textH),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Sync all locations',
              onPressed: _syncAll,
            ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : Column(children: [
                  _buildMap(),
                  if (_selected != null) _buildSelectedCard(),
                  Expanded(child: _products.isEmpty ? _buildList() : _buildListItems()),
                ]),
    );
  }

  Widget _buildError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
    const SizedBox(height: 12),
    Text(_error!, style: const TextStyle(color: AppColors.textBody)),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: _load, child: const Text('Retry')),
  ]));

  Widget _buildMap() => SizedBox(
    height: 220,
    child: FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: _mapCenter, initialZoom: 13),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.iset.smart_inventory',
        ),
        MarkerLayer(markers: _markers),
      ],
    ),
  );

  Widget _buildSelectedCard() {
    final p       = _selected!;
    final lat     = double.tryParse(p['tracker_lat']?.toString() ?? '');
    final lng     = double.tryParse(p['tracker_lng']?.toString() ?? '');
    final battery = p['tracker_battery'] as int?;
    final linked  = p['tracker_hashed_key'] != null;
    final active  = p['tracker_active'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(p['name'] ?? '—',
                style: const TextStyle(color: AppColors.textH, fontWeight: FontWeight.w600, fontSize: 14))),
            _StatusBadge(active: active),
          ]),
          const SizedBox(height: 2),
          Text(lat != null && lng != null ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}' : 'No location',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          if (battery != null)
            Text('Battery: $battery%',
                style: TextStyle(fontSize: 12,
                    color: battery > 20 ? AppColors.success : AppColors.warning)),
          if (!linked)
            const Text('No AirTag linked',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ])),
        if (linked) ...[
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: active,
              onChanged: (_) => _toggle(p),
              activeColor: AppColors.success,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.wifi_tethering_rounded, color: AppColors.primary),
            tooltip: 'Ping',
            onPressed: () => _ping(p),
          ),
          IconButton(
            icon: const Icon(Icons.link_off_rounded, color: AppColors.error),
            tooltip: 'Unlink',
            onPressed: () => _unlink(p),
          ),
        ] else
          TextButton.icon(
            onPressed: () => _showLinkSheet(p),
            icon: const Icon(Icons.link_rounded, size: 16),
            label: const Text('Link'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
          onPressed: () => setState(() => _selected = null),
        ),
      ]),
    );
  }

  Widget _buildList() {
    if (_products.isEmpty) return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('No trackers linked yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textH)),
          const SizedBox(height: 8),
          const Text(
            'Link an AirTag to an inventory item to start tracking its GPS location.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showLinkSheet(null),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.link_rounded, size: 20),
            label: const Text('Link AirTag to Item',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
    return const SizedBox.shrink();
  }

  Widget _buildListItems() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
      itemCount: _products.length,
      itemBuilder: (_, i) => _TrackerTile(
        product: _products[i],
        isSelected: _selected?['id'] == _products[i]['id'],
        onTap: () {
          setState(() => _selected = _products[i]);
          final lat = double.tryParse(_products[i]['tracker_lat']?.toString() ?? '');
          final lng = double.tryParse(_products[i]['tracker_lng']?.toString() ?? '');
          if (lat != null && lng != null) _mapController.move(LatLng(lat, lng), 16);
        },
        onPing:   () => _ping(_products[i]),
        onUnlink: () => _unlink(_products[i]),
        onLink:   () => _showLinkSheet(_products[i]),
        onToggle: () => _toggle(_products[i]),
      ),
    );
  }
}

// ── Tracker tile ──────────────────────────────────────────────────────────────

class _TrackerTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isSelected;
  final VoidCallback onTap, onPing, onUnlink, onLink, onToggle;

  const _TrackerTile({
    required this.product, required this.isSelected,
    required this.onTap, required this.onPing,
    required this.onUnlink, required this.onLink,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final linked  = product['tracker_hashed_key'] != null;
    final active  = product['tracker_active'] as bool? ?? false;
    final battery = product['tracker_battery'] as int?;
    final room    = product['room_name'] as String?;
    final dept    = product['dept_name'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.07) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.45) : AppColors.border),
        ),
        child: Row(children: [
          // Icon bubble — colour reflects linked+active state
          Container(width: 38, height: 38,
            decoration: BoxDecoration(
              color: linked && active
                  ? AppColors.success.withOpacity(0.13)
                  : linked
                      ? AppColors.warning.withOpacity(0.13)
                      : AppColors.bgMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              linked ? Icons.location_on_rounded : Icons.location_off_rounded,
              color: linked && active
                  ? AppColors.success
                  : linked
                      ? AppColors.warning
                      : AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Name + zone + status
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product['name'] ?? '—',
                style: const TextStyle(color: AppColors.textH, fontWeight: FontWeight.w600, fontSize: 13)),
            if (room != null || dept != null)
              Text([dept, room].where((s) => s != null).join(' › '),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 2),
            _StatusBadge(active: linked && active, noLink: !linked),
          ])),
          // Battery
          if (battery != null) ...[
            const SizedBox(width: 4),
            Icon(
              battery > 50 ? Icons.battery_full_rounded
                  : battery > 20 ? Icons.battery_4_bar_rounded
                  : Icons.battery_alert_rounded,
              size: 14,
              color: battery > 50 ? AppColors.success
                  : battery > 20 ? AppColors.warning
                  : AppColors.error,
            ),
            const SizedBox(width: 2),
            Text('$battery%', style: TextStyle(
                fontSize: 11,
                color: battery > 50 ? AppColors.success
                    : battery > 20 ? AppColors.warning : AppColors.error)),
            const SizedBox(width: 4),
          ],
          // Active toggle (only when linked)
          if (linked)
            Transform.scale(
              scale: 0.72,
              child: Switch(
                value: active,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.success,
              ),
            )
          else
            GestureDetector(
              onTap: onLink,
              child: const Icon(Icons.link_rounded, size: 20, color: AppColors.primary),
            ),
        ]),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool active;
  final bool noLink;
  const _StatusBadge({required this.active, this.noLink = false});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    final IconData icon;

    if (noLink) {
      bg = AppColors.bgMuted; fg = AppColors.textMuted;
      label = 'No AirTag'; icon = Icons.link_off_rounded;
    } else if (active) {
      bg = AppColors.success.withOpacity(0.12); fg = AppColors.success;
      label = 'Active'; icon = Icons.circle;
    } else {
      bg = AppColors.warning.withOpacity(0.12); fg = AppColors.warning;
      label = 'Inactive'; icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: noLink ? 11 : 7, color: fg),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

// ── Link AirTag bottom sheet (AirTag-first flow) ──────────────────────────────

class _LinkAirTagSheet extends StatefulWidget {
  final Map<String, dynamic>? preselectedProduct;
  final VoidCallback onLinked;
  const _LinkAirTagSheet({this.preselectedProduct, required this.onLinked});
  @override
  State<_LinkAirTagSheet> createState() => _LinkAirTagSheetState();
}

class _LinkAirTagSheetState extends State<_LinkAirTagSheet> {
  // Step 0 = pick AirTag, Step 1 = pick product
  int _step = 0;
  Accessory? _accessory;
  Map<String, dynamic>? _product;
  bool _saving = false;
  String _search = '';
  List<Map<String, dynamic>> _allProducts = [];
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedProduct != null) {
      _product = widget.preselectedProduct;
      // still start at step 0 to pick the AirTag first
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final res = await ApiService.getProducts();
      if (mounted) setState(() {
        _allProducts = List<Map<String, dynamic>>.from(res['data'] ?? []);
        _loadingProducts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _save() async {
    if (_product == null || _accessory == null) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.linkTracker(
        _product!['id'].toString(),
        _accessory!.hashedPublicKey,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pop(context);
        widget.onLinked();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${_accessory!.name}" linked to "${_product!['name']}"'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Failed to link'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessories = context.watch<AccessoryRegistry>().accessories;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Header
          Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  gradient: AppColors.gradPrimary,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.link_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Link AirTag to Item',
                  style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700, color: AppColors.textH)),
              Text(_step == 0
                  ? 'Step 1 — Pick your AirTag'
                  : 'Step 2 — Pick the inventory item',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            if (_step == 1)
              TextButton(
                onPressed: () => setState(() { _step = 0; _product = null; _search = ''; }),
                child: const Text('Back'),
              ),
          ]),
          const SizedBox(height: 14),

          // Step bar
          Row(children: [
            _StepDot(n: 1, active: true, done: _step > 0),
            Expanded(child: Container(height: 2,
                color: _step > 0 ? AppColors.primary : AppColors.border)),
            _StepDot(n: 2, active: _step >= 1, done: false),
          ]),
          const SizedBox(height: 16),

          // ── STEP 0: pick AirTag ──────────────────────────────────────────
          if (_step == 0) ...[
            if (accessories.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.bgMuted,
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'No AirTags found.\nCreate one in the AirTag Tracker screen first.',
                    style: TextStyle(fontSize: 12, color: AppColors.textBody),
                  )),
                ]),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: accessories.map((acc) {
                    final sel =
                        _accessory?.hashedPublicKey == acc.hashedPublicKey;
                    return GestureDetector(
                      onTap: () => setState(() => _accessory = acc),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary.withOpacity(0.08)
                              : AppColors.bgMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? AppColors.primary : AppColors.border,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: acc.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(acc.icon, color: acc.color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(acc.name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.textH)),
                            Text(acc.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: acc.isActive
                                        ? AppColors.success
                                        : AppColors.textMuted)),
                          ])),
                          if (sel)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 22),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _accessory != null
                    ? () => setState(() { _step = 1; _search = ''; })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.bgMuted,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Next — Pick Item',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],

          // ── STEP 1: pick product ─────────────────────────────────────────
          if (_step == 1) ...[
            // Selected AirTag recap
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(_accessory!.icon, color: _accessory!.color, size: 16),
                const SizedBox(width: 8),
                Text(_accessory!.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ]),
            ),
            const SizedBox(height: 12),

            // Product search
            TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search inventory…',
                prefixIcon: Icon(Icons.search, size: 18,
                    color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 10),

            if (_loadingProducts)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2)))
            else
              ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _allProducts
                      .where((p) =>
                          _search.isEmpty ||
                          (p['name'] as String? ?? '')
                              .toLowerCase()
                              .contains(_search) ||
                          (p['sku'] as String? ?? '')
                              .toLowerCase()
                              .contains(_search))
                      .map((p) {
                    final sel = _product?['id'] == p['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _product = p),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary.withOpacity(0.08)
                              : AppColors.bgMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? AppColors.primary : AppColors.border,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(p['name'] ?? '—',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.textH)),
                            Text(p['sku'] ?? '',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          ])),
                          if (sel)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 18)
                          else
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textMuted, size: 18),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: _saving
                  ? Container(
                      decoration: BoxDecoration(
                          gradient: AppColors.gradPrimary,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))))
                  : ElevatedButton.icon(
                      onPressed: _product != null ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.bgMuted,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Confirm Link',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int n;
  final bool active, done;
  const _StepDot({required this.n, required this.active, required this.done});

  @override
  Widget build(BuildContext context) => Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.bgMuted,
          shape: BoxShape.circle,
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
        ),
        child: Center(
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$n',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textMuted)),
        ),
      );
}
