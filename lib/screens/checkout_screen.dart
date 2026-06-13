import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

// â”€â”€ Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class Checkout {
  final String   id;
  final String   status;
  final String?  dueDate;
  final String?  returnedAt;
  final String?  notes;
  final String   createdAt;
  final Map<String, dynamic> product;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? approvedBy;

  Checkout.fromJson(Map<String, dynamic> j)
      : id         = j['id']          as String,
        status     = j['status']      as String,
        dueDate    = j['due_date']    as String?,
        returnedAt = j['returned_at'] as String?,
        notes      = j['notes']       as String?,
        createdAt  = j['created_at']  as String? ?? '',
        product    = j['product']     as Map<String, dynamic>? ?? {},
        user       = j['user']        as Map<String, dynamic>? ?? {},
        approvedBy = j['approved_by'] as Map<String, dynamic>?;
}

// â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Checkout> _all  = [];
  List<Checkout> _mine = [];
  StreamSubscription? _wsSub;
  bool _loading = true;

  static const _statusColor = {
    'pending':  Color(0xFFF59E0B),
    'approved': Color(0xFF22C55E),
    'returned': Color(0xFF64748B),
    'rejected': Color(0xFFEF4444),
    'overdue':  Color(0xFFDC2626),
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    _wsSub = WsService.stream.listen(_onWs);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  void _onWs(dynamic raw) {
    try {
      final msg = raw is String ? jsonDecode(raw) as Map<String, dynamic> : raw as Map<String, dynamic>;
      if (!mounted) return;
      if (['checkout_request','checkout_approved','checkout_rejected','checkout_returned']
          .contains(msg['type'])) {
        _load();
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final resAll  = await ApiService.getCheckouts();
      final resMine = await ApiService.getCheckouts(mine: true);
      if (!mounted) return;
      setState(() {
        _all  = (resAll['data']  as List? ?? []).map((e) => Checkout.fromJson(e as Map<String, dynamic>)).toList();
        _mine = (resMine['data'] as List? ?? []).map((e) => Checkout.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isStaff {
    final role = context.read<AuthProvider>().user?['role'] as String? ?? '';
    return role == 'admin' || role == 'technicien';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textH),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Equipment Checkout',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'My Requests'), Tab(text: 'All Requests')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(controller: _tabs, children: [
              _buildList(_mine),
              _buildList(_all),
            ]),
    );
  }

  Widget _buildList(List<Checkout> items) {
    if (items.isEmpty) return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.inbox_outlined, size: 52, color: AppColors.textMuted),
        const SizedBox(height: 12),
        const Text('No checkout requests', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
      ]),
    );
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _CheckoutCard(
          checkout: items[i],
          statusColor: _statusColor,
          isStaff: _isStaff,
          onAction: _load,
        ),
      ),
    );
  }

  void _showRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestSheet(onCreated: _load),
    );
  }
}

// â”€â”€ Checkout card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CheckoutCard extends StatefulWidget {
  final Checkout checkout;
  final Map<String, Color> statusColor;
  final bool isStaff;
  final VoidCallback onAction;
  const _CheckoutCard({required this.checkout, required this.statusColor,
      required this.isStaff, required this.onAction});
  @override
  State<_CheckoutCard> createState() => _CheckoutCardState();
}

class _CheckoutCardState extends State<_CheckoutCard> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try { await fn(); widget.onAction(); } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c     = widget.checkout;
    final color = widget.statusColor[c.status] ?? AppColors.textMuted;
    final baseHost = ApiService.baseUrl.replaceAll('/api', '');
    final photo    = c.product['photo_url'] as String?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: photo != null && photo.isNotEmpty
                ? Image.network('$baseHost$photo', width: 44, height: 44, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _productIcon())
                : _productIcon(),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.product['name'] as String? ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textH)),
            Text(c.product['sku'] as String? ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3))),
            child: Text(c.status.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
          ),
        ]),
        const Divider(height: 20, color: AppColors.border),
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(c.user['name'] as String? ?? '',
              style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
          const Spacer(),
          if (c.dueDate != null) ...[
            const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('Due: ${c.dueDate!.substring(0, 10)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
          ],
        ]),
        if (c.notes != null && c.notes!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(c.notes!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted,
              fontStyle: FontStyle.italic)),
        ],
        if (widget.isStaff && c.status == 'pending') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ActionBtn(label: 'Approve', color: const Color(0xFF22C55E),
                busy: _busy, onTap: () => _act(() => ApiService.approveCheckout(c.id)))),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(label: 'Reject', color: AppColors.error,
                busy: _busy, onTap: () => _act(() => ApiService.rejectCheckout(c.id)))),
          ]),
        ],
        if (widget.isStaff && c.status == 'approved') ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: _ActionBtn(label: 'Mark Returned', color: AppColors.primary,
                busy: _busy, onTap: () => _act(() => ApiService.returnCheckout(c.id)))),
        ],
      ]),
    );
  }

  Widget _productIcon() => Container(width: 44, height: 44,
      color: AppColors.bgMuted,
      child: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 22));
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool busy;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: busy ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3))),
      alignment: Alignment.center,
      child: busy
          ? SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(color: color, strokeWidth: 2))
          : Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ),
  );
}

// â”€â”€ Request sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RequestSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _RequestSheet({required this.onCreated});
  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  List<dynamic> _products = [];
  String? _selectedId;
  DateTime? _dueDate;
  final _notesCtrl = TextEditingController();
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Future<void> _loadProducts() async {
    try {
      final res = await ApiService.getProducts(limit: 200);
      if (!mounted) return;
      setState(() {
        _products = (res['data'] as List? ?? [])
            .where((p) => (p as Map)['status'] == 'in_stock').toList();
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _submit() async {
    if (_selectedId == null) return;
    setState(() => _saving = true);
    try {
      await ApiService.requestCheckout(_selectedId!, dueDate: _dueDate, notes: _notesCtrl.text.trim());
      if (!mounted) return;
      widget.onCreated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Request submitted â€” waiting for approval'),
        backgroundColor: Color(0xFF22C55E), behavior: SnackBarBehavior.floating));
    } catch (_) { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4, decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            const Text('Request Equipment', style: TextStyle(fontSize: 17,
                fontWeight: FontWeight.w800, color: AppColors.textH)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context)),
          ])),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), children: [
              const Text('Select equipment', style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: AppColors.textBody)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedId,
                hint: const Text('Choose an item'),
                decoration: InputDecoration(
                  filled: true, fillColor: AppColors.bgPage,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none)),
                items: _products.map((p) => DropdownMenuItem<String>(
                  value: p['id'] as String,
                  child: Text(p['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedId = v),
              ),
              const SizedBox(height: 16),
              const Text('Return date (optional)', style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: AppColors.textBody)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setState(() => _dueDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(color: AppColors.bgPage,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Text(_dueDate == null ? 'Pick a date' :
                        '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2,'0')}-${_dueDate!.day.toString().padLeft(2,'0')}',
                        style: TextStyle(fontSize: 14,
                            color: _dueDate == null ? AppColors.textMuted : AppColors.textH)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Notes (optional)', style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: AppColors.textBody)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Why do you need this item?',
                  filled: true, fillColor: AppColors.bgPage,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none)),
              ),
            ])),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedId == null || _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.border,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Request',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ))),
      ]),
    );
  }
}


