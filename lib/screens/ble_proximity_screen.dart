import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class BleProximityScreen extends StatefulWidget {
  const BleProximityScreen({Key? key}) : super(key: key);

  @override
  State<BleProximityScreen> createState() => _BleProximityScreenState();
}

class _BleProximityScreenState extends State<BleProximityScreen> {
  // fingerprint prefix → tracker product
  Map<String, Map<String, dynamic>> _trackerByFingerprint = {};
  List<Map<String, dynamic>> _allTrackers = [];
  bool _loadingTrackers = true;

  bool _scanning = false;
  bool _starting = false;
  bool _btOn = false;
  // mac → latest ScanResult (Apple FindMy only)
  final Map<String, ScanResult> _rawDevices = {};

  StreamSubscription? _scanSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _btSub;
  Timer? _restartTimer;

  @override
  void initState() {
    super.initState();

    // Watch BT adapter state — start/stop scanning automatically
    _btSub = FlutterBluePlus.adapterState.listen((state) {
      final on = state == BluetoothAdapterState.on;
      if (mounted) setState(() => _btOn = on);
      if (on && !_scanning && !_starting) {
        _startScan();
      } else if (!on) {
        _restartTimer?.cancel();
        _scanSub?.cancel();
        setState(() { _scanning = false; _rawDevices.clear(); });
      }
    });

    // isScanning: schedule ONE restart, only when BT is on
    _stateSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (!mounted) return;
      setState(() => _scanning = scanning);
      if (!scanning && !_starting && _btOn) {
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(seconds: 5), () {
          if (mounted && !_scanning && !_starting && _btOn) _startScan();
        });
      }
    });

    _loadTrackers();
  }

  @override
  void dispose() {
    _restartTimer?.cancel();
    _scanSub?.cancel();
    _stateSub?.cancel();
    _btSub?.cancel();
    FlutterBluePlus.stopScan().catchError((_) {});
    super.dispose();
  }

  // Detect Apple FindMy / AirTag advertisement.
  // Company ID 0x004C = 76 (Apple), first data byte 0x12 = FindMy type.
  static bool _isAppleFindMy(ScanResult r) {
    final data = r.advertisementData.manufacturerData[0x004C];
    return data != null && data.isNotEmpty && data[0] == 0x12;
  }

  // Build the stable FINDMY: fingerprint from manufacturer data.
  // Format matches what the firmware sends: "FINDMY:" + hex([0x4C,0x00,...data])
  static String _fingerprint(ScanResult r) {
    final data = r.advertisementData.manufacturerData[0x004C] ?? [];
    // Prepend company ID bytes (0x004C in little-endian = [0x4C, 0x00])
    final bytes = [0x4C, 0x00, ...data];
    return 'FINDMY:${bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join()}';
  }

  Future<void> _loadTrackers() async {
    setState(() => _loadingTrackers = true);
    try {
      final data = await ApiService.getTrackers();
      final all = List<Map<String, dynamic>>.from(data)
          .where((t) =>
              t['tracker_hashed_key'] != null &&
              (t['tracker_active'] as bool? ?? false))
          .toList();

      // Build fingerprint → tracker map from ble_device field (e.g. "FINDMY:4C0012020003")
      final byFp = <String, Map<String, dynamic>>{};
      for (final t in all) {
        final fp = (t['ble_device'] as String? ?? '').trim().toUpperCase();
        if (fp.startsWith('FINDMY:')) byFp[fp] = t;
      }

      if (mounted) {
        setState(() {
          _allTrackers = all;
          _trackerByFingerprint = byFp;
          _loadingTrackers = false;
        });
      }
      _startScan();
    } catch (e) {
      if (mounted) setState(() => _loadingTrackers = false);
    }
  }

  Future<void> _startScan() async {
    if (_scanning || _starting || !_btOn) return;
    _starting = true;
    _restartTimer?.cancel();

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      bool changed = false;
      for (final r in results) {
        if (!_isAppleFindMy(r)) continue;
        final mac = r.device.remoteId.str.toLowerCase();
        if (!_rawDevices.containsKey(mac) || _rawDevices[mac]!.rssi != r.rssi) {
          _rawDevices[mac] = r;
          changed = true;
        }
      }
      if (changed && mounted) setState(() {});
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));
    } catch (e) {
      debugPrint('BLE startScan error: $e');
    }
    _starting = false;
  }

  Future<void> _restart() async {
    _restartTimer?.cancel();
    _scanSub?.cancel();
    try { await FlutterBluePlus.stopScan(); } catch (_) {}
    setState(() { _rawDevices.clear(); });
    await Future.delayed(const Duration(milliseconds: 500));
    _startScan();
  }

  // Match detected AirTags to registered trackers.
  // Strategy 1: fingerprint prefix match (first 10 hex chars = 5 stable bytes,
  //   ignoring the rotating status byte at the end).
  // Strategy 2: position-based fallback (strongest signal = first tracker).
  List<_ProximityItem> get _items {
    final detected = _rawDevices.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return detected.asMap().entries.map((e) {
      final idx = e.key;
      final r   = e.value;

      // Build 5-byte prefix (10 hex chars) from this scan result
      final fp        = _fingerprint(r);
      final fpPrefix  = fp.length >= 17 ? fp.substring(0, 17) : fp; // "FINDMY:4C001202"

      // Try prefix match against registered trackers
      Map<String, dynamic>? tracker;
      for (final entry in _trackerByFingerprint.entries) {
        final storedPrefix = entry.key.length >= 17 ? entry.key.substring(0, 17) : entry.key;
        if (storedPrefix == fpPrefix) { tracker = entry.value; break; }
      }

      // Position-based fallback when no exact prefix match
      tracker ??= idx < _allTrackers.length ? _allTrackers[idx] : null;

      return _ProximityItem(
        mac:     r.device.remoteId.str.toLowerCase(),
        rssi:    r.rssi,
        product: tracker,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_btOn) {
      return Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: _appBar(),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bluetooth_disabled_rounded, size: 64,
                color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Bluetooth is off',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textH)),
            const SizedBox(height: 8),
            const Text('Turn on Bluetooth to scan for nearby AirTags.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    if (_loadingTrackers) {
      return Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final items = _items;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: _appBar(),
      body: Column(
        children: [
          _buildStatusBar(items.length),
          Expanded(
            child: items.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ProximityCard(item: items[i]),
                  ),
          ),
        ],
      ),
    );
  }

  AppBar _appBar() => AppBar(
        backgroundColor: AppColors.bgCard,
        title: const Text('AirTag Proximity',
            style: TextStyle(color: AppColors.textH, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.textH),
        actions: [
          IconButton(
            icon: Icon(
              _scanning ? Icons.stop_rounded : Icons.refresh_rounded,
              color: _scanning ? Colors.orange : AppColors.textH,
            ),
            tooltip: _scanning ? 'Stop' : 'Restart scan',
            onPressed: _scanning ? () => FlutterBluePlus.stopScan() : _restart,
          ),
        ],
      );

  Widget _buildStatusBar(int matched) => Container(
        color: AppColors.bgCard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: _scanning ? AppColors.success : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _scanning ? 'Scanning…' : 'Idle',
            style: TextStyle(
              color: _scanning ? AppColors.success : AppColors.textMuted,
              fontSize: 13, fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '$matched / ${_trackerByFingerprint.length} trackers detected',
            style: const TextStyle(color: AppColors.accent,
                fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ]),
      );

  Widget _buildEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.radar_rounded, size: 64,
              color: AppColors.textMuted.withOpacity(0.35)),
          const SizedBox(height: 16),
          Text(
            _scanning ? 'Scanning for your AirTags…' : 'No AirTags detected',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text('${_allTrackers.length} tracker(s) registered',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          if (!_scanning) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.radar_rounded, size: 16),
              label: const Text('Scan Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ]),
      );
}

// ── Data model ────────────────────────────────────────────────────────────────

class _ProximityItem {
  final String mac;
  final int rssi;
  final Map<String, dynamic>? product;

  const _ProximityItem({required this.mac, required this.rssi, this.product});

  String get proximityLabel {
    if (rssi >= -60) return 'Very Close';
    if (rssi >= -75) return 'Close';
    return 'Nearby';
  }

  Color get proximityColor {
    if (rssi >= -60) return AppColors.success;
    if (rssi >= -75) return AppColors.warning;
    return AppColors.error;
  }

  double get signalStrength => ((rssi + 100) / 100).clamp(0.0, 1.0);
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _ProximityCard extends StatelessWidget {
  final _ProximityItem item;
  const _ProximityCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final p       = item.product;
    final name    = p?['name'] as String? ?? 'AirTag';
    final sku     = p?['sku'] as String? ?? '';
    final room    = p?['room_name'] as String?;
    final dept    = p?['dept_name'] as String?;
    final battery = p?['tracker_battery'] as int?;
    final location = [dept, room].where((s) => s != null && s.isNotEmpty).join(' › ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(children: [
        // Signal column
        SizedBox(
          width: 46,
          child: Column(children: [
            Icon(Icons.radar_rounded, color: item.proximityColor, size: 26),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.signalStrength,
                backgroundColor: AppColors.bgMuted,
                color: item.proximityColor,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 3),
            Text('${item.rssi} dBm',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
          ]),
        ),
        const SizedBox(width: 12),
        // Product info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    color: AppColors.textH,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            if (sku.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sku,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
            if (location.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.place_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(location,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
            if (battery != null) ...[
              const SizedBox(height: 3),
              Row(children: [
                Icon(
                  battery > 50 ? Icons.battery_full_rounded
                      : battery > 20 ? Icons.battery_4_bar_rounded
                      : Icons.battery_alert_rounded,
                  size: 12,
                  color: battery > 50 ? AppColors.success
                      : battery > 20 ? AppColors.warning : AppColors.error,
                ),
                const SizedBox(width: 3),
                Text('$battery%',
                    style: TextStyle(
                      fontSize: 11,
                      color: battery > 50 ? AppColors.success
                          : battery > 20 ? AppColors.warning : AppColors.error,
                    )),
              ]),
            ],
            if (p == null) ...[
              const SizedBox(height: 3),
              const Text('Not linked to inventory',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        // Proximity badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: item.proximityColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(item.proximityLabel,
              style: TextStyle(
                  color: item.proximityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
