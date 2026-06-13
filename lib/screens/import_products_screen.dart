import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class ImportProductsScreen extends StatefulWidget {
  const ImportProductsScreen({super.key});
  @override
  State<ImportProductsScreen> createState() => _ImportProductsScreenState();
}

class _ImportProductsScreenState extends State<ImportProductsScreen> {
  String? _csvContent;
  String? _fileName;
  bool _uploading = false;
  Map<String, dynamic>? _result;

  static const _template =
      'name,sku,category,barcode,description,quantity,price,status,purchase_date,warranty_expiry,end_of_life_date\n'
      'Laptop Dell,,,MDL-001,15 inch laptop,1,2500,in_stock,2024-01-01,2027-01-01,2030-01-01';

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    final file = res.files.first;
    if (file.bytes == null) return;
    setState(() {
      _csvContent = String.fromCharCodes(file.bytes!);
      _fileName   = file.name;
      _result     = null;
    });
  }

  Future<void> _import() async {
    if (_csvContent == null) return;
    setState(() => _uploading = true);
    try {
      final res = await ApiService.importProductsCSV(_csvContent!);
      if (!mounted) return;
      setState(() { _result = res['data'] as Map<String, dynamic>?; _uploading = false; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _uploading = false);
      }
    }
  }

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
        title: const Text('Import Products', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Format guide
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('CSV Format', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textH)),
            ]),
            const SizedBox(height: 10),
            const Text('Required: name\nOptional: sku, category, barcode, description, quantity, price, status, purchase_date, warranty_expiry, end_of_life_date',
                style: TextStyle(fontSize: 12, color: AppColors.textBody, height: 1.5)),
            const SizedBox(height: 12),
            const Text('Example row:', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.bgMuted, borderRadius: BorderRadius.circular(8)),
              child: const Text(_template, style: TextStyle(fontSize: 10, color: AppColors.textBody, fontFamily: 'monospace')),
            ),
          ])),
          const SizedBox(height: 16),

          // File picker
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _csvContent != null ? AppColors.primary : AppColors.border,
                  width: _csvContent != null ? 1.5 : 1,
                  style: BorderStyle.solid,
                ),
                boxShadow: AppColors.shadowMd,
              ),
              child: Column(children: [
                Icon(_csvContent != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                    size: 40, color: _csvContent != null ? AppColors.primary : AppColors.textMuted),
                const SizedBox(height: 8),
                Text(_fileName ?? 'Tap to pick a CSV file',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: _csvContent != null ? AppColors.primary : AppColors.textMuted)),
                if (_csvContent != null)
                  Text('${_csvContent!.split('\n').length - 1} data rows detected',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Import button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _csvContent == null || _uploading ? null : _import,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.bgMuted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _uploading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Import', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),

          // Result
          if (_result != null) ...[
            const SizedBox(height: 16),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Import Result', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textH)),
              const SizedBox(height: 12),
              _resultRow(Icons.check_circle_rounded, 'Imported', _result!['imported'].toString(), const Color(0xFF22C55E)),
              _resultRow(Icons.skip_next_rounded,    'Skipped',  _result!['skipped'].toString(),  const Color(0xFFF59E0B)),
              if ((_result!['errors'] as List).isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Errors:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
                const SizedBox(height: 4),
                ...(_result!['errors'] as List).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('• $e', style: const TextStyle(fontSize: 11, color: AppColors.error)),
                )),
              ],
            ])),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card(context), borderRadius: BorderRadius.circular(14),
      boxShadow: AppColors.shadowMd,
    ),
    child: child,
  );

  Widget _resultRow(IconData icon, String label, String value, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    ]),
  );
}
