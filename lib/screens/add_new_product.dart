import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
      ),
      home: const AddNewProductScreen(),
    );
  }
}

class AddNewProductScreen extends StatefulWidget {
  const AddNewProductScreen({super.key});

  @override
  State<AddNewProductScreen> createState() => _AddNewProductScreenState();
}

class _AddNewProductScreenState extends State<AddNewProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _priceController = TextEditingController(text: '0.00');
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _shelfBinController = TextEditingController();
  final _supplierNameController = TextEditingController();

  String? _selectedCategory;
  String? _selectedZone;
  int _descriptionLength = 0;

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Food & Beverage',
    'Office Supplies',
    'Tools & Hardware',
    'Health & Beauty',
    'Sports & Outdoors',
    'Other',
  ];

  final List<String> _zones = ['A', 'B', 'C', 'D', 'E', 'F'];

  static const _gradientColors = [Color(0xFF4F46E5), Color(0xFF7C3AED)];

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      setState(() {
        _descriptionLength = _descriptionController.text.length;
      });
    });
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
    _minStockController.dispose();
    _maxStockController.dispose();
    _shelfBinController.dispose();
    _supplierNameController.dispose();
    super.dispose();
  }

  void _autoGenerateSku() {
    final name = _itemNameController.text.trim();
    if (name.isNotEmpty) {
      final prefix =
          name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
      final number = (1000 + DateTime.now().millisecond).toString();
      setState(() {
        _skuController.text = '$prefix-$number';
      });
    } else {
      final number = DateTime.now().millisecondsSinceEpoch % 10000;
      setState(() {
        _skuController.text = 'SKU-$number';
      });
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
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
        color: const Color(0xFFF0F1F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1E1E2E),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 14,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF9090A0), size: 18)
              : prefix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildLabel(String label,
      {bool required = false, bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E2E),
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                  color: Color(0xFFE53E3E), fontWeight: FontWeight.w700),
            ),
          if (optional)
            const Text(
              '  (Optional)',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFAAAAAA),
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.arrow_back,
                                color: Color(0xFF1E1E2E), size: 22),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Add New Product',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E1E2E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Manual Entry · View-only after saving',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9090A0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF4F46E5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.lock_outline,
                                  size: 14, color: Color(0xFF4F46E5)),
                              SizedBox(width: 6),
                              Text(
                                'Add Only',
                                style: TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Info banner
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.shield_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13),
                              children: [
                                TextSpan(text: 'Products can be '),
                                TextSpan(
                                  text: 'added and viewed',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                    text:
                                        ' only. Modifications and deletions are restricted.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basic Information ──
                  _buildSectionHeader(
                      'Basic Information', Icons.inventory_2_outlined),
                  const SizedBox(height: 20),

                  // Product Image
                  const Text(
                    'Product Image',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1E2E)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF4F46E5),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              color: Color(0xFF4F46E5), size: 30),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Add Product Photo',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1E1E2E)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PNG, JPG up to 10MB',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF9090A0)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildImageButton(
                                Icons.camera_alt_outlined, 'Camera'),
                            const SizedBox(width: 12),
                            _buildImageButton(
                                Icons.photo_library_outlined, 'Gallery'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Item Name
                  _buildLabel('Item Name', required: true),
                  _buildTextField(
                    controller: _itemNameController,
                    hint: 'e.g., Wireless Mouse',
                    prefixIcon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: 16),

                  // SKU
                  _buildLabel('SKU', optional: true),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _skuController,
                          hint: 'E.G., EL-0042',
                          prefixIcon: Icons.tag,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _autoGenerateSku,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDDDEE)),
                          ),
                          child: const Text(
                            'Auto-generate',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E2E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category
                  _buildLabel('Category', required: true),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        hint: Row(
                          children: const [
                            Icon(Icons.label_outline,
                                color: Color(0xFF9090A0), size: 18),
                            SizedBox(width: 10),
                            Text(
                              'Select a category',
                              style: TextStyle(
                                  color: Color(0xFFAAAAAA), fontSize: 14),
                            ),
                          ],
                        ),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFF9090A0)),
                        items: _categories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Barcode
                  _buildLabel('Barcode / QR Code', optional: true),
                  _buildTextField(
                    controller: _barcodeController,
                    hint: 'Scan or enter barcode',
                    prefixIcon: Icons.tag,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildLabel('Description', optional: true),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 14, top: 14),
                              child: Icon(Icons.description_outlined,
                                  color: const Color(0xFF9090A0), size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _descriptionController,
                                maxLines: 4,
                                maxLength: 500,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF1E1E2E)),
                                decoration: const InputDecoration(
                                  hintText: 'Enter product description...',
                                  hintStyle: TextStyle(
                                      color: Color(0xFFAAAAAA), fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(
                                      top: 14, right: 14, bottom: 8),
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
                            child: Text(
                              '$_descriptionLength/500',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9090A0)),
                            ),
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
                    prefixIcon: Icons.label_outline,
                  ),
                  const SizedBox(height: 28),

                  // ── Inventory & Pricing ──
                  _buildSectionHeader(
                      'Inventory & Pricing', Icons.attach_money),
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
                              prefixIcon: Icons.tag,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Price', optional: true),
                            _buildTextField(
                              controller: _priceController,
                              hint: '0.00',
                              prefix: const Padding(
                                padding: EdgeInsets.only(left: 14, right: 8),
                                child: Text('\$',
                                    style: TextStyle(
                                        color: Color(0xFF9090A0),
                                        fontSize: 16)),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Stock Alert Thresholds', optional: true),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8F0),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFFFC77A)),
                              ),
                              child: TextField(
                                controller: _minStockController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF1E1E2E)),
                                decoration: const InputDecoration(
                                  hintText: 'Min stock',
                                  hintStyle: TextStyle(
                                      color: Color(0xFFE8A040), fontSize: 14),
                                  prefixIcon: Icon(Icons.warning_amber_outlined,
                                      color: Color(0xFFE8A040), size: 18),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('Alert below',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF9090A0))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FFF4),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFF68D391)),
                              ),
                              child: TextField(
                                controller: _maxStockController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF1E1E2E)),
                                decoration: const InputDecoration(
                                  hintText: 'Max stock',
                                  hintStyle: TextStyle(
                                      color: Color(0xFF38A169), fontSize: 14),
                                  prefixIcon: Icon(Icons.check_circle_outline,
                                      color: Color(0xFF38A169), size: 18),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('Full at',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF9090A0))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Storage Location ──
                  _buildSectionHeader(
                      'Storage Location', Icons.location_on_outlined),
                  const SizedBox(height: 20),

                  _buildLabel('Warehouse Zone', optional: true),
                  Wrap(
                    spacing: 10,
                    children: _zones.map((zone) {
                      final selected = _selectedZone == zone;
                      return GestureDetector(
                        onTap: () => setState(
                            () => _selectedZone = selected ? null : zone),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF4F46E5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFDDDDEE),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              zone,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF1E1E2E),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Shelf / Bin Location', optional: true),
                  _buildTextField(
                    controller: _shelfBinController,
                    hint: 'e.g., Warehouse A, Shelf 5B',
                    prefixIcon: Icons.place_outlined,
                  ),
                  const SizedBox(height: 28),

                  // ── Supplier Info ──
                  _buildSectionHeader('Supplier Info', Icons.business_outlined),
                  const SizedBox(height: 20),

                  _buildLabel('Supplier Name', optional: true),
                  _buildTextField(
                    controller: _supplierNameController,
                    hint: 'e.g., ABC Supplies Inc.',
                    prefixIcon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 24),

                  // Warning note
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.lock_outline,
                            color: Color(0xFFD97706), size: 16),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF92400E)),
                              children: [
                                TextSpan(
                                    text:
                                        'Once added, this product can only be '),
                                TextSpan(
                                  text: 'viewed',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: ', not edited or deleted.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product added to inventory!'),
                            backgroundColor: Color(0xFF4F46E5),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add Product to Inventory',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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

  Widget _buildImageButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF1E1E2E)),
      label: Text(
        label,
        style: const TextStyle(
            color: Color(0xFF1E1E2E), fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: const BorderSide(color: Color(0xFFDDDDEE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
