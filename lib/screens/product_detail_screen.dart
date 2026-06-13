import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/department.dart';
import '../models/room.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/image_picker_helper.dart';
import 'nfc_scan_screen.dart';
import 'ble_select_screen.dart';
import 'maintenance_screen.dart';

// Status display config
const _statusLabels  = {'operational': 'Operational', 'in_stock': 'In Stock', 'in_maintenance': 'In Maintenance', 'critical_issue': 'Critical Issue', 'retired': 'Retired', 'lost': 'Lost'};
const _statusColors  = {'operational': Color(0xFF4F46E5), 'in_stock': Color(0xFF10B981), 'in_maintenance': Color(0xFFF59E0B), 'critical_issue': Color(0xFFEF4444), 'retired': Color(0xFF6B7280), 'lost': Color(0xFF8B5CF6)};
const _statusBgColors = {'operational': Color(0xFFEEF2FF), 'in_stock': Color(0xFFE6F9F2), 'in_maintenance': Color(0xFFFFF8E6), 'critical_issue': Color(0xFFFFEEEE), 'retired': Color(0xFFF3F4F6), 'lost': Color(0xFFF3E8FF)};
const _statusIcons   = {'operational': Icons.check_circle, 'in_stock': Icons.inventory_2, 'in_maintenance': Icons.build, 'critical_issue': Icons.warning_amber, 'retired': Icons.archive, 'lost': Icons.search_off};

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool initiallyEditing;
  const ProductDetailScreen({super.key, required this.product, this.initiallyEditing = false});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  bool _editing = false;
  bool _saving  = false;

  // Edit controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _tagsCtrl;
  final Map<String, TextEditingController> _specCtrl = {};
  String _editStatus = 'in_stock';
  String? _editRoomId;
  String? _editRoomName;
  XFile?  _pickedPhoto;
  Uint8List? _photoBytes;
  String? _editRfidTag;
  String? _editBleDevice;
  DateTime? _editPurchaseDate;
  DateTime? _editWarrantyExpiry;
  DateTime? _editEndOfLife;

  final String _baseHost = ApiService.baseUrl.replaceAll('/api', '');

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _nameCtrl     = TextEditingController();
    _descCtrl     = TextEditingController();
    _quantityCtrl = TextEditingController();
    _priceCtrl    = TextEditingController();
    _barcodeCtrl  = TextEditingController();
    _tagsCtrl     = TextEditingController();
    if (widget.initiallyEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startEdit();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _barcodeCtrl.dispose();
    _tagsCtrl.dispose();
    for (final c in _specCtrl.values) c.dispose();
    super.dispose();
  }

  void _startEdit() {
    _nameCtrl.text     = _product.name;
    _descCtrl.text     = _product.description ?? '';
    _quantityCtrl.text = _product.quantity.toString();
    _priceCtrl.text    = _product.price?.toString() ?? '';
    _barcodeCtrl.text  = _product.barcode ?? '';
    _tagsCtrl.text     = _product.tags.join(', ');
    _editStatus   = _product.status;
    _editRoomId   = _product.roomId;
    _editRoomName = _product.roomName;
    _editRfidTag       = _product.rfidTag;
    _editBleDevice     = _product.bleDevice;
    _editPurchaseDate  = _product.purchaseDate;
    _editWarrantyExpiry = _product.warrantyExpiry;
    _editEndOfLife     = _product.endOfLifeDate;
    _pickedPhoto  = null;
    _photoBytes   = null;

    // Build spec controllers from current product specs
    for (final c in _specCtrl.values) c.dispose();
    _specCtrl.clear();
    for (final entry in _product.specifications.entries) {
      _specCtrl[entry.key] = TextEditingController(text: entry.value?.toString() ?? '');
    }

    setState(() => _editing = true);
  }

  void _cancelEdit() {
    setState(() { _editing = false; _pickedPhoto = null; _photoBytes = null; });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final tags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final specs = <String, dynamic>{};
      for (final e in _specCtrl.entries) {
        if (e.value.text.trim().isNotEmpty) specs[e.key] = e.value.text.trim();
      }

      final res = await ApiService.updateProduct(
        _product.id,
        name:            name,
        sku:             _product.sku,
        type:            _product.type,
        description:     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        quantity:        int.tryParse(_quantityCtrl.text) ?? _product.quantity,
        price:           double.tryParse(_priceCtrl.text),
        barcode:         _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        tags:            tags,
        specifications:  specs,
        roomId:          _editRoomId,
        setRoom:         true,
        rfidTag:         _editRfidTag,
        setRfid:         true,
        bleDevice:       _editBleDevice,
        setBle:          true,
        photo:           _pickedPhoto,
        photoBytes:      _photoBytes,
        purchaseDate:    _editPurchaseDate,
        warrantyExpiry:  _editWarrantyExpiry,
        endOfLifeDate:   _editEndOfLife,
      );

      if (!mounted) return;

      if (res['success'] != true) {
        throw Exception(res['message'] ?? 'Update failed');
      }

      // Update status only after the main update succeeded
      if (_editStatus != _product.status) {
        await ApiService.updateProductStatus(_product.id, _editStatus);
        if (!mounted) return;
      }

      final updated = Product.fromJson(res['data'] as Map<String, dynamic>);
      setState(() {
        _product     = updated.copyWith(status: _editStatus);
        _editing     = false;
        _saving      = false;
        _pickedPhoto = null;
        _photoBytes  = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item updated successfully'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, false),
            ),
            if (_pickedPhoto != null || _product.photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() { _pickedPhoto = null; _photoBytes = null; });
                },
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final (picked, bytes) = await pickImageFromSource(choice);
    if (picked != null && mounted) {
      setState(() { _pickedPhoto = picked; _photoBytes = bytes; });
    }
  }

  Future<void> _pickStatus() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _StatusSheet(current: _editStatus),
    );
    if (picked != null && picked != _editStatus) setState(() => _editStatus = picked);
  }

  Future<void> _pickLocation() async {
    final result = await showModalBottomSheet<(String?, String?)>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LocationSheet(currentRoomId: _editRoomId),
    );
    if (result == null) return;
    setState(() { _editRoomId = result.$1; _editRoomName = result.$2; });
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canEdit = auth.canEditProduct;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing ? 'Edit Item' : 'Item Details',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH),
            ),
            Text(
              _product.sku,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          if (!_editing && canEdit)
            TextButton.icon(
              onPressed: _startEdit,
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
              label: const Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            )
          else if (_editing) ...[
            TextButton(
              onPressed: _saving ? null : _cancelEdit,
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            if (!_saving)
              TextButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, size: 16, color: AppColors.primary),
                label: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              ),
          ],
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoSection(),
            const SizedBox(height: 16),
            _buildIdentityCard(),
            const SizedBox(height: 12),
            _buildStatusRow(),
            const SizedBox(height: 12),
            _HealthScoreCard(productId: _product.id),
            const SizedBox(height: 12),
            _buildInfoCard(),
            const SizedBox(height: 12),
            if (_editing || (_product.description?.isNotEmpty == true))
              _buildDescriptionCard(),
            if (_editing || (_product.description?.isNotEmpty == true))
              const SizedBox(height: 12),
            if (_editing || _product.specifications.isNotEmpty)
              _buildSpecsCard(),
            if (_editing || _product.specifications.isNotEmpty)
              const SizedBox(height: 12),
            if (_editing || _product.tags.isNotEmpty)
              _buildTagsCard(),
            if (_editing || _product.tags.isNotEmpty)
              const SizedBox(height: 12),
            if (_editing || _product.barcode != null)
              _buildBarcodeCard(),
            if (_editing || _product.barcode != null)
              const SizedBox(height: 12),
            _buildWarrantyCard(),
            const SizedBox(height: 12),
            _buildTimestampCard(),
            const SizedBox(height: 12),
            _buildRfidCard(),
            const SizedBox(height: 12),
            _buildBleCard(),
            const SizedBox(height: 12),
            _ActivityFeedCard(productId: _product.id),
            const SizedBox(height: 12),
            _MaintenanceHistoryCard(productId: _product.id),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Photo section ────────────────────────────────────────────────────────────

  Widget _buildPhotoSection() {
    Widget photoWidget;
    if (_editing && _photoBytes != null) {
      photoWidget = Image.memory(_photoBytes!, width: double.infinity, height: 200, fit: BoxFit.cover);
    } else if (_product.photoUrl != null) {
      photoWidget = Image.network(
        '$_baseHost${_product.photoUrl}',
        width: double.infinity, height: 200, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _photoPlaceholder(),
      );
    } else {
      photoWidget = _photoPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          photoWidget,
          if (_editing)
            Positioned(
              bottom: 12, right: 12,
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Change photo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        width: double.infinity,
        height: 200,
        color: AppColors.bgMuted,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 48, color: AppColors.textMuted),
            SizedBox(height: 8),
            Text('No photo', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );

  // ─── Identity card (name, SKU, category) ─────────────────────────────────────

  Widget _buildIdentityCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Name'),
          _editing
              ? _input(_nameCtrl, hint: 'Item name')
              : Text(_product.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textH)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('SKU'),
                Text(_product.sku, style: const TextStyle(fontSize: 14, color: AppColors.textBody, fontWeight: FontWeight.w500)),
              ],
            )),
            if (_product.categoryName != null)
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Category'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_product.categoryName!,
                        style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              )),
          ]),
        ],
      ),
    );
  }

  // ─── Status row ───────────────────────────────────────────────────────────────

  Widget _buildStatusRow() {
    final status = _editing ? _editStatus : _product.status;
    final color  = _statusColors[status]   ?? AppColors.textMuted;
    final bg     = _statusBgColors[status] ?? AppColors.bgMuted;
    final icon   = _statusIcons[status]    ?? Icons.help_outline;
    final label  = _statusLabels[status]   ?? status;

    return _card(
      child: Row(
        children: [
          const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textBody)),
          const Spacer(),
          GestureDetector(
            onTap: _editing ? _pickStatus : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                  if (_editing) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more, size: 14, color: color),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info card (qty, price, location) ─────────────────────────────────────────

  Widget _buildInfoCard() {
    final roomLabel = _editing
        ? (_editRoomName ?? 'Not placed')
        : (_product.roomName != null ? '${_product.departmentCode ?? ''} · ${_product.roomName}' : 'Not placed');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Quantity'),
                _editing
                    ? _input(_quantityCtrl, hint: '0', keyboard: TextInputType.number)
                    : Text(_product.quantity.toString(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textH)),
              ],
            )),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Price (TND)'),
                _editing
                    ? _input(_priceCtrl, hint: '0.00', keyboard: const TextInputType.numberWithOptions(decimal: true))
                    : Text(
                        _product.price != null ? _product.price!.toStringAsFixed(2) : '—',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textH)),
              ],
            )),
          ]),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          _label('Location'),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  roomLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _product.roomId != null || (_editing && _editRoomId != null)
                        ? AppColors.textH
                        : AppColors.textMuted,
                  ),
                ),
              ),
              if (_editing)
                TextButton(
                  onPressed: _pickLocation,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Change', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Description ─────────────────────────────────────────────────────────────

  Widget _buildDescriptionCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Description'),
          _editing
              ? _input(_descCtrl, hint: 'Enter description…', maxLines: 4)
              : Text(
                  _product.description ?? '—',
                  style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.5),
                ),
        ],
      ),
    );
  }

  // ─── Specs ───────────────────────────────────────────────────────────────────

  Widget _buildSpecsCard() {
    final specs = _editing
        ? _specCtrl.entries.toList()
        : _product.specifications.entries.toList();

    if (specs.isEmpty && !_editing) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Specifications'),
          const SizedBox(height: 4),
          if (specs.isEmpty)
            const Text('No specifications', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
          else
            ...specs.map((e) {
              if (_editing) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          e.key.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 13, color: AppColors.textBody, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _input(e.value as TextEditingController, hint: '—')),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          e.key.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value?.toString() ?? '—',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textH),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
        ],
      ),
    );
  }

  // ─── Tags ────────────────────────────────────────────────────────────────────

  Widget _buildTagsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Tags'),
          const SizedBox(height: 6),
          if (_editing)
            _input(_tagsCtrl, hint: 'tag1, tag2, tag3…')
          else if (_product.tags.isEmpty)
            const Text('No tags', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _product.tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(t, style: const TextStyle(fontSize: 12, color: AppColors.textBody, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
        ],
      ),
    );
  }

  // ─── Barcode ──────────────────────────────────────────────────────────────────

  Widget _buildBarcodeCard() {
    return _card(
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.bgMuted, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.qr_code, color: AppColors.textMuted, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Barcode'),
                _editing
                    ? _input(_barcodeCtrl, hint: 'e.g. MDL-XXXXXXXX')
                    : Text(
                        _product.barcode ?? '—',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Warranty & Lifecycle ─────────────────────────────────────────────────────

  Widget _buildWarrantyCard() {
    final purchaseDate   = _editing ? _editPurchaseDate   : _product.purchaseDate;
    final warrantyExpiry = _editing ? _editWarrantyExpiry : _product.warrantyExpiry;
    final endOfLife      = _editing ? _editEndOfLife      : _product.endOfLifeDate;

    final now = DateTime.now();
    String? warrantyBadge;
    Color   badgeColor = const Color(0xFF22C55E);
    if (warrantyExpiry != null) {
      if (warrantyExpiry.isBefore(now)) {
        warrantyBadge = 'Expired';
        badgeColor    = const Color(0xFFEF4444);
      } else if (warrantyExpiry.difference(now).inDays <= 30) {
        warrantyBadge = 'Expiring Soon';
        badgeColor    = const Color(0xFFF59E0B);
      }
    }

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF6D28D9)),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Warranty & Lifecycle',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textH))),
          if (warrantyBadge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(warrantyBadge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
            ),
        ]),
        const SizedBox(height: 12),
        _warrantyRow('Purchase Date',    purchaseDate,   'purchase_date',   (d) => setState(() => _editPurchaseDate   = d)),
        const SizedBox(height: 8),
        _warrantyRow('Warranty Expiry',  warrantyExpiry, 'warranty_expiry', (d) => setState(() => _editWarrantyExpiry = d)),
        const SizedBox(height: 8),
        _warrantyRow('End of Life',      endOfLife,      'end_of_life_date',(d) => setState(() => _editEndOfLife      = d)),
      ]),
    );
  }

  Widget _warrantyRow(String label, DateTime? date, String field, void Function(DateTime?) onPick) {
    final formatted = date != null
        ? '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}'
        : (_editing ? 'Tap to set' : '—');
    return Row(children: [
      SizedBox(width: 130, child: Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
      Expanded(child: GestureDetector(
        onTap: _editing ? () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2040),
          );
          onPick(picked);
        } : null,
        child: Row(children: [
          Text(formatted, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: _editing ? AppColors.primary : AppColors.textH,
          )),
          if (_editing && date != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => onPick(null),
              child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
            ),
          ],
          if (_editing) const SizedBox(width: 4),
          if (_editing) const Icon(Icons.edit_calendar_outlined, size: 14, color: AppColors.primary),
        ]),
      )),
    ]);
  }

  // ─── Timestamps ───────────────────────────────────────────────────────────────

  Widget _buildTimestampCard() {
    return _card(
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Added'),
              Text(_formatDate(_product.createdAt),
                  style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
            ],
          )),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Updated'),
              Text(_formatDate(_product.updatedAt),
                  style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
            ],
          )),
        ],
      ),
    );
  }

  // ─── RFID card ────────────────────────────────────────────────────────────────

  Widget _buildRfidCard() {
    const rfidColor = Color(0xFF6D28D9);
    const rfidBg    = Color(0xFFF5F3FF);
    final tag = _editing ? _editRfidTag : _product.rfidTag;
    final hasTag = tag != null && tag.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasTag ? rfidColor.withValues(alpha: 0.35) : AppColors.border,
        ),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: hasTag ? rfidBg : AppColors.bgMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.nfc_rounded,
                    color: hasTag ? rfidColor : AppColors.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RFID Tag',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textH)),
                      Text(
                        hasTag ? 'Tag assigned' : 'No tag assigned',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasTag ? rfidColor : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasTag)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rfidBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: rfidColor, size: 12),
                        SizedBox(width: 4),
                        Text('Active', style: TextStyle(fontSize: 11, color: rfidColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Tag ID display
          if (hasTag)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: rfidBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: rfidColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, size: 14, color: rfidColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: rfidColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (_editing)
                    GestureDetector(
                      onTap: () => setState(() => _editRfidTag = null),
                      child: const Icon(Icons.close, size: 16, color: rfidColor),
                    ),
                ],
              ),
            ),

          // Assign / Change button (edit mode only)
          if (_editing)
            Padding(
              padding: EdgeInsets.fromLTRB(16, hasTag ? 0 : 4, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showRfidDialog(),
                  icon: Icon(hasTag ? Icons.edit_outlined : Icons.add_circle_outline,
                      size: 18, color: rfidColor),
                  label: Text(
                    hasTag ? 'Change RFID Tag' : 'Assign RFID Tag',
                    style: const TextStyle(color: rfidColor, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: rfidColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),

          if (!_editing && !hasTag)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No RFID tag has been assigned to this item.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBleCard() {
    const bleColor  = Color(0xFF2563EB);
    const bleBg     = Color(0xFFEFF6FF);
    final tag   = _editing ? _editBleDevice : _product.bleDevice;
    final hasTag = tag != null && tag.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasTag ? bleColor.withValues(alpha: 0.35) : AppColors.border,
        ),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: hasTag ? bleBg : AppColors.bgMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bluetooth_rounded,
                      color: hasTag ? bleColor : AppColors.textMuted, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BLE Device',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textH)),
                      Text(
                        hasTag ? 'Device linked' : 'No device linked',
                        style: TextStyle(
                            fontSize: 12,
                            color: hasTag ? bleColor : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (hasTag)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bleBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: bleColor, size: 12),
                        SizedBox(width: 4),
                        Text('Active',
                            style: TextStyle(
                                fontSize: 11,
                                color: bleColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // MAC address display
          if (hasTag)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bleBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bleColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, size: 14, color: bleColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tag,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: bleColor,
                          letterSpacing: 0.5),
                    ),
                  ),
                  if (_editing)
                    GestureDetector(
                      onTap: () => setState(() => _editBleDevice = null),
                      child: const Icon(Icons.close, size: 16, color: bleColor),
                    ),
                ],
              ),
            ),

          // Assign / Change button (edit mode only)
          if (_editing)
            Padding(
              padding: EdgeInsets.fromLTRB(16, hasTag ? 0 : 4, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showBleDialog,
                  icon: Icon(
                    hasTag ? Icons.edit_outlined : Icons.add_circle_outline,
                    size: 18,
                    color: bleColor,
                  ),
                  label: Text(
                    hasTag ? 'Change BLE Device' : 'Link BLE Device',
                    style: const TextStyle(
                        color: bleColor, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: bleColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),

          if (!_editing && !hasTag)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No BLE device has been linked to this item.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showRfidDialog() async {
    final uid = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const NfcScanScreen()),
    );
    if (uid == null || !mounted) return;
    setState(() => _editRfidTag = uid.isEmpty ? null : uid);
  }

  Future<void> _showBleDialog() async {
    final mac = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BleSelectScreen()),
    );
    if (mac == null || !mounted) return;
    setState(() => _editBleDevice = mac.isEmpty ? null : mac);
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.shadowMd,
        ),
        child: child,
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.textMuted, letterSpacing: 0.5)),
      );

  Widget _input(TextEditingController ctrl, {String hint = '', int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14, color: AppColors.textH),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Health score card ────────────────────────────────────────────────────────

class _HealthScoreCard extends StatefulWidget {
  final String productId;
  const _HealthScoreCard({required this.productId});
  @override
  State<_HealthScoreCard> createState() => _HealthScoreCardState();
}

class _HealthScoreCardState extends State<_HealthScoreCard> {
  Map<String, dynamic>? _health;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final h = await ApiService.getProductHealth(widget.productId);
    if (mounted) setState(() { _health = h; _loading = false; });
  }

  Color get _color {
    final s = _health?['score'] as int? ?? 0;
    if (s >= 80) return const Color(0xFF22C55E);
    if (s >= 60) return const Color(0xFF84CC16);
    if (s >= 40) return const Color(0xFFF59E0B);
    if (s >= 20) return const Color(0xFFEF4444);
    return const Color(0xFF7F1D1D);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_health == null) return const SizedBox.shrink();

    final score   = _health!['score']   as int;
    final label   = _health!['label']   as String;
    final reasons = (_health!['reasons'] as List).cast<String>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.shadowMd,
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.health_and_safety_rounded, size: 20, color: _color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Health Score', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: AppColors.textH)),
            Text(label, style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
          ])),
          Text('$score', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _color)),
          Text('/100', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
        ),
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...reasons.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              Icon(Icons.remove_circle_outline_rounded, size: 12, color: _color),
              const SizedBox(width: 5),
              Text(r, style: TextStyle(fontSize: 11, color: AppColors.tBody(context))),
            ]),
          )),
        ],
      ]),
    );
  }
}

// ─── Status sheet ─────────────────────────────────────────────────────────────

class _StatusSheet extends StatelessWidget {
  final String current;
  const _StatusSheet({required this.current});

  static const _options = [
    ('operational',    'Operational',    Icons.check_circle,  Color(0xFF4F46E5), Color(0xFFEEF2FF)),
    ('in_stock',       'In Stock',       Icons.inventory_2,   Color(0xFF10B981), Color(0xFFE6F9F2)),
    ('in_maintenance', 'In Maintenance', Icons.build,         Color(0xFFF59E0B), Color(0xFFFFF8E6)),
    ('critical_issue', 'Critical Issue', Icons.warning_amber, Color(0xFFEF4444), Color(0xFFFFEEEE)),
    ('retired',        'Retired',        Icons.archive,       Color(0xFF6B7280), Color(0xFFF3F4F6)),
    ('lost',           'Lost',           Icons.search_off,    Color(0xFF8B5CF6), Color(0xFFF3E8FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Change Status',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
          const SizedBox(height: 4),
          const Text('Select a new status for this equipment',
              style: TextStyle(fontSize: 13, color: AppColors.textBody)),
          const SizedBox(height: 16),
          ..._options.map((opt) {
            final (key, label, icon, color, bg) = opt;
            final selected = key == current;
            return GestureDetector(
              onTap: () => Navigator.pop(context, key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? bg : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Text(label, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? color : AppColors.textH)),
                    const Spacer(),
                    if (selected) Icon(Icons.check_circle, color: color, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Location sheet ───────────────────────────────────────────────────────────

class _LocationSheet extends StatefulWidget {
  final String? currentRoomId;
  const _LocationSheet({this.currentRoomId});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  List<Department> _depts = [];
  final Map<String, List<Room>> _roomCache = {};
  Department? _selDept;
  Room? _selRoom;
  bool _loadingDepts = true;
  bool _loadingRooms = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await ApiService.getDepartments();
      if (!mounted) return;
      setState(() {
        _depts = raw.map((d) => Department.fromJson(d as Map<String, dynamic>)).toList();
        _loadingDepts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDepts = false);
    }
  }

  Future<void> _selectDept(Department dept) async {
    setState(() { _selDept = dept; _selRoom = null; });
    if (_roomCache.containsKey(dept.id)) return;
    setState(() => _loadingRooms = true);
    try {
      final raw = await ApiService.getDepartmentRooms(dept.id);
      if (!mounted) return;
      _roomCache[dept.id] = raw.map((r) => Room.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loadingRooms = false);
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _selDept != null ? (_roomCache[_selDept!.id] ?? <Room>[]) : <Room>[];

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Place Equipment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
                SizedBox(height: 2),
                Text('Choose department then room', style: TextStyle(fontSize: 13, color: AppColors.textBody)),
              ],
            )),
            if (widget.currentRoomId != null)
              TextButton(
                onPressed: () => Navigator.pop(context, (null, null)),
                child: const Text('Unplace', style: TextStyle(color: Colors.red, fontSize: 13)),
              ),
          ]),
          const SizedBox(height: 16),
          const Text('Department', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textH)),
          const SizedBox(height: 10),
          _loadingDepts
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator(color: AppColors.primary)))
              : Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _depts.map((dept) {
                    final sel = _selDept?.id == dept.id;
                    final color = dept.flutterColor;
                    final bg = dept.flutterBg;
                    return GestureDetector(
                      onTap: () => _selectDept(dept),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? color : bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? color : Colors.transparent, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.domain, color: sel ? Colors.white : color, size: 18),
                            const SizedBox(height: 4),
                            Text(dept.code, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sel ? Colors.white : color)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
          if (_selDept != null) ...[
            const SizedBox(height: 16),
            const Text('Room', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textH)),
            const SizedBox(height: 8),
            if (_loadingRooms)
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: CircularProgressIndicator(color: AppColors.primary)))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                child: SingleChildScrollView(
                  child: Column(
                    children: rooms.map((room) {
                      final sel = _selRoom?.id == room.id;
                      final color = _selDept!.flutterColor;
                      final bg = _selDept!.flutterBg;
                      return GestureDetector(
                        onTap: () => setState(() => _selRoom = room),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? bg : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sel ? color : AppColors.border, width: sel ? 1.5 : 1),
                          ),
                          child: Row(children: [
                            Icon(Icons.meeting_room_outlined, size: 16, color: sel ? color : AppColors.textMuted),
                            const SizedBox(width: 10),
                            Expanded(child: Text(room.name, style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.normal, color: sel ? color : AppColors.textH))),
                            if (sel) Icon(Icons.check_circle, color: color, size: 16),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selRoom == null
                  ? null
                  : () => Navigator.pop(context, (_selRoom!.id, _selRoom!.name)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.bgMuted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity feed card ────────────────────────────────────────────────────────

class _ActivityFeedCard extends StatefulWidget {
  final String productId;
  const _ActivityFeedCard({required this.productId});
  @override
  State<_ActivityFeedCard> createState() => _ActivityFeedCardState();
}

class _ActivityFeedCardState extends State<_ActivityFeedCard> {
  List<dynamic> _events = [];
  bool _loading   = true;
  bool _expanded  = false;

  static const _typeIcon = {
    'scan':           Icons.qr_code_scanner_rounded,
    'product_added':  Icons.add_circle_outline_rounded,
    'moved':          Icons.swap_horiz_rounded,
    'status_changed': Icons.change_circle_outlined,
    'maintenance':    Icons.build_rounded,
    'dept_qr':        Icons.domain_outlined,
  };
  static const _typeColor = {
    'scan':           Color(0xFF4F46E5),
    'product_added':  Color(0xFF22C55E),
    'moved':          Color(0xFF0EA5E9),
    'status_changed': Color(0xFFF59E0B),
    'maintenance':    Color(0xFFEF4444),
    'dept_qr':        Color(0xFF8B5CF6),
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final events = await ApiService.getProductActivity(widget.productId);
      if (mounted) setState(() { _events = events; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  String _timeAgo(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 30)    return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final shown = _expanded ? _events : _events.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(children: [
        // Header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timeline_rounded, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Activity Feed', style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppColors.textH)),
                if (!_loading)
                  Text('${_events.length} event${_events.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ])),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted),
            ]),
          ),
        ),
        if (_expanded || (!_loading && _events.isNotEmpty)) ...[
          Divider(height: 1, color: AppColors.divider(context)),
          if (_loading)
            const Padding(padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2)))
          else if (_events.isEmpty)
            const Padding(padding: EdgeInsets.all(16),
              child: Text('No activity recorded yet.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox.shrink(),
              itemBuilder: (_, i) {
                final e     = shown[i];
                final type  = e['type'] as String? ?? 'scan';
                final label = e['label'] as String? ?? type;
                final at    = e['at']   as String? ?? '';
                final user  = e['userName'] as String?;
                final detail = e['detail'] as Map? ?? {};
                final color  = _typeColor[type] ?? AppColors.primary;
                final icon   = _typeIcon[type]  ?? Icons.circle_outlined;
                final isLast = i == shown.length - 1;

                String? subtitle;
                if (type == 'moved') {
                  final from = detail['from_room'] as String?;
                  final to   = detail['to_room']   as String?;
                  if (from != null || to != null)
                    subtitle = '${from ?? '—'} → ${to ?? '—'}';
                } else if (type == 'status_changed') {
                  final old = detail['old_status'] as String?;
                  final nw  = detail['new_status'] as String?;
                  if (old != null && nw != null)
                    subtitle = '${old.replaceAll('_',' ')} → ${nw.replaceAll('_',' ')}';
                } else if (type == 'maintenance') {
                  subtitle = (detail['status'] as String?)?.replaceAll('_', ' ');
                }

                return Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, isLast ? 6 : 0),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Column(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      if (!isLast)
                        Container(width: 1.5, height: 20,
                            color: AppColors.border.withOpacity(0.5)),
                    ]),
                    const SizedBox(width: 10),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(label, style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: AppColors.tH(context)))),
                          Text(_timeAgo(at), style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                        ]),
                        if (subtitle != null)
                          Text(subtitle, style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                        if (user != null)
                          Text('by $user', style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                      ]),
                    )),
                  ]),
                );
              },
            ),
          if (!_loading && _events.length > 4)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(child: Text(
                  _expanded ? 'Show less' : 'Show all ${_events.length} events',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                )),
              ),
            ),
        ],
      ]),
    );
  }
}

// ── Maintenance history card ───────────────────────────────────────────────────

class _MaintenanceHistoryCard extends StatefulWidget {
  final String productId;
  const _MaintenanceHistoryCard({required this.productId});

  @override
  State<_MaintenanceHistoryCard> createState() => _MaintenanceHistoryCardState();
}

class _MaintenanceHistoryCardState extends State<_MaintenanceHistoryCard> {
  List<MaintenanceTask> _tasks = [];
  bool _loading  = true;
  bool _expanded = true;

  static const _priorityColor = {
    'high':   Color(0xFFEF4444),
    'medium': Color(0xFFF59E0B),
    'low':    Color(0xFF22C55E),
  };
  static const _statusColor = {
    'scheduled':   Color(0xFF6D28D9),
    'in_progress': Color(0xFF0EA5E9),
    'done':        Color(0xFF22C55E),
    'cancelled':   Color(0xFF94A3B8),
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiService.getMaintenanceTasks(productId: widget.productId);
      if (!mounted) return;
      setState(() {
        _tasks = (res['data'] as List? ?? [])
            .map((e) => MaintenanceTask.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.build_rounded, size: 18, color: AppColors.error)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Maintenance History', style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700, color: AppColors.textH)),
                if (!_loading)
                  Text('${_tasks.length} record${_tasks.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ])),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
            ]),
          ),
        ),
        if (_expanded) ...[
          const Divider(height: 1, color: AppColors.border),
          if (_loading)
            const Padding(padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2)))
          else if (_tasks.isEmpty)
            const Padding(padding: EdgeInsets.all(20),
              child: Row(children: [
                Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF22C55E)),
                SizedBox(width: 8),
                Text('No maintenance records', style: TextStyle(fontSize: 13,
                    color: AppColors.textMuted)),
              ]))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 52, color: AppColors.border),
              itemBuilder: (_, i) => _HistoryRow(
                task: _tasks[i],
                priorityColor: _priorityColor,
                statusColor:   _statusColor,
              ),
            ),
        ],
      ]),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final MaintenanceTask task;
  final Map<String, Color> priorityColor;
  final Map<String, Color> statusColor;
  const _HistoryRow({required this.task, required this.priorityColor, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final pColor  = priorityColor[task.priority] ?? AppColors.textMuted;
    final sColor  = statusColor[task.status]     ?? AppColors.textMuted;
    final rawDate = task.completedAt ?? task.scheduledDate ?? task.createdAt;
    final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: pColor, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textH))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: sColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(task.status.replaceAll('_', ' '),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sColor)),
            ),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            if (task.assignedTo != null) ...[
              const Icon(Icons.person_outline_rounded, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(task.assignedTo!['name'] as String? ?? '',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ])),
      ]),
    );
  }
}
