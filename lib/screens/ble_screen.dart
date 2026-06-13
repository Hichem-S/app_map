import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_colors.dart';

class BleScreen extends StatefulWidget {
  const BleScreen({super.key});

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, ScanResult> _nearby = {};
  final Map<String, ScanResult> _history = {};
  final Set<String> _favorites = {};
  final Map<String, int?> _advIntervals = {};
  final Map<String, DateTime> _lastSeen = {};

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanSub;
  bool _isScanning = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    FlutterBluePlus.adapterState.listen((s) {
      if (!mounted) return;
      setState(() => _adapterState = s);
      if (s == BluetoothAdapterState.on) _startScanning();
    });
    _isScanSub = FlutterBluePlus.isScanning.listen((v) {
      if (mounted) setState(() => _isScanning = v);
    });
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scanSub?.cancel();
    _isScanSub?.cancel();
    FlutterBluePlus.stopScan().catchError((_) {});
    super.dispose();
  }

  Future<void> _init() async {
    await _requestPermissions();
    final state = await FlutterBluePlus.adapterState.first;
    if (state == BluetoothAdapterState.on) {
      await _startScanning();
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _startScanning() async {
    if (_isScanning) return;
    try {
      _scanSub?.cancel();
      setState(() => _nearby.clear());

      _scanSub = FlutterBluePlus.onScanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          for (final r in results) {
            final id = r.device.remoteId.toString();
            final prev = _lastSeen[id];
            if (prev != null) {
              final ms = r.timeStamp.difference(prev).inMilliseconds;
              if (ms > 0 && ms < 10000) _advIntervals[id] = ms;
            }
            _lastSeen[id] = r.timeStamp;
            _nearby[id] = r;
            _history[id] = r;
          }
        });
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
        androidUsesFineLocation: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _stopScanning() async {
    await FlutterBluePlus.stopScan().catchError((_) {});
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Color _rssiColor(int rssi) {
    if (rssi >= -60) return const Color(0xFF27AE60);
    if (rssi >= -75) return const Color(0xFF2980B9);
    if (rssi >= -85) return const Color(0xFFF59E0B);
    return const Color(0xFFE74C3C);
  }

  double _distanceM(int rssi) => pow(10.0, (-59 - rssi) / 20.0).toDouble();

  String _deviceName(ScanResult r) {
    final n = r.advertisementData.advName.isNotEmpty
        ? r.advertisementData.advName
        : r.device.platformName;
    return n.isNotEmpty ? n : 'N/A';
  }

  bool _isApple(ScanResult r) =>
      r.advertisementData.manufacturerData.containsKey(0x004C);

  void _toggleFav(String id) => setState(() {
        _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id);
      });

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final adapterOff = _adapterState == BluetoothAdapterState.off ||
        _adapterState == BluetoothAdapterState.unavailable;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BLE Scanner',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
            Text(
              _isScanning ? 'Scanning…' : 'Bluetooth Low Energy',
              style: TextStyle(
                  fontSize: 11,
                  color: _isScanning ? AppColors.primary : AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          if (!adapterOff)
            IconButton(
              icon: Icon(
                _isScanning ? Icons.stop_rounded : Icons.refresh_rounded,
                color: _isScanning ? AppColors.error : AppColors.primary,
                size: 26,
              ),
              onPressed: _isScanning ? _stopScanning : _startScanning,
            ),
          IconButton(
            icon: const Icon(Icons.radar_rounded, color: AppColors.primary),
            tooltip: 'BLE Proximity',
            onPressed: () => Navigator.pushNamed(context, '/ble-proximity'),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              const Divider(height: 1, color: AppColors.border),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                tabs: [
                  Tab(text: 'Near By (${_nearby.length})'),
                  Tab(text: 'History (${_history.length})'),
                  Tab(text: 'Favorites (${_favorites.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: adapterOff
          ? _buildBluetoothOff()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_nearby.values.toList()),
                _buildList(_history.values.toList()),
                _buildList(_history.values
                    .where((r) => _favorites.contains(r.device.remoteId.toString()))
                    .toList()),
              ],
            ),
      floatingActionButton: adapterOff
          ? null
          : FloatingActionButton.extended(
              onPressed: _isScanning ? _stopScanning : _startScanning,
              backgroundColor: _isScanning ? AppColors.error : AppColors.primary,
              elevation: 2,
              icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
              label: Text(_isScanning ? 'Stop' : 'Scan',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
    );
  }

  // â”€â”€â”€ Bluetooth off â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildBluetoothOff() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorBg,
                border: Border.all(color: AppColors.error, width: 2),
              ),
              child: const Icon(Icons.bluetooth_disabled_rounded,
                  size: 55, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            const Text('Bluetooth is Off',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textH)),
            const SizedBox(height: 10),
            const Text(
              'Enable Bluetooth on your device\nto start scanning.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.6),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try { await FlutterBluePlus.turnOn(); } catch (_) {}
              },
              icon: const Icon(Icons.bluetooth_rounded),
              label: const Text('Enable Bluetooth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ Device list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildList(List<ScanResult> results) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bluetooth_searching_rounded,
                  size: 64, color: AppColors.textMuted.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                _isScanning
                    ? 'Scanning for nearby devices…'
                    : 'No devices found.\nTap Scan to start.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.6),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = [...results]..sort((a, b) => b.rssi.compareTo(a.rssi));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 96),
      itemCount: sorted.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 76, color: Color(0xFFF0F0F0)),
      itemBuilder: (_, i) {
        final r = sorted[i];
        final id = r.device.remoteId.toString();
        return _DeviceTile(
          result: r,
          name: _deviceName(r),
          distance: _distanceM(r.rssi),
          advInterval: _advIntervals[id],
          signalColor: _rssiColor(r.rssi),
          isApple: _isApple(r),
          isFavorite: _favorites.contains(id),
          onFavorite: () => _toggleFav(id),
          onConnect: r.advertisementData.connectable
              ? () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => _BleDeviceScreen(device: r.device)))
              : null,
          onRawData: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _RawDataSheet(result: r, name: _deviceName(r)),
          ),
        );
      },
    );
  }
}

// â”€â”€â”€ Device tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DeviceTile extends StatelessWidget {
  final ScanResult result;
  final String name;
  final double distance;
  final int? advInterval;
  final Color signalColor;
  final bool isApple;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback? onConnect;
  final VoidCallback onRawData;

  const _DeviceTile({
    required this.result,
    required this.name,
    required this.distance,
    required this.advInterval,
    required this.signalColor,
    required this.isApple,
    required this.isFavorite,
    required this.onFavorite,
    required this.onConnect,
    required this.onRawData,
  });

  @override
  Widget build(BuildContext context) {
    final rssi = result.rssi;
    final mac = result.device.remoteId.toString();
    final distStr = distance < 100 ? '${distance.toStringAsFixed(2)} m' : '>100 m';
    final advStr = advInterval != null ? '${advInterval} ms' : 'â€”';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signal circle
          Column(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: signalColor,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(rssi.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const Text('dBm',
                        style: TextStyle(color: Colors.white70, fontSize: 9)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (isApple)
                const Icon(Icons.apple, size: 18, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textH)),
                const SizedBox(height: 2),
                Text(mac,
                    style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.straighten_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text('Apx Dist: $distStr',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textBody),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text('Adv: $advStr',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textBody),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (onConnect != null)
                GestureDetector(
                  onTap: onConnect,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('CONNECT',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                )
              else
                const Text('Non Connectable',
                    style: TextStyle(
                        color: Color(0xFFE74C3C),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onRawData,
                    child: const Text('RAW DATA',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onRawData,
                    child: const Icon(Icons.show_chart_rounded,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onFavorite,
                    child: Icon(
                      isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 20,
                      color: isFavorite
                          ? const Color(0xFFF59E0B)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Raw data sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RawDataSheet extends StatelessWidget {
  final ScanResult result;
  final String name;

  const _RawDataSheet({required this.result, required this.name});

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

  @override
  Widget build(BuildContext context) {
    final ad = result.advertisementData;
    final mac = result.device.remoteId.toString();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.show_chart_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textH)),
                      Text(mac,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(16),
              children: [
                _row('RSSI', '${result.rssi} dBm'),
                _row('Connectable', ad.connectable ? 'Yes' : 'No'),
                if (ad.advName.isNotEmpty) _row('Advertised Name', ad.advName),
                if (ad.txPowerLevel != null)
                  _row('TX Power', '${ad.txPowerLevel} dBm'),
                if (ad.appearance != null)
                  _row('Appearance', '0x${ad.appearance!.toRadixString(16).toUpperCase().padLeft(4, '0')}'),
                if (ad.serviceUuids.isNotEmpty)
                  _row('Service UUIDs',
                      ad.serviceUuids.map((u) => u.toString()).join('\n')),
                if (ad.manufacturerData.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const _SectionLabel('Manufacturer Data'),
                  ...ad.manufacturerData.entries.map((e) => _row(
                      'ID 0x${e.key.toRadixString(16).padLeft(4, '0').toUpperCase()}',
                      _hex(e.value))),
                ],
                if (ad.serviceData.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const _SectionLabel('Service Data'),
                  ...ad.serviceData.entries
                      .map((e) => _row(e.key.toString(), _hex(e.value))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 12, color: AppColors.textH)),
            ),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5)),
      );
}

// â”€â”€â”€ Device detail / GATT screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BleDeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  const _BleDeviceScreen({required this.device});

  @override
  State<_BleDeviceScreen> createState() => _BleDeviceScreenState();
}

class _BleDeviceScreenState extends State<_BleDeviceScreen> {
  BluetoothConnectionState _connState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _discovering = false;
  StreamSubscription? _connSub;

  @override
  void initState() {
    super.initState();
    _connSub = widget.device.connectionState.listen((s) {
      if (mounted) setState(() => _connState = s);
    });
    _connect();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    widget.device.disconnect().catchError((_) {});
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      await widget.device.connect(autoConnect: false);
      if (mounted) {
        setState(() => _discovering = true);
        final services = await widget.device.discoverServices();
        if (mounted) setState(() { _services = services; _discovering = false; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connect failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _connState == BluetoothConnectionState.connected;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.device.platformName.isNotEmpty
                  ? widget.device.platformName
                  : 'Unknown Device',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textH),
            ),
            Text(widget.device.remoteId.toString(),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: connected
                  ? const Color(0xFFE6F9F2)
                  : const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: connected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444)),
            ),
            child: Text(
              connected ? 'Connected' : 'Connecting…',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: connected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444)),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: _discovering
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Discovering services…',
                      style: TextStyle(color: AppColors.textBody)),
                ],
              ),
            )
          : _services.isEmpty
              ? const Center(
                  child: Text('No services found',
                      style: TextStyle(color: AppColors.textBody)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _services.length,
                  itemBuilder: (_, i) {
                    final svc = _services[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.shadowMd,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.settings_input_antenna_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          svc.uuid.toString().toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textH),
                        ),
                        subtitle: Text(
                          '${svc.characteristics.length} characteristic(s)',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                        children: svc.characteristics.map((c) {
                          final props = <String>[];
                          if (c.properties.read) props.add('Read');
                          if (c.properties.write) props.add('Write');
                          if (c.properties.notify) props.add('Notify');
                          if (c.properties.indicate) props.add('Indicate');
                          return ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(56, 0, 16, 0),
                            title: Text(
                              c.uuid.toString().toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: AppColors.textBody),
                            ),
                            subtitle: Text(
                              props.isEmpty ? 'No properties' : props.join('  ·  '),
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textMuted),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}


