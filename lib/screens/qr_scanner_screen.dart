import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/department.dart';
import '../utils/app_colors.dart';
import '../utils/app_l10n.dart';
import 'dept_rooms_screen.dart';
import 'product_detail_screen.dart';
import 'maintenance_screen.dart';
import 'rfid_screen.dart';
import 'ble_screen.dart';

final _baseHost = ApiService.baseUrl.replaceAll('/api', '');

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isCameraTab = true;
  bool _isSearching = false;
  bool _scanned = false;
  bool _cameraActive = true;
  bool _processing = false;
  String? _scanError; // non-null = camera stopped after a failed scan
  bool _historyLoading = true;
  bool _isLoadingSuggestions = false;
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  final _manualController = TextEditingController();
  final _manualFocus = FocusNode();
  final MobileScannerController _cameraController = MobileScannerController(
    formats: const [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.normal,
  );
  final List<Map<String, String>> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final rows = await ApiService.getScanHistory();
      if (!mounted) return;
      final parsed = <Map<String, String>>[];
      for (final r in rows) {
        final map = r as Map<String, dynamic>;
        parsed.add({
          'name': (map['name'] ?? '').toString(),
          'code': (map['sku'] ?? '').toString(),
          'time': _formatTime((map['scanned_at'] ?? '').toString()),
          'id': (map['product_id'] ?? '').toString(),
        });
      }
      setState(() {
        _recentScans
          ..clear()
          ..addAll(parsed);
        _historyLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _historyLoading = false);
        _snack('Could not load scan history');
      }
    }
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cameraController.dispose();
    _manualController.dispose();
    _manualFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _suggestions = []; _isLoadingSuggestions = false; });
      return;
    }
    setState(() => _isLoadingSuggestions = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await ApiService.searchProducts(value);
        if (!mounted) return;
        setState(() {
          _suggestions = results
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
          _isLoadingSuggestions = false;
        });
      } catch (_) {
        if (mounted) setState(() => _isLoadingSuggestions = false);
      }
    });
  }

  Future<void> _selectSuggestion(Map<String, dynamic> product) async {
    _manualFocus.unfocus();
    setState(() => _suggestions = []);
    _manualController.text = product['name'] as String;
    final p = Product.fromJson(product);
    _addRecentScan(p);
    await ApiService.addScanHistory(p.id);
    await _showProductDialog(p);
  }

  // â”€â”€â”€ Core logic â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _onQRDetected(String raw) async {
    if (_isSearching) return;
    setState(() { _isSearching = true; _scanned = true; });

    try {
      final trimmed = raw.trim();

      // â”€â”€ ISET hierarchical QR codes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (trimmed == 'ISET://institution') {
        setState(() { _isSearching = false; _scanned = false; });
        if (mounted) Navigator.pushNamed(context, '/vueinstitut');
        return;
      }

      if (trimmed.startsWith('ISET://dept/')) {
        final code = trimmed.substring('ISET://dept/'.length).trim();
        setState(() { _isSearching = false; _scanned = false; });
        if (!mounted) return;
        // Load departments to find the one matching this code
        final depts = await ApiService.getDepartments();
        final match = depts.cast<Map<String, dynamic>>()
            .where((d) => d['code'] == code)
            .toList();
        if (match.isEmpty) {
          _snack('Department "$code" not found');
          return;
        }
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => DeptRoomsScreen(
              department: Department.fromJson(match.first),
            ),
          ));
        }
        return;
      }

      // â”€â”€ Product QR (UUID) or physical barcode â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      // Try UUID first (product QR code)
      String? productId;
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.queryParameters.containsKey('id')) {
        productId = uri.queryParameters['id'];
      } else if (uuidRegex.hasMatch(trimmed)) {
        productId = trimmed;
      }

      if (productId != null) {
        final data = await ApiService.getProduct(productId);
        if (!mounted) return;
        if (data['success'] == true) {
          final product = Product.fromJson(data['data'] as Map<String, dynamic>);
          _addRecentScan(product);
          await ApiService.addScanHistory(product.id);
          await _showProductDialog(product);
        } else {
          await _showScanError(data['message'] ?? 'Product not found');
        }
        return;
      }

      // Not a UUID â€” try as a physical barcode
      final barcodeRes = await ApiService.checkBarcode(trimmed);
      if (!mounted) return;
      if (barcodeRes['exists'] == true && barcodeRes['data'] != null) {
        final fullData = await ApiService.getProduct((barcodeRes['data'] as Map)['id'] as String);
        if (!mounted) return;
        if (fullData['success'] == true) {
          final product = Product.fromJson(fullData['data'] as Map<String, dynamic>);
          _addRecentScan(product);
          await ApiService.addScanHistory(product.id);
          await _showProductDialog(product);
        } else {
          await _showScanError('Product not found');
        }
      } else {
        await _showScanError('No product registered for this barcode');
      }
    } catch (e) {
      if (!mounted) return;
      await _showScanError('Error: $e');
    } finally {
      _processing = false;
      if (mounted) setState(() { _isSearching = false; _scanned = false; });
    }
  }

  void _addRecentScan(Product p) {
    setState(() {
      _recentScans.removeWhere((s) => s['id'] == p.id);
      _recentScans.insert(0, {
        'name': p.name,
        'code': p.sku,
        'time': 'Just now',
        'id': p.id,
      });
      if (_recentScans.length > 20) _recentScans.removeLast();
    });
  }

  Future<void> _showScanError(String message) async {
    await _cameraController.stop();
    if (mounted) setState(() { _cameraActive = false; _scanError = message; });
  }

  Future<void> _resumeCamera() async {
    setState(() { _scanError = null; _cameraActive = true; });
    await _cameraController.start();
  }

  Future<void> _showProductDialog(Product product) async {
    await _cameraController.stop();
    await _showQuickActions(product);
    if (mounted && _cameraActive) await _cameraController.start();
  }

  Future<void> _showQuickActions(Product product) async {
    final baseHost = ApiService.baseUrl.replaceAll('/api', '');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickActionsSheet(
        product:  product,
        baseHost: baseHost,
        onAction: (action) async {
          Navigator.pop(ctx);
          switch (action) {
            case 'view':
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product)));
              break;
            case 'move':
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product, initiallyEditing: true)));
              break;
            case 'issue':
              await ApiService.updateProductStatus(product.id, 'critical_issue');
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Item marked as critical issue'),
                backgroundColor: Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ));
              break;
            case 'maintenance':
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => const MaintenanceScreen()));
              break;
            case 'history':
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product)));
              break;
          }
        },
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _cameraController.stop();
        if (context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () async {
            await _cameraController.stop();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QR Code Scanner',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textH)),
            Text('Scan to retrieve product info',
                style: TextStyle(fontSize: 12, color: AppColors.textBody)),
          ],
        ),
        actions: [
          // Flash toggle (camera tab only)
          if (_isCameraTab)
            IconButton(
              icon: Icon(
                _cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off,
                color: _cameraController.torchEnabled ? Colors.amber : AppColors.textH,
              ),
              onPressed: () => _cameraController.toggleTorch(),
            ),
          IconButton(
            icon: const Icon(Icons.nfc_rounded, color: Color(0xFF6D28D9)),
            tooltip: 'RFID Scanner',
            onPressed: () {
              _cameraController.stop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RfidScreen()),
              ).then((_) {
                if (mounted && _cameraActive) _cameraController.start();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth_searching_rounded, color: Color(0xFF2563EB)),
            tooltip: 'BLE Scanner',
            onPressed: () {
              _cameraController.stop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BleScreen()),
              ).then((_) {
                if (mounted && _cameraActive) _cameraController.start();
              });
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE0E0E0)),
        ),
      ),
      body: Column(
        children: [
          // Tab switcher
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildTab(Icons.camera_alt_outlined, 'Camera Scan', _isCameraTab, () {
                    setState(() => _isCameraTab = true);
                  }),
                  _buildTab(Icons.keyboard_outlined, 'Manual Entry', !_isCameraTab, () {
                    setState(() => _isCameraTab = false);
                  }),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isCameraTab ? _buildCameraView() : _buildManualEntry(),
          ),
        ],
      ),
    ),   // Scaffold
    );   // PopScope
  }

  // â”€â”€â”€ Camera tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildCameraView() {
    return SingleChildScrollView(
      child: Column(
        children: [
        // Scanner area
        SizedBox(
          height: 360,
          child: _cameraActive ? Stack(
            children: [
              MobileScanner(
                controller: _cameraController,
                onDetect: (capture) {
                  if (_processing || _scanned || _isSearching || capture.barcodes.isEmpty) return;
                  final b = capture.barcodes.first;
                  final code = b.rawValue ?? b.displayValue;
                  if (code != null && code.isNotEmpty) {
                    _processing = true;
                    _onQRDetected(code);
                  }
                },
              ),
              // Overlay frame
              Center(
                child: Container(
                  width: 240, height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                  ),
                  child: Stack(
                    children: [
                      _corner(Alignment.topLeft, left: true, top: true),
                      _corner(Alignment.topRight, left: false, top: true),
                      _corner(Alignment.bottomLeft, left: true, top: false),
                      _corner(Alignment.bottomRight, left: false, top: false),
                    ],
                  ),
                ),
              ),
              // Close camera button
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    _cameraController.stop();
                    setState(() { _cameraActive = false; _scanError = null; });
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
              // Status badge
              Positioned(
                bottom: 24,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSearching) ...[
                          const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Text('Looking up product...',
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                        ] else ...[
                          const Icon(Icons.sync, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          const Text('Scanning QR codes & barcodes...',
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ) : Container(
            color: Colors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: _scanError != null
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _scanError != null ? Icons.search_off : Icons.videocam_off,
                        color: _scanError != null ? Colors.redAccent : Colors.white54,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _scanError ?? 'Camera stopped',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _scanError != null ? Colors.redAccent : Colors.white54,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _resumeCamera,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(_scanError != null ? 'Scan Again' : 'Resume Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Recent scans
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildRecentScans(),
        ),
      ],
    ),
    );
  }

  // â”€â”€â”€ Manual entry tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.search, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search Product',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textH)),
                  Text('By name, SKU or barcode',
                      style: TextStyle(fontSize: 12, color: AppColors.textBody)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: TextField(
              controller: _manualController,
              focusNode: _manualFocus,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onQRDetected(_manualController.text),
              decoration: InputDecoration(
                hintText: 'Name, SKU, barcode or QR URL…',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoadingSuggestions)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                      )
                    else if (_manualController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                        onPressed: () {
                          _manualController.clear();
                          setState(() => _suggestions = []);
                        },
                      ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),

          // Live suggestions
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text('${_suggestions.length} result${_suggestions.length > 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
                      ],
                    ),
                  ),
                  ...List.generate(_suggestions.length, (i) {
                    final s = _suggestions[i];
                    final isLast = i == _suggestions.length - 1;
                    return InkWell(
                      onTap: () => _selectSuggestion(s),
                      borderRadius: BorderRadius.vertical(
                        bottom: isLast ? const Radius.circular(12) : Radius.zero,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: !isLast
                              ? const Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.bgMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: s['photo_url'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        '$_baseHost${s['photo_url']}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 22),
                                      ),
                                    )
                                  : const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(s['sku'] ?? '',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
                                      if (s['category_name'] != null) ...[
                                        const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                                        Text(s['category_name'],
                                            style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (s['quantity'] ?? 0) > 0
                                        ? const Color(0xFFE6F9F2)
                                        : const Color(0xFFFFF0F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Qty ${s['quantity'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: (s['quantity'] ?? 0) > 0
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // No results hint
          if (!_isLoadingSuggestions && _suggestions.isEmpty && _manualController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_off, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No product found for "${_manualController.text}".\nTry searching by SKU or UUID.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textBody),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Search by UUID button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSearching || _manualController.text.trim().isEmpty
                  ? null
                  : () => _onQRDetected(_manualController.text),
              icon: _isSearching
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.qr_code, size: 18),
              label: const Text('Search by UUID / QR URL'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildRecentScans(),
        ],
      ),
    );
  }

  // â”€â”€â”€ Recent scans â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildRecentScans() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Recent Scans',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textH)),
            ],
          ),
          const SizedBox(height: 12),
          if (_historyLoading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ))
          else if (_recentScans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No scans yet', style: TextStyle(color: AppColors.textBody, fontSize: 13)),
              ),
            )
          else
          ..._recentScans.map((scan) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgPage,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_2, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(scan['name']!,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH)),
                          Text('${scan['code']} · ${scan['time']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F9F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Found',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTab(IconData icon, String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.textH : AppColors.textBody),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? AppColors.textH : AppColors.textBody)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corner(Alignment alignment, {required bool left, required bool top}) {
    // ignore: dead_code - kept below
    return Align(
      alignment: alignment,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          border: Border(
            left: left ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
            right: !left ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
            top: top ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
            bottom: !top ? const BorderSide(color: AppColors.primary, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Quick actions bottom sheet ─────────────────────────────────────────────────

class _QuickActionsSheet extends StatelessWidget {
  final Product  product;
  final String   baseHost;
  final void Function(String action) onAction;
  const _QuickActionsSheet({required this.product, required this.baseHost, required this.onAction});

  static const _statusColors = {
    'in_stock': Color(0xFF10B981), 'operational': Color(0xFF4F46E5),
    'in_maintenance': Color(0xFFF59E0B), 'critical_issue': Color(0xFFEF4444),
    'retired': Color(0xFF6B7280), 'lost': Color(0xFF8B5CF6),
  };

  @override
  Widget build(BuildContext context) {
    final sColor = _statusColors[product.status] ?? AppColors.textMuted;
    final l10n   = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Container(margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),

        // Product header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.photoUrl != null
                  ? Image.network('$baseHost${product.photoUrl}', width: 56, height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: const TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w800, color: AppColors.textH),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(product.sku, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: sColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(product.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sColor)),
              ),
            ])),
            if (product.roomName != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                Text(product.departmentCode ?? '', style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
                Text(product.roomName!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ]),
          ]),
        ),

        const Divider(height: 24, indent: 20, endIndent: 20),

        // Action grid
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: GridView.count(
            crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: [
              _ActionTile(Icons.open_in_new_rounded,   AppColors.primary,           l10n.viewDetails,     () => onAction('view')),
              _ActionTile(Icons.swap_horiz_rounded,    const Color(0xFF0EA5E9),     l10n.moveItem,        () => onAction('move')),
              _ActionTile(Icons.warning_amber_rounded, const Color(0xFFEF4444),     l10n.reportIssue,     () => onAction('issue')),
              _ActionTile(Icons.build_rounded,         const Color(0xFFF59E0B),     l10n.startMaintenance,() => onAction('maintenance')),
              _ActionTile(Icons.timeline_rounded,      const Color(0xFF8B5CF6),     l10n.viewHistory,     () => onAction('history')),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(width: 56, height: 56,
      color: AppColors.bgMuted, child: const Icon(Icons.devices_other,
          color: AppColors.textMuted, size: 28));
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(this.icon, this.color, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}
