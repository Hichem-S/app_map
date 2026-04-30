import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AddNewProductScreen extends StatefulWidget {
  const AddNewProductScreen({super.key});

  @override
  State<AddNewProductScreen> createState() => _AddNewProductScreenState();
}

class _AddNewProductScreenState extends State<AddNewProductScreen> {
  final _itemNameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _priceController = TextEditingController(text: '0.00');
  final _shelfBinController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedZone;
  int _descriptionLength = 0;
  XFile? _pickedXFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _skuIsAuto = true;

  List<Map<String, String>> _categories = [];

  static const _gradientColors = [Color(0xFF4F46E5), Color(0xFF7C3AED)];
  final List<String> _zones = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(
      () => setState(() => _descriptionLength = _descriptionController.text.length),
    );
    _loadCategories();
  }

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

  @override
  void dispose() {
    _itemNameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _shelfBinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedXFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  void _autoGenerateSku() {
    setState(() {
      _skuIsAuto = true;
      _skuController.clear();
    });
  }

  Future<void> _submit() async {
    final name = _itemNameController.text.trim();
    if (name.isEmpty) {
      _snack('Item name is required');
      return;
    }
    if (_selectedCategoryId == null) {
      _snack('Please select a type');
      return;
    }

    final qty = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text);
    final tags = _tagsController.text.trim().isEmpty
        ? <String>[]
        : _tagsController.text.split(',').map((t) => t.trim()).toList();

    final location = [
      if (_selectedZone != null) 'Zone $_selectedZone',
      if (_shelfBinController.text.trim().isNotEmpty) _shelfBinController.text.trim(),
    ].join(' – ');

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.createProduct(
        name: name,
        sku: _skuIsAuto ? null : _skuController.text.trim(),
        type: _selectedCategoryId,
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        tags: tags.isEmpty ? null : tags,
        quantity: qty,
        price: price,
        storageLocation: location.isEmpty ? null : location,
        photo: _pickedXFile,
      );

      if (!mounted) return;

      if (data['success'] == true) {
        final product = data['data'];
        _showSuccessDialog(product);
      } else {
        _snack(data['message'] ?? 'Failed to add product');
      }
    } catch (_) {
      if (!mounted) return;
      _snack('Connection error. Check your network.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(Map product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text('Product Added!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('SKU: ${product['sku'] ?? ''}', style: const TextStyle(color: Color(0xFF707070))),
            const SizedBox(height: 12),
            const Text('A QR code has been generated for this product.',
                style: TextStyle(fontSize: 13, color: Color(0xFF707070))),
            const SizedBox(height: 8),
            FutureBuilder<String?>(
              future: ApiService.getToken(),
              builder: (context, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                return Image.network(
                  ApiService.productQrUrl(product['id']),
                  height: 150,
                  width: 150,
                  headers: {'Authorization': 'Bearer ${snap.data}'},
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.qr_code, size: 80, color: Color(0xFF4F46E5)),
                );
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ─── UI helpers ─────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _gradientColors),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, {bool required = false, bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E1E2E))),
          if (required)
            const Text(' *', style: TextStyle(color: Color(0xFFE53E3E), fontWeight: FontWeight.w700)),
          if (optional)
            const Text('  (Optional)',
                style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
        ],
      ),
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E1E2E))),
                              SizedBox(height: 2),
                              Text('Fill in the details below',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF9090A0))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable form
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
                  _buildLabel('Product Image', optional: true),
                  GestureDetector(
                    onTap: () => _showImageSourceSheet(),
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
                              child: Image.memory(_imageBytes!, height: 160, fit: BoxFit.cover),
                            )
                          : Column(
                              children: [
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
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
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Item Name
                  _buildLabel('Item Name', required: true),
                  _buildTextField(
                      controller: _itemNameController,
                      hint: 'e.g., Wireless Mouse',
                      prefixIcon: Icons.inventory_2_outlined),
                  const SizedBox(height: 16),

                  // SKU
                  _buildLabel('SKU', optional: true),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _skuController,
                          hint: _skuIsAuto ? 'Auto-generated by server' : 'e.g., ISET-INFO-001',
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _skuIsAuto ? Colors.white : const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                        hint: Row(
                          children: const [
                            Icon(Icons.label_outline, color: Color(0xFF9090A0), size: 18),
                            SizedBox(width: 10),
                            Text('Select a type',
                                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
                          ],
                        ),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9090A0)),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c['id'], child: Text(c['name']!)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Barcode
                  _buildLabel('Barcode', optional: true),
                  _buildTextField(
                      controller: _barcodeController,
                      hint: 'Scan or enter barcode',
                      prefixIcon: Icons.qr_code),
                  const SizedBox(height: 16),

                  // Description
                  _buildLabel('Description', optional: true),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
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
                                maxLines: 4,
                                maxLength: 500,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  _buildLabel('Tags', optional: true),
                  _buildTextField(
                      controller: _tagsController,
                      hint: 'e.g., office, peripherals, wireless',
                      prefixIcon: Icons.label_outline),
                  const SizedBox(height: 4),
                  const Text('Separate tags with commas',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9090A0))),
                  const SizedBox(height: 28),

                  // ── Inventory & Pricing ────────────────────────────────────
                  _buildSectionHeader('Inventory & Pricing', Icons.attach_money),
                  const SizedBox(height: 20),

                  Row(
                    children: [
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
                            _buildLabel('Price (TND)', optional: true),
                            _buildTextField(
                              controller: _priceController,
                              hint: '0.00',
                              prefix: const Padding(
                                padding: EdgeInsets.only(left: 14, right: 8),
                                child: Text('TND',
                                    style: TextStyle(
                                        color: Color(0xFF9090A0), fontSize: 13)),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Storage Location ───────────────────────────────────────
                  _buildSectionHeader('Storage Location', Icons.location_on_outlined),
                  const SizedBox(height: 20),

                  _buildLabel('Warehouse Zone', optional: true),
                  Wrap(
                    spacing: 10,
                    children: _zones.map((zone) {
                      final selected = _selectedZone == zone;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedZone = selected ? null : zone),
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF4F46E5) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? const Color(0xFF4F46E5) : const Color(0xFFDDDDEE),
                            ),
                          ),
                          child: Center(
                            child: Text(zone,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: selected ? Colors.white : const Color(0xFF1E1E2E))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Shelf / Bin Location', optional: true),
                  _buildTextField(
                      controller: _shelfBinController,
                      hint: 'e.g., Shelf 5B, Room 204',
                      prefixIcon: Icons.place_outlined),
                  const SizedBox(height: 36),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF4F46E5)),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
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
