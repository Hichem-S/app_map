import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';

class ComparisonScreen extends StatelessWidget {
  final List<Product> products;
  const ComparisonScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Comparing ${products.length} Items',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _headerRow(context),
          const SizedBox(height: 12),
          _section('General', [
            _row('Name',     (p) => p.name),
            _row('SKU',      (p) => p.sku),
            _row('Category', (p) => p.categoryName ?? '—'),
            _row('Status',   (p) => p.status.replaceAll('_', ' ')),
            _row('Quantity', (p) => p.quantity.toString()),
            _row('Price',    (p) => p.price != null ? '${p.price!.toStringAsFixed(2)} TND' : '—'),
          ]),
          const SizedBox(height: 12),
          _section('Location', [
            _row('Department', (p) => p.departmentCode ?? '—'),
            _row('Room',       (p) => p.roomName ?? '—'),
          ]),
          const SizedBox(height: 12),
          _section('Tracking', [
            _row('RFID Tag',   (p) => p.rfidTag   ?? '—'),
            _row('BLE Device', (p) => p.bleDevice  ?? '—'),
            _row('Barcode',    (p) => p.barcode    ?? '—'),
          ]),
          const SizedBox(height: 12),
          _section('Warranty', [
            _row('Purchase Date',   (p) => _fmt(p.purchaseDate)),
            _row('Warranty Expiry', (p) => _fmt(p.warrantyExpiry)),
            _row('End of Life',     (p) => _fmt(p.endOfLifeDate)),
          ]),
          if (products.any((p) => p.specifications.isNotEmpty)) ...[
            const SizedBox(height: 12),
            _specsSection(),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    final baseHost = 'http://192.168.31.23:3000';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 110),
        ...products.map((p) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: p.photoUrl != null
                    ? Image.network('$baseHost${p.photoUrl}', height: 72, width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder())
                    : _photoPlaceholder(),
              ),
              const SizedBox(height: 6),
              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textH)),
              Text(p.sku, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ]),
          ),
        )),
      ],
    );
  }

  Widget _photoPlaceholder() => Container(
    height: 72, color: AppColors.bgMuted,
    child: const Icon(Icons.devices_other, color: AppColors.textMuted, size: 30),
  );

  Widget _section(String title, List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: AppColors.shadowMd,
    ),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Row(children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
      ),
      ...rows,
    ]),
  );

  Widget _row(String label, String Function(Product) val) {
    final values = products.map(val).toList();
    final allSame = values.every((v) => v == values.first);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ),
          ...values.asMap().entries.map((e) {
            final isDiff = !allSame;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: isDiff ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : EdgeInsets.zero,
                  decoration: isDiff ? BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ) : null,
                  child: Text(e.value, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isDiff ? AppColors.warning : AppColors.textH,
                  )),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _specsSection() {
    final allKeys = <String>{};
    for (final p in products) allKeys.addAll(p.specifications.keys);
    return _section('Specifications',
      allKeys.map((key) => _row(
        key.replaceAll('_', ' '),
        (p) => p.specifications[key]?.toString() ?? '—',
      )).toList(),
    );
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}
