import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class TransferRequestsScreen extends StatefulWidget {
  const TransferRequestsScreen({super.key});
  @override
  State<TransferRequestsScreen> createState() => _TransferRequestsScreenState();
}

class _TransferRequestsScreenState extends State<TransferRequestsScreen> {
  List<dynamic> _requests = [];
  bool _loading = true;
  String _filter = 'all';

  static const _filters = ['all', 'pending', 'approved', 'rejected'];
  static const _statusColor = {
    'pending':  Color(0xFFF59E0B),
    'approved': Color(0xFF22C55E),
    'rejected': Color(0xFFEF4444),
  };
  static const _statusIcon = {
    'pending':  Icons.hourglass_top_rounded,
    'approved': Icons.check_circle_rounded,
    'rejected': Icons.cancel_rounded,
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getTransfers(
          status: _filter == 'all' ? null : _filter);
      if (!mounted) return;
      setState(() { _requests = res['data'] as List? ?? []; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _resolve(String id, String action) async {
    try {
      if (action == 'approve') await ApiService.approveTransfer(id);
      else await ApiService.rejectTransfer(id);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.read<AuthProvider>().user?['role'] != 'user';

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Transfer Requests',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _load),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: _filters.map((f) {
            final sel = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () { setState(() { _filter = f; _loading = true; }); _load(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppColors.textMuted)),
                ),
              ),
            );
          }).toList()),
        ),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _requests.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.swap_horiz_rounded, size: 52, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('No transfer requests', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load, color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _TransferCard(
                      request: _requests[i],
                      isStaff: isStaff,
                      statusColor: _statusColor,
                      statusIcon: _statusIcon,
                      onResolve: _resolve,
                    ),
                  ))),
      ]),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final dynamic request;
  final bool isStaff;
  final Map<String, Color> statusColor;
  final Map<String, IconData> statusIcon;
  final void Function(String id, String action) onResolve;

  const _TransferCard({required this.request, required this.isStaff,
      required this.statusColor, required this.statusIcon, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String;
    final sColor = statusColor[status] ?? AppColors.textMuted;
    final sIcon  = statusIcon[status]  ?? Icons.circle;
    final product    = request['product']     as Map<String, dynamic>? ?? {};
    final requester  = request['requested_by'] as Map<String, dynamic>? ?? {};
    final fromRoom   = request['from_room']   as Map<String, dynamic>?;
    final toRoom     = request['to_room']     as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context), borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.shadowMd,
        border: Border.all(color: sColor.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product['name'] as String? ?? '—',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textH)),
            Text(product['sku'] as String? ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(sIcon, size: 12, color: sColor),
              const SizedBox(width: 4),
              Text(status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sColor)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(requester['name'] as String? ?? '—',
              style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
          const Spacer(),
          const Icon(Icons.meeting_room_outlined, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text('${fromRoom?['name'] ?? '—'} → ${toRoom?['name'] ?? '—'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
        ]),
        if (request['notes'] != null) ...[
          const SizedBox(height: 6),
          Text(request['notes'] as String,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
        ],
        if (isStaff && status == 'pending') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Btn('Approve', const Color(0xFF22C55E),
                () => onResolve(request['id'] as String, 'approve'))),
            const SizedBox(width: 8),
            Expanded(child: _Btn('Reject', AppColors.error,
                () => onResolve(request['id'] as String, 'reject'))),
          ]),
        ],
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35))),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ),
  );
}
