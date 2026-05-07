import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/department.dart';
import '../utils/app_colors.dart';
import 'dept_rooms_screen.dart';

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
  bool _historyLoading = true;
  bool _isLoadingSuggestions = false;
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  final _manualController = TextEditingController();
  final _manualFocus = FocusNode();
  final MobileScannerController _cameraController = MobileScannerController();
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

  // ─── Core logic ─────────────────────────────────────────────────────────────

  Future<void> _onQRDetected(String raw) async {
    if (_isSearching) return;
    setState(() { _isSearching = true; _scanned = true; });

    try {
      final trimmed = raw.trim();

      // ── ISET hierarchical QR codes ──────────────────────────────────────────
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

      // ── Product QR ──────────────────────────────────────────────────────────
      String? productId;
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.queryParameters.containsKey('id')) {
        productId = uri.queryParameters['id'];
      } else {
        productId = trimmed;
      }

      if (productId == null || productId.isEmpty) {
        _snack('Invalid QR code');
        return;
      }

      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      if (!uuidRegex.hasMatch(productId)) {
        _snack('QR code is not a valid product code');
        return;
      }

      final data = await ApiService.getProductByQR(productId);
      if (!mounted) return;

      if (data['success'] == true) {
        final product = Product.fromJson(data['data'] as Map<String, dynamic>);
        _addRecentScan(product);
        await ApiService.addScanHistory(product.id);
        await _showProductDialog(product);
      } else {
        _snack(data['message'] ?? 'Product not found');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e');
    } finally {
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

  Future<void> _showProductDialog(Product product) async {
    // Stop camera while dialog is on screen to prevent white-screen on resume
    await _cameraController.stop();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Product Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '$_baseHost${product.photoUrl}',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 12),
            Text(product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            _row('SKU', product.sku),
            if (product.categoryName != null) _row('Type', product.categoryName!),
            _row('Quantity', product.quantity.toString()),
            if (product.price != null) _row('Price', '${product.price!.toStringAsFixed(2)} TND'),
            if (product.storageLocation != null) _row('Location', product.storageLocation!),
            if (product.description != null) ...[
              const SizedBox(height: 6),
              Text(product.description!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.textBody)),
          ),
        ],
      ),
    );
    // Restart camera after dialog is dismissed
    if (mounted && _cameraActive) {
      await _cameraController.start();
    }
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ─── Build ───────────────────────────────────────────────────────────────────

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
      backgroundColor: AppColors.bgPage,
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

  // ─── Camera tab ──────────────────────────────────────────────────────────────

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
                  if (_scanned || _isSearching) return;
                  final code = capture.barcodes.first.rawValue;
                  if (code != null) _onQRDetected(code);
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
                    setState(() => _cameraActive = false);
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
                          const Text('Scanning for QR codes...',
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                  const SizedBox(height: 16),
                  const Text('Camera stopped',
                      style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      _cameraController.start();
                      setState(() => _cameraActive = true);
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('Resume Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
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

  // ─── Manual entry tab ────────────────────────────────────────────────────────

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

  // ─── Recent scans ────────────────────────────────────────────────────────────

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

  // ─── Helpers ─────────────────────────────────────────────────────────────────

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
