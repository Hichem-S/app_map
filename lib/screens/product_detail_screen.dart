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

// Status display config
const _statusLabels  = {'operational': 'Operational', 'in_stock': 'In Stock', 'in_maintenance': 'In Maintenance', 'critical_issue': 'Critical Issue', 'retired': 'Retired', 'lost': 'Lost'};
const _statusColors  = {'operational': Color(0xFF4F46E5), 'in_stock': Color(0xFF10B981), 'in_maintenance': Color(0xFFF59E0B), 'critical_issue': Color(0xFFEF4444), 'retired': Color(0xFF6B7280), 'lost': Color(0xFF8B5CF6)};
const _statusBgColors = {'operational': Color(0xFFEEF2FF), 'in_stock': Color(0xFFE6F9F2), 'in_maintenance': Color(0xFFFFF8E6), 'critical_issue': Color(0xFFFFEEEE), 'retired': Color(0xFFF3F4F6), 'lost': Color(0xFFF3E8FF)};
const _statusIcons   = {'operational': Icons.check_circle, 'in_stock': Icons.inventory_2, 'in_maintenance': Icons.build, 'critical_issue': Icons.warning_amber, 'retired': Icons.archive, 'lost': Icons.search_off};

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

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
    _editRfidTag  = _product.rfidTag;
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
        name:           name,
        sku:            _product.sku,
        type:           _product.type,
        description:    _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        quantity:       int.tryParse(_quantityCtrl.text) ?? _product.quantity,
        price:          double.tryParse(_priceCtrl.text),
        barcode:        _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        tags:           tags,
        specifications: specs,
        roomId:         _editRoomId,
        setRoom:        true,
        rfidTag:        _editRfidTag,
        setRfid:        true,
        photo:          _pickedPhoto,
        photoBytes:     _photoBytes,
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
      backgroundColor: AppColors.bgPage,
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
            _buildTimestampCard(),
            const SizedBox(height: 12),
            _buildRfidCard(),
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

  Future<void> _showRfidDialog() async {
    final uid = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const NfcScanScreen()),
    );
    if (uid == null || !mounted) return;
    setState(() => _editRfidTag = uid.isEmpty ? null : uid);
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
