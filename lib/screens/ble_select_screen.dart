import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_colors.dart';

/// BLE scanner that returns the selected device MAC address when a device is tapped.
class BleSelectScreen extends StatefulWidget {
  const BleSelectScreen({super.key});

  @override
  State<BleSelectScreen> createState() => _BleSelectScreenState();
}

class _BleSelectScreenState extends State<BleSelectScreen> {
  final Map<String, ScanResult> _results = {};
  StreamSubscription<List<ScanResult>>? _scanSub;
  bool _isScanning = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.adapterState.listen((s) {
      if (!mounted) return;
      setState(() => _adapterState = s);
      if (s == BluetoothAdapterState.on) _startScanning();
    });
    FlutterBluePlus.isScanning.listen((v) {
      if (mounted) setState(() => _isScanning = v);
    });
    _init();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus.stopScan().catchError((_) {});
    super.dispose();
  }

  Future<void> _init() async {
    await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();
    final state = await FlutterBluePlus.adapterState.first;
    if (state == BluetoothAdapterState.on) await _startScanning();
  }

  Future<void> _startScanning() async {
    if (_isScanning) return;
    try {
      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.onScanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          for (final r in results) {
            _results[r.device.remoteId.toString()] = r;
          }
        });
      });
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
        androidUsesFineLocation: false,
      );
    } catch (_) {}
  }

  Color _rssiColor(int rssi) {
    if (rssi >= -60) return const Color(0xFF27AE60);
    if (rssi >= -75) return const Color(0xFF2980B9);
    if (rssi >= -85) return const Color(0xFFF59E0B);
    return const Color(0xFFE74C3C);
  }

  double _distanceM(int rssi) => pow(10.0, (-59 - rssi) / 20.0).toDouble();

  String _name(ScanResult r) {
    final n = r.advertisementData.advName.isNotEmpty
        ? r.advertisementData.advName
        : r.device.platformName;
    return n.isNotEmpty ? n : 'N/A';
  }

  void _select(ScanResult r) {
    FlutterBluePlus.stopScan().catchError((_) {});
    Navigator.pop(context, r.device.remoteId.toString());
  }

  @override
  Widget build(BuildContext context) {
    final adapterOff = _adapterState == BluetoothAdapterState.off ||
        _adapterState == BluetoothAdapterState.unavailable;

    final sorted = _results.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

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
            const Text('Select BLE Device',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
            Text(
              _isScanning ? 'Scanning… tap a device to link it' : 'Tap a device to link it',
              style: TextStyle(
                  fontSize: 11,
                  color: _isScanning ? AppColors.primary : AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isScanning ? Icons.stop_rounded : Icons.refresh_rounded,
              color: _isScanning ? AppColors.error : AppColors.primary,
            ),
            onPressed: _isScanning
                ? () => FlutterBluePlus.stopScan()
                : _startScanning,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: adapterOff
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bluetooth_disabled_rounded,
                      size: 60, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text('Bluetooth is off',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textH)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      try { await FlutterBluePlus.turnOn(); } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Enable Bluetooth'),
                  ),
                ],
              ),
            )
          : sorted.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bluetooth_searching_rounded,
                          size: 60,
                          color: AppColors.textMuted.withValues(alpha: 0.3)),
                      const SizedBox(height: 14),
                      Text(
                        _isScanning
                            ? 'Scanning for devices…'
                            : 'No devices found.\nTap refresh to scan.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textBody, height: 1.6),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, indent: 72, color: Color(0xFFF0F0F0)),
                  itemBuilder: (_, i) {
                    final r = sorted[i];
                    final mac = r.device.remoteId.toString();
                    final name = _name(r);
                    final dist = _distanceM(r.rssi);
                    final distStr = dist < 100
                        ? '${dist.toStringAsFixed(2)} m'
                        : '>100 m';

                    return InkWell(
                      onTap: () => _select(r),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Signal circle
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _rssiColor(r.rssi),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(r.rssi.toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  const Text('dBm',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 9)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textH)),
                                  const SizedBox(height: 2),
                                  Text(mac,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textBody)),
                                  const SizedBox(height: 2),
                                  Text(distStr,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('SELECT',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}


