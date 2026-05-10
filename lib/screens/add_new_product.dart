import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../utils/image_picker_helper.dart';

// ─── Spec field definition ────────────────────────────────────────────────────

class _SpecField {
  final String key;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  const _SpecField(this.key, this.label, this.hint, this.icon,
      {this.keyboard = TextInputType.text});
}

const Map<String, List<_SpecField>> _typeSpecs = {
  'Computer': [
    _SpecField('cpu',          'CPU Model',          'e.g., Intel Core i7-12700',  Icons.memory),
    _SpecField('ram_gb',       'RAM (GB)',            'e.g., 16',                   Icons.storage,       keyboard: TextInputType.number),
    _SpecField('storage_gb',   'Storage (GB)',        'e.g., 512',                  Icons.save,          keyboard: TextInputType.number),
    _SpecField('os',           'Operating System',   'e.g., Windows 11 Pro',       Icons.laptop_windows),
    _SpecField('color',        'Color',               'e.g., Silver',               Icons.palette),
    _SpecField('screen_inch',  'Screen Size (inch)',  'e.g., 15.6',                 Icons.monitor,       keyboard: TextInputType.numberWithOptions(decimal: true)),
  ],
  'Server': [
    _SpecField('cpu',          'CPU Model',     'e.g., Xeon E5-2680',       Icons.memory),
    _SpecField('ram_gb',       'RAM (GB)',       'e.g., 64',                 Icons.storage,   keyboard: TextInputType.number),
    _SpecField('storage_tb',   'Storage (TB)',   'e.g., 2',                  Icons.save,      keyboard: TextInputType.numberWithOptions(decimal: true)),
    _SpecField('form_factor',  'Form Factor',   'e.g., 1U, 2U, Tower',     Icons.view_agenda),
    _SpecField('os',           'OS',            'e.g., Ubuntu Server 22.04',Icons.terminal),
  ],
  'Network Device': [
    _SpecField('sub_type',    'Device Type',      'e.g., Switch, Router, AP',     Icons.router),
    _SpecField('ports',       'Number of Ports',  'e.g., 24',                     Icons.cable,    keyboard: TextInputType.number),
    _SpecField('speed_mbps',  'Speed (Mbps)',     'e.g., 1000',                   Icons.speed,    keyboard: TextInputType.number),
    _SpecField('protocol',    'Protocol',         'e.g., IEEE 802.11ac',          Icons.wifi),
  ],
  'Peripheral': [
    _SpecField('sub_type',   'Peripheral Type',  'e.g., Mouse, Keyboard, Headset', Icons.mouse),
    _SpecField('interface',  'Interface',         'e.g., USB, Bluetooth, PS/2',    Icons.usb),
    _SpecField('color',      'Color',             'e.g., Black',                   Icons.palette),
  ],
  'Printer/Scanner': [
    _SpecField('sub_type',         'Device Type',        'e.g., Laser, Inkjet, Flatbed',  Icons.print),
    _SpecField('print_speed_ppm',  'Print Speed (ppm)',  'e.g., 30',                      Icons.speed,       keyboard: TextInputType.number),
    _SpecField('resolution_dpi',   'Resolution (DPI)',   'e.g., 1200',                    Icons.tune,        keyboard: TextInputType.number),
    _SpecField('color_capable',    'Color Print',        'e.g., Yes / No',                Icons.color_lens),
  ],
  'Display': [
    _SpecField('screen_inch',   'Screen Size (inch)',  'e.g., 27',          Icons.monitor,  keyboard: TextInputType.numberWithOptions(decimal: true)),
    _SpecField('resolution',    'Resolution',          'e.g., 1920x1080',   Icons.hd),
    _SpecField('panel_type',    'Panel Type',          'e.g., IPS, VA, TN', Icons.layers),
    _SpecField('refresh_hz',    'Refresh Rate (Hz)',   'e.g., 60, 144',     Icons.refresh,  keyboard: TextInputType.number),
  ],
  'Projector': [
    _SpecField('lumens',       'Brightness (Lumens)',  'e.g., 3000',     Icons.light_mode,  keyboard: TextInputType.number),
    _SpecField('resolution',   'Resolution',           'e.g., Full HD',  Icons.hd),
    _SpecField('throw_ratio',  'Throw Ratio',          'e.g., 1.5:1',    Icons.crop_free),
  ],
  'Machine Tool': [
    _SpecField('power_w',       'Power (W)',        'e.g., 1500',  Icons.bolt,   keyboard: TextInputType.number),
    _SpecField('max_speed_rpm', 'Max Speed (RPM)',  'e.g., 3000',  Icons.speed,  keyboard: TextInputType.number),
    _SpecField('weight_kg',     'Weight (kg)',      'e.g., 25',    Icons.scale,  keyboard: TextInputType.numberWithOptions(decimal: true)),
  ],
};

// ─── Screen ───────────────────────────────────────────────────────────────────

class AddNewProductScreen extends StatefulWidget {
  const AddNewProductScreen({super.key});

  @override
  State<AddNewProductScreen> createState() => _AddNewProductScreenState();
}

class _AddNewProductScreenState extends State<AddNewProductScreen> {
  final _itemNameController    = TextEditingController();
  final _skuController         = TextEditingController();
  final _barcodeController     = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController        = TextEditingController();
  final _quantityController    = TextEditingController(text: '0');
  final _priceController       = TextEditingController(text: '0.00');
  final _stockController       = TextEditingController();

  // Dynamic spec controllers keyed by field key
  final Map<String, TextEditingController> _specControllers = {};

  String? _selectedCategoryId;
  int     _descriptionLength = 0;
  XFile?  _pickedXFile;
  Uint8List? _imageBytes;
  bool    _isLoading  = false;
  bool    _skuIsAuto  = true;

  // Barcode lookup state
  Timer?                   _barcodeDebounce;
  bool                     _barcodeChecking = false;
  Map<String, dynamic>?    _barcodeMatch;
  bool                     _barcodeDismissed = false;

  List<Map<String, String>> _categories = [];

  // Storage location type: 'room' or 'stock'
  String _locationType = 'room';

  // Room assignment state
  List<Map<String, dynamic>> _departments = [];
  String? _selectedDeptId;
  List<Map<String, dynamic>> _deptRooms = [];
  bool _roomsLoading = false;
  String? _selectedRoomId;

  static const _gradientColors = [Color(0xFF4F46E5), Color(0xFF7C3AED)];

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(
      () => setState(() => _descriptionLength = _descriptionController.text.length),
    );
    _barcodeController.addListener(_onBarcodeChanged);
    _loadCategories();
    _loadDepartments();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    for (final c in _specControllers.values) c.dispose();
    _barcodeDebounce?.cancel();
    super.dispose();
  }

  // ─── Category / spec helpers ─────────────────────────────────────────────────

  Future<void> _loadCategories() async {
    try {
      final data = await ApiService.getCategories();
      if (data['success'] == true && mounted) {
        final list = (data['data'] as List)
            .map((c) => {'id': c['id'].toString(), 'name': c['name'].toString()})
            .toList();
        setState(() => _categories = list);
      }
    } catch (_) {}
  }

  Future<void> _loadDepartments() async {
    try {
      final list = await ApiService.getDepartments();
      if (mounted) {
        setState(() => _departments = list.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _loadRoomsForDept(String deptId) async {
    setState(() { _roomsLoading = true; _deptRooms = []; _selectedRoomId = null; });
    try {
      final list = await ApiService.getDepartmentRooms(deptId);
      if (mounted) {
        setState(() { _deptRooms = list.cast<Map<String, dynamic>>(); _roomsLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _roomsLoading = false);
    }
  }

  String? get _selectedCategoryName => _categories
      .where((c) => c['id'] == _selectedCategoryId)
      .map((c) => c['name'])
      .firstOrNull;

  List<_SpecField> get _currentSpecFields =>
      _typeSpecs[_selectedCategoryName] ?? [];

  void _onTypeChanged(String? id) {
    // Dispose old spec controllers
    for (final c in _specControllers.values) c.dispose();
    _specControllers.clear();

    setState(() => _selectedCategoryId = id);

    // Create controllers for new type's fields
    final name = _categories.where((c) => c['id'] == id).map((c) => c['name']).firstOrNull;
    if (name != null) {
      for (final f in (_typeSpecs[name] ?? [])) {
        _specControllers[f.key] = TextEditingController();
      }
    }
  }

  Map<String, dynamic> _collectSpecs() {
    final specs = <String, dynamic>{};
    for (final f in _currentSpecFields) {
      final val = _specControllers[f.key]?.text.trim() ?? '';
      if (val.isNotEmpty) specs[f.key] = val;
    }
    return specs;
  }

  // ─── Barcode lookup ──────────────────────────────────────────────────────────

  void _onBarcodeChanged() {
    final barcode = _barcodeController.text.trim();
    _barcodeDebounce?.cancel();

    if (barcode.isEmpty) {
      setState(() { _barcodeMatch = null; _barcodeDismissed = false; });
      return;
    }

    setState(() { _barcodeChecking = true; _barcodeDismissed = false; });
    _barcodeDebounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final res = await ApiService.checkBarcode(barcode);
        if (!mounted) return;
        setState(() {
          _barcodeChecking = false;
          _barcodeMatch = (res['exists'] == true) ? res['data'] as Map<String, dynamic> : null;
        });
      } catch (_) {
        if (mounted) setState(() => _barcodeChecking = false);
      }
    });
  }

  void _applyBarcodeModel(Map<String, dynamic> model) {
    _itemNameController.text    = model['name'] ?? '';
    _descriptionController.text = model['description'] ?? '';
    _tagsController.text        = ((model['tags'] as List?)?.join(', ')) ?? '';
    _priceController.text       = model['price']?.toString() ?? '0.00';

    // Set type
    final catId = model['category_id']?.toString();
    _onTypeChanged(catId);

    // Fill specs
    final specs = model['specifications'];
    if (specs is Map) {
      for (final entry in specs.entries) {
        _specControllers[entry.key]?.text = entry.value?.toString() ?? '';
      }
    }

    setState(() => _barcodeDismissed = true);
  }

  // ─── Image ───────────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    debugPrint('[ADD_PRODUCT] _pickImage called source=$source');
    try {
      final (file, bytes) =
          await pickImageFromSource(source == ImageSource.camera);
      debugPrint('[ADD_PRODUCT] file=$file bytesLen=${bytes?.length}');
      if (file == null || !mounted) return;
      setState(() { _pickedXFile = file; _imageBytes = bytes; });
      debugPrint('[ADD_PRODUCT] _imageBytes set: ${_imageBytes?.length} bytes');
    } catch (e, st) {
      debugPrint('[ADD_PRODUCT] picker error: $e\n$st');
      if (!mounted) return;
      _snack('Photo error: $e');
    }
  }

  // ─── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final name = _itemNameController.text.trim();
    if (name.isEmpty) { _snack('Item name is required'); return; }
    if (_selectedCategoryId == null) { _snack('Please select a type'); return; }

    final qty      = int.tryParse(_quantityController.text) ?? 0;
    final price    = double.tryParse(_priceController.text);
    final tags     = _tagsController.text.trim().isEmpty
        ? <String>[]
        : _tagsController.text.split(',').map((t) => t.trim()).toList();
    final specs = _collectSpecs();

    setState(() => _isLoading = true);
    debugPrint('[SUBMIT] photo=${_pickedXFile?.name} imageBytes=${_imageBytes?.length}');
    try {
      final stockLoc = _locationType == 'stock' ? _stockController.text.trim() : null;
      final data = await ApiService.createProduct(
        name:            name,
        sku:             _skuIsAuto ? null : _skuController.text.trim(),
        type:            _selectedCategoryId,
        barcode:         _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        description:     _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        tags:            tags.isEmpty ? null : tags,
        quantity:        qty,
        price:           price,
        storageLocation: stockLoc?.isEmpty == true ? null : stockLoc,
        roomId:          _locationType == 'room' ? _selectedRoomId : null,
        photo:           _pickedXFile,
        photoBytes:      _imageBytes,
        specifications:  specs.isEmpty ? null : specs,
      );

      if (!mounted) return;
      if (data['success'] == true) {
        final product = data['data'] as Map;
        _showSuccessDialog(product);
      } else {
        _snack(data['message'] ?? 'Failed to add product');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Dialogs / snack ─────────────────────────────────────────────────────────

  void _showSuccessDialog(Map product) {
    final photoUrl = product['photo_url'] as String?;
    final baseHost = ApiService.baseUrl.replaceAll('/api', '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF4F46E5)),
          SizedBox(width: 8),
          Text('Product Added!'),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product photo (if uploaded)
              if (_imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _imageBytes!,
                    height: 120, width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(product['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('SKU: ${product['sku'] ?? ''}',
                  style: const TextStyle(color: Color(0xFF707070))),
              if (product['barcode'] != null) ...[
                const SizedBox(height: 2),
                Text('Barcode: ${product['barcode']}',
                    style: const TextStyle(color: Color(0xFF707070))),
              ],
              if (photoUrl != null && photoUrl.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Photo: $baseHost$photoUrl',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9090A0))),
              ],
              const SizedBox(height: 12),
              const Text('A QR code has been generated for this product.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF707070))),
              const SizedBox(height: 8),
              FutureBuilder<String?>(
                future: ApiService.getToken(),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  return Center(
                    child: Image.network(
                      ApiService.productQrUrl(product['id'],
                          qrImageUrl: product['qr_image_url'] as String?),
                      height: 150, width: 150,
                      headers: {'Authorization': 'Bearer ${snap.data}'},
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.qr_code, size: 80, color: Color(0xFF4F46E5)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ─── UI helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _gradientColors),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildLabel(String label, {bool required = false, bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E1E2E))),
        if (required)
          const Text(' *', style: TextStyle(color: Color(0xFFE53E3E), fontWeight: FontWeight.w700)),
        if (optional)
          const Text('  (Optional)',
              style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
      ]),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    Widget? prefix,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF0F1F5), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E1E2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF9090A0), size: 18)
              : prefix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterText: '',
        ),
      ),
    );
  }

  // ─── Barcode match banner ────────────────────────────────────────────────────

  Widget _buildBarcodeBanner() {
    if (_barcodeDismissed || _barcodeController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (_barcodeChecking) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(children: [
          SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5))),
          SizedBox(width: 10),
          Text('Checking barcode...', style: TextStyle(fontSize: 13, color: Color(0xFF707070))),
        ]),
      );
    }
    if (_barcodeMatch == null) return const SizedBox.shrink();

    final match = _barcodeMatch!;
    final catName = match['category_name'] ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline, color: Color(0xFF4F46E5), size: 18),
            const SizedBox(width: 8),
            const Text('Model already exists',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF4F46E5))),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _barcodeDismissed = true),
              child: const Icon(Icons.close, size: 16, color: Color(0xFF9090A0)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(match['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text('Type: $catName',
              style: const TextStyle(fontSize: 12, color: Color(0xFF707070))),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _applyBarcodeModel(match),
              icon: const Icon(Icons.copy_all, size: 16, color: Colors.white),
              label: const Text('Use this model (auto-fill)',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dynamic spec fields ─────────────────────────────────────────────────────

  Widget _buildSpecSection() {
    final fields = _currentSpecFields;
    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        _buildSectionHeader(
          '${_selectedCategoryName ?? ''} Specifications',
          Icons.settings_applications_outlined,
        ),
        const SizedBox(height: 20),
        ...fields.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(f.label),
              _buildTextField(
                controller: _specControllers[f.key]!,
                hint: f.hint,
                prefixIcon: f.icon,
                keyboardType: f.keyboard,
              ),
            ],
          ),
        )),
      ],
    );
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Widget _buildLocTypeButton(String type, IconData icon, String label) {
    final selected = _locationType == type;
    return GestureDetector(
      onTap: () => setState(() => _locationType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF4F46E5) : const Color(0xFFDDDDEE),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18,
                color: selected ? Colors.white : const Color(0xFF9090A0)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF6B6B80))),
          ],
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // Top bar
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back, color: Color(0xFF1E1E2E), size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Product',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1E2E))),
                        SizedBox(height: 2),
                        Text('Fill in the details below',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9090A0))),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basic Information ──────────────────────────────────────
                  _buildSectionHeader('Basic Information', Icons.inventory_2_outlined),
                  const SizedBox(height: 20),

                  // Product Image
                  _buildLabel('Product Image'),
                  GestureDetector(
                    // Only open the sheet when tapping the preview (photo already chosen);
                    // when empty, the inner Camera/Gallery buttons handle their own taps.
                    onTap: _imageBytes != null ? _showImageSourceSheet : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_imageBytes!, height: 160, fit: BoxFit.cover))
                          : Column(children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.camera_alt_outlined,
                                    color: Color(0xFF4F46E5), size: 30),
                              ),
                              const SizedBox(height: 12),
                              const Text('Add Product Photo',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 4),
                              const Text('PNG, JPG up to 5MB',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF9090A0))),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildImageButton(Icons.camera_alt_outlined, 'Camera',
                                      () => _pickImage(ImageSource.camera)),
                                  const SizedBox(width: 12),
                                  _buildImageButton(Icons.photo_library_outlined, 'Gallery',
                                      () => _pickImage(ImageSource.gallery)),
                                ],
                              ),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Item Name
                  _buildLabel('Item Name', required: true),
                  _buildTextField(
                      controller: _itemNameController,
                      hint: 'e.g., Dell Latitude 5520',
                      prefixIcon: Icons.inventory_2_outlined),
                  const SizedBox(height: 16),

                  // SKU
                  _buildLabel('SKU'),
                  Row(children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _skuController,
                        hint: _skuIsAuto ? 'Auto-generated by server' : 'e.g., ISET-PC-001',
                        prefixIcon: Icons.tag,
                        readOnly: _skuIsAuto,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() {
                        _skuIsAuto = !_skuIsAuto;
                        if (_skuIsAuto) _skuController.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: _skuIsAuto ? const Color(0xFF4F46E5) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4F46E5)),
                        ),
                        child: Text(
                          _skuIsAuto ? 'Manual' : 'Auto',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: _skuIsAuto ? Colors.white : const Color(0xFF4F46E5)),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Type
                  _buildLabel('Type', required: true),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryId,
                        hint: const Row(children: [
                          Icon(Icons.label_outline, color: Color(0xFF9090A0), size: 18),
                          SizedBox(width: 10),
                          Text('Select a type',
                              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
                        ]),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9090A0)),
                        items: _categories.map((c) => DropdownMenuItem(
                            value: c['id'], child: Text(c['name']!))).toList(),
                        onChanged: _onTypeChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Barcode
                  _buildLabel('Barcode'),
                  _buildTextField(
                      controller: _barcodeController,
                      hint: 'Auto-assigned from type & specs if empty',
                      prefixIcon: Icons.barcode_reader),
                  _buildBarcodeBanner(),
                  const SizedBox(height: 16),

                  // Description
                  _buildLabel('Description'),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 14, top: 14),
                            child: Icon(Icons.description_outlined,
                                color: Color(0xFF9090A0), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _descriptionController,
                              maxLines: 4, maxLength: 500,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1E1E2E)),
                              decoration: const InputDecoration(
                                hintText: 'Enter product description...',
                                hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(top: 14, right: 14, bottom: 8),
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 14, bottom: 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('$_descriptionLength/500',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9090A0))),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  _buildLabel('Tags'),
                  _buildTextField(
                      controller: _tagsController,
                      hint: 'e.g., office, peripherals, wireless',
                      prefixIcon: Icons.label_outline),
                  const SizedBox(height: 4),
                  const Text('Separate tags with commas',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9090A0))),

                  // ── Dynamic Specification Fields ───────────────────────────
                  _buildSpecSection(),

                  const SizedBox(height: 28),

                  // ── Inventory & Pricing ────────────────────────────────────
                  _buildSectionHeader('Inventory & Pricing', Icons.attach_money),
                  const SizedBox(height: 20),

                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Quantity', required: true),
                          _buildTextField(
                              controller: _quantityController,
                              hint: '0',
                              prefixIcon: Icons.numbers,
                              keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Price (TND)'),
                          _buildTextField(
                            controller: _priceController,
                            hint: '0.00',
                            prefix: const Padding(
                              padding: EdgeInsets.only(left: 14, right: 8),
                              child: Text('TND',
                                  style: TextStyle(color: Color(0xFF9090A0), fontSize: 13)),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // ── Storage Location ───────────────────────────────────────
                  _buildSectionHeader('Storage Location', Icons.location_on_outlined),
                  const SizedBox(height: 16),

                  // Location type toggle
                  Row(children: [
                    Expanded(child: _buildLocTypeButton('room',  Icons.meeting_room_outlined, 'Room')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildLocTypeButton('stock', Icons.warehouse_outlined,     'Stock')),
                  ]),
                  const SizedBox(height: 16),

                  // ── Room branch ───────────────────────────────────────────
                  if (_locationType == 'room') ...[
                    _buildLabel('Department'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDDDEE)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDeptId,
                          hint: const Row(children: [
                            Icon(Icons.business_outlined, color: Color(0xFF9090A0), size: 16),
                            SizedBox(width: 8),
                            Text('Select department',
                                style: TextStyle(color: Color(0xFF9090A0), fontSize: 14)),
                          ]),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9090A0)),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('— None —', style: TextStyle(color: Color(0xFF9090A0))),
                            ),
                            ..._departments.map((d) {
                              final c = _hexColor(d['color'] as String? ?? '4F46E5');
                              return DropdownMenuItem(
                                value: d['id'] as String,
                                child: Row(children: [
                                  Container(
                                    width: 10, height: 10,
                                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${d['code']} · ${d['name']}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14)),
                                ]),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            final v = val == '' ? null : val;
                            setState(() { _selectedDeptId = v; _selectedRoomId = null; _deptRooms = []; });
                            if (v != null) _loadRoomsForDept(v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Room'),
                    Container(
                      decoration: BoxDecoration(
                        color: _selectedDeptId == null ? const Color(0xFFF0F1F5) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDDDEE)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _roomsLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Row(children: [
                                SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5))),
                                SizedBox(width: 12),
                                Text('Loading rooms…',
                                    style: TextStyle(color: Color(0xFF9090A0), fontSize: 14)),
                              ]),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRoomId,
                                hint: Row(children: [
                                  Icon(Icons.meeting_room_outlined,
                                      color: _selectedDeptId == null
                                          ? const Color(0xFFCCCCCC)
                                          : const Color(0xFF9090A0),
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedDeptId == null
                                        ? 'Select a department first'
                                        : 'Select room',
                                    style: TextStyle(
                                        color: _selectedDeptId == null
                                            ? const Color(0xFFCCCCCC)
                                            : const Color(0xFF9090A0),
                                        fontSize: 14),
                                  ),
                                ]),
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9090A0)),
                                items: _selectedDeptId == null
                                    ? null
                                    : [
                                        const DropdownMenuItem(
                                          value: '',
                                          child: Text('— None —',
                                              style: TextStyle(color: Color(0xFF9090A0))),
                                        ),
                                        ..._deptRooms.map((r) => DropdownMenuItem(
                                              value: r['id'] as String,
                                              child: Row(children: [
                                                const Icon(Icons.meeting_room_outlined,
                                                    size: 15, color: Color(0xFF9090A0)),
                                                const SizedBox(width: 8),
                                                Text(r['name'] as String,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 14)),
                                              ]),
                                            )),
                                      ],
                                onChanged: _selectedDeptId == null
                                    ? null
                                    : (val) => setState(() => _selectedRoomId = val == '' ? null : val),
                              ),
                            ),
                    ),
                  ],

                  // ── Stock branch ──────────────────────────────────────────
                  if (_locationType == 'stock') ...[
                    _buildLabel('Stock Name / Reference'),
                    _buildTextField(
                      controller: _stockController,
                      hint: 'e.g., Stock Principal, Réserve B2',
                      prefixIcon: Icons.warehouse_outlined,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Stockroom or warehouse area outside any department',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9090A0)),
                    ),
                  ],

                  const SizedBox(height: 36),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Saving...' : 'Add Product to Inventory',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom sheet ─────────────────────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF4F46E5)),
              title: const Text('Take a photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF4F46E5)),
              title: const Text('Choose from gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            if (_pickedXFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() { _pickedXFile = null; _imageBytes = null; });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: const Color(0xFF1E1E2E)),
      label: Text(label,
          style: const TextStyle(color: Color(0xFF1E1E2E), fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: const BorderSide(color: Color(0xFFDDDDEE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
