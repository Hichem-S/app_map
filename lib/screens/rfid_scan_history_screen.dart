import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class RfidScanHistoryScreen extends StatefulWidget {
  const RfidScanHistoryScreen({Key? key}) : super(key: key);

  @override
  State<RfidScanHistoryScreen> createState() => _RfidScanHistoryScreenState();
}

class _RfidScanHistoryScreenState extends State<RfidScanHistoryScreen> {
  List<Map<String, dynamic>> _scans = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // all | rfid | ble
  String _search = '';
  int _total = 0;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getIotScanHistory(
        scanType: _filter == 'all' ? null : _filter,
        limit: 200,
      );
      final data = (res['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _scans = data;
        _total = res['total'] as int? ?? data.length;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    if (q.isEmpty) return _scans;
    return _scans.where((s) {
      return (s['product_name'] ?? '').toLowerCase().contains(q) ||
          (s['sku'] ?? '').toLowerCase().contains(q) ||
          (s['room_name'] ?? '').toLowerCase().contains(q) ||
          (s['identifier'] ?? '').toLowerCase().contains(q) ||
          (s['reader_id'] ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.tH(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IoT Scan History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.tH(context),
              ),
            ),
            if (!_loading)
              Text(
                '$_total events total',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & filter bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(fontSize: 13, color: AppColors.tH(context)),
              decoration: InputDecoration(
                hintText: 'Search product, SKU, room, reader…',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.muted(context),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // ── Filter chips ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                _chip('All', 'all'),
                const SizedBox(width: 8),
                _chip('RFID', 'rfid'),
                const SizedBox(width: 8),
                _chip('BLE', 'ble'),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _errorView()
                    : filtered.isEmpty
                        ? _emptyView()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) => _ScanCard(
                                scan: filtered[i],
                                timeAgo: _timeAgo(filtered[i]['scanned_at']),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () {
        if (_filter == value) return;
        setState(() => _filter = value);
        _load();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.muted(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textBody,
          ),
        ),
      ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load scan history',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.tH(context)),
              ),
              const SizedBox(height: 6),
              Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );

  Widget _emptyView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_tethering_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('No scan events yet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textH)),
            const SizedBox(height: 6),
            const Text('RFID and BLE events will appear here\nonce the ESP32 reader detects tags.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      );
}

// ── Scan card ─────────────────────────────────────────────────────────────────

class _ScanCard extends StatelessWidget {
  final Map<String, dynamic> scan;
  final String timeAgo;

  const _ScanCard({required this.scan, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final isRfid  = scan['scan_type'] == 'rfid';
    final moved   = scan['moved'] == true;
    final fromRoom = scan['from_room'] as String?;
    final toRoom  = scan['room_name'] as String? ?? '—';
    final productName = scan['product_name'] as String? ?? 'Unregistered';
    final sku     = scan['sku'] as String?;
    final readerId = scan['reader_id'] as String? ?? '—';
    final rssi    = scan['rssi'] as int?;

    final typeColor  = isRfid ? AppColors.primary : AppColors.accent;
    final typeBg     = isRfid ? AppColors.primaryGlow : const Color(0x330EA5E9);
    final typeLabel  = isRfid ? 'RFID' : 'BLE';
    final typeIcon   = isRfid ? Icons.nfc_rounded : Icons.bluetooth_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type icon ──────────────────────────────────────────────
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            // ── Content ────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tH(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(typeLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: typeColor)),
                      ),
                      if (moved) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.successBg, borderRadius: BorderRadius.circular(6)),
                          child: const Text('MOVED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ),
                      ],
                    ],
                  ),
                  if (sku != null) ...[
                    const SizedBox(height: 2),
                    Text(sku,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')),
                  ],
                  const SizedBox(height: 6),
                  // ── Location ─────────────────────────────────────────
                  if (moved && fromRoom != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '$fromRoom  →  $toRoom',
                            style: TextStyle(fontSize: 12, color: AppColors.tBody(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            toRoom,
                            style: TextStyle(fontSize: 12, color: AppColors.tBody(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  // ── Reader + RSSI + time ───────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.router_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          readerId,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (rssi != null) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.signal_cellular_alt_rounded, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Text('$rssi dBm',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                      const SizedBox(width: 8),
                      Text(timeAgo,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
