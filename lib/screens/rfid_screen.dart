import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'product_detail_screen.dart';

enum _ScreenState { scanning, looking, found, notFound, error }

class RfidScreen extends StatefulWidget {
  const RfidScreen({super.key});

  @override
  State<RfidScreen> createState() => _RfidScreenState();
}

class _RfidScreenState extends State<RfidScreen>
    with SingleTickerProviderStateMixin {
  _ScreenState _state = _ScreenState.scanning;
  String? _errorMessage;
  String? _scannedUid;
  Product? _foundProduct;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _startSession();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() {
      _state = _ScreenState.scanning;
      _scannedUid = null;
      _foundProduct = null;
      _errorMessage = null;
    });

    final availability = await NfcManager.instance.checkAvailability();
    if (!mounted) return;

    if (availability != NfcAvailability.enabled) {
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = availability == NfcAvailability.disabled
            ? 'NFC is disabled.\nPlease enable NFC in Settings.'
            : 'NFC is not available on this device.';
      });
      return;
    }

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          final uid = _extractUid(tag);
          await NfcManager.instance.stopSession();
          if (!mounted) return;
          setState(() { _state = _ScreenState.looking; _scannedUid = uid; });
          await _lookupProduct(uid);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScreenState.error;
          _errorMessage = 'Could not start NFC session: $e';
        });
      }
    }
  }

  String _extractUid(NfcTag tag) {
    final androidTag = NfcTagAndroid.from(tag);
    if (androidTag != null && androidTag.id.isNotEmpty) {
      return androidTag.id
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(':');
    }
    return 'Unknown';
  }

  Future<void> _lookupProduct(String uid) async {
    try {
      final res = await ApiService.getProductByRfid(uid);
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        final product = Product.fromJson(res['data'] as Map<String, dynamic>);
        setState(() { _state = _ScreenState.found; _foundProduct = product; });
      } else {
        setState(() => _state = _ScreenState.notFound);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScreenState.error;
          _errorMessage = 'Lookup failed: $e';
        });
      }
    }
  }

  void _openProduct() {
    if (_foundProduct == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: _foundProduct!,
          initiallyEditing: true,
        ),
      ),
    );
  }

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RFID Scanner',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
            Text('Scan a tag to find the linked item',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Scan History',
            icon: const Icon(Icons.history_rounded, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, '/rfid-scan-history'),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: () {
        switch (_state) {
          case _ScreenState.scanning:
            return _buildScanningView();
          case _ScreenState.looking:
            return _buildLookingView();
          case _ScreenState.found:
            return _buildFoundView();
          case _ScreenState.notFound:
            return _buildNotFoundView();
          case _ScreenState.error:
            return _buildErrorView();
        }
      }(),
    );
  }

  // â”€â”€â”€ Scanning view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildScanningView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5F3FF),
                  border: Border.all(color: const Color(0xFF6D28D9), width: 2),
                ),
                child: const Icon(Icons.nfc_rounded, size: 72, color: Color(0xFF6D28D9)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Approach an RFID Tag',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textH)),
            const SizedBox(height: 12),
            const Text(
              'Hold the RFID/NFC tag close to the\nback of your phone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.6),
            ),
            const SizedBox(height: 40),
            _WaitingDots(),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ Looking up view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildLookingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F3FF),
                border: Border.all(color: const Color(0xFF6D28D9), width: 2),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF6D28D9),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text('Tag Detected',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textH)),
            const SizedBox(height: 8),
            if (_scannedUid != null)
              Text(_scannedUid!,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6D28D9),
                      fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            const Text('Looking up product...',
                style: TextStyle(fontSize: 14, color: AppColors.textBody)),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ Found view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildFoundView() {
    final p = _foundProduct!;
    final statusColor = {
      'operational': const Color(0xFF4F46E5), 'in_stock': const Color(0xFF10B981),
      'in_maintenance': const Color(0xFFF59E0B), 'critical_issue': const Color(0xFFEF4444),
      'retired': const Color(0xFF6B7280), 'lost': const Color(0xFF8B5CF6),
    }[p.status] ?? AppColors.primary;
    final statusLabel = {
      'operational': 'Operational', 'in_stock': 'In Stock',
      'in_maintenance': 'In Maintenance', 'critical_issue': 'Critical Issue',
      'retired': 'Retired', 'lost': 'Lost',
    }[p.status] ?? p.status;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Success banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
                SizedBox(width: 10),
                Text('Product Found!',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tag UID
          _infoCard(
            icon: Icons.nfc_rounded,
            iconColor: const Color(0xFF6D28D9),
            bgColor: const Color(0xFFF5F3FF),
            title: 'RFID Tag UID',
            value: _scannedUid ?? '',
          ),
          const SizedBox(height: 10),

          // Product info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.shadowMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.bgMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.textMuted, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold, color: AppColors.textH)),
                          Text(p.sku,
                              style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ),
                  ],
                ),
                if (p.departmentName != null || p.roomName != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [p.departmentName, p.roomName]
                              .where((v) => v != null)
                              .join(' → '),
                          style: const TextStyle(fontSize: 13, color: AppColors.textBody),
                        ),
                      ),
                    ],
                  ),
                ],
                if (p.type != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.category_outlined,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(p.type!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openProduct,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Edit This Item',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.nfc_rounded, size: 18, color: AppColors.textBody),
              label: const Text('Scan Another Tag',
                  style: TextStyle(color: AppColors.textBody, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Not found view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildNotFoundView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF8E6),
                border: Border.all(color: const Color(0xFFF59E0B), width: 2),
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 60, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 28),
            const Text('No Product Found',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textH)),
            const SizedBox(height: 12),
            if (_scannedUid != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_scannedUid!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textBody,
                        fontWeight: FontWeight.w600, letterSpacing: 0.6)),
              ),
            const SizedBox(height: 12),
            const Text(
              'No item is registered with this RFID tag.\nAssign this tag to an item from its detail screen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.6),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startSession,
                icon: const Icon(Icons.nfc_rounded, size: 20),
                label: const Text('Scan Again',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ Error view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorBg,
                border: Border.all(color: AppColors.error, width: 2),
              ),
              child: const Icon(Icons.nfc_rounded, size: 60, color: AppColors.error),
            ),
            const SizedBox(height: 28),
            const Text('NFC Unavailable',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textH)),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.6),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: iconColor, letterSpacing: 0.4)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textH, letterSpacing: 0.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Animated waiting dots â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WaitingDots extends StatefulWidget {
  @override
  State<_WaitingDots> createState() => _WaitingDotsState();
}

class _WaitingDotsState extends State<_WaitingDots> {
  int _active = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (mounted) setState(() => _active = (_active + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: i == _active ? 13 : 8,
        height: i == _active ? 13 : 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i == _active
              ? const Color(0xFF6D28D9)
              : const Color(0xFF6D28D9).withValues(alpha: 0.25),
        ),
      )),
    );
  }
}


