import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

// ── Model ──────────────────────────────────────────────────────────────────────

class MaintenanceTask {
  final String  id;
  final String  title;
  final String? description;
  final String  priority;
  final String  status;
  final String? scheduledDate;
  final String? completedAt;
  final String  createdAt;
  final int?    recurrenceIntervalDays;
  final Map<String, dynamic> product;
  final Map<String, dynamic> createdBy;
  final Map<String, dynamic>? assignedTo;

  MaintenanceTask.fromJson(Map<String, dynamic> j)
      : id                     = j['id']                        as String,
        title                  = j['title']                     as String,
        description            = j['description']              as String?,
        priority               = j['priority']                 as String? ?? 'medium',
        status                 = j['status']                   as String? ?? 'scheduled',
        scheduledDate          = j['scheduled_date']           as String?,
        completedAt            = j['completed_at']             as String?,
        createdAt              = j['created_at']               as String? ?? '',
        recurrenceIntervalDays = j['recurrence_interval_days'] as int?,
        product                = j['product']                  as Map<String, dynamic>? ?? {},
        createdBy              = j['created_by']               as Map<String, dynamic>? ?? {},
        assignedTo             = j['assigned_to']              as Map<String, dynamic>?;

  String? get recurrenceLabel {
    switch (recurrenceIntervalDays) {
      case 7:   return 'Weekly';
      case 30:  return 'Monthly';
      case 90:  return 'Quarterly';
      case 180: return 'Biannual';
      case 365: return 'Annual';
      default:  return recurrenceIntervalDays != null ? 'Every ${recurrenceIntervalDays}d' : null;
    }
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);
  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<MaintenanceTask> _tasks = [];
  String _filter = 'all';
  bool _loading = true;

  static const _filters = ['all', 'scheduled', 'in_progress', 'done'];

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
      final res = await ApiService.getMaintenanceTasks(
          status: _filter == 'all' ? null : _filter);
      if (!mounted) return;
      setState(() {
        _tasks = (res['data'] as List? ?? [])
            .map((e) => MaintenanceTask.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
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
        backgroundColor: AppColors.card(context), elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: AppColors.tH(context)),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Maintenance', style: TextStyle(fontSize: 17,
            fontWeight: FontWeight.bold, color: AppColors.textH)),
      ),
      floatingActionButton: _isStaff
          ? FloatingActionButton.extended(
              onPressed: _showCreateSheet,
              backgroundColor: AppColors.error,
              icon: const Icon(Icons.build_rounded, color: Colors.white),
              label: const Text('New Task', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w600)))
          : null,
      body: Column(children: [
        _buildFilters(),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _tasks.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.build_outlined, size: 52, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('No maintenance tasks', style: TextStyle(
                      color: AppColors.textMuted, fontSize: 15)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _TaskCard(
                      task: _tasks[i],
                      priorityColor: _priorityColor,
                      statusColor: _statusColor,
                      isStaff: _isStaff,
                      onChanged: _load,
                      onTap: () => _showProductHistory(_tasks[i]),
                    ),
                  ))),
      ]),
    );
  }

  Widget _buildFilters() => SingleChildScrollView(
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
            child: Text(f == 'all' ? 'All' : f.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppColors.textMuted)),
          ),
        ),
      );
    }).toList()),
  );

  void _showProductHistory(MaintenanceTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductHistorySheet(
        productId:   task.product['id'] as String,
        productName: task.product['name'] as String? ?? 'Product',
      ),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTaskSheet(onCreated: _load),
    );
  }
}

// ── Task card ──────────────────────────────────────────────────────────────────

class _TaskCard extends StatefulWidget {
  final MaintenanceTask task;
  final Map<String, Color> priorityColor;
  final Map<String, Color> statusColor;
  final bool isStaff;
  final VoidCallback onChanged;
  final VoidCallback onTap;
  const _TaskCard({required this.task, required this.priorityColor,
      required this.statusColor, required this.isStaff, required this.onChanged,
      required this.onTap});
  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _busy = false;
  bool _downloading = false;

  Future<void> _setStatus(String status) async {
    setState(() => _busy = true);
    try {
      await ApiService.updateMaintenanceStatus(widget.task.id, status);
      widget.onChanged();
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _downloadReport() async {
    setState(() => _downloading = true);
    try {
      final t    = widget.task;
      final name = t.product['name'] as String? ?? 'product';
      final id   = t.product['id']   as String? ?? '';
      final path = await ApiService.downloadProductMaintenanceReport(id, name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(path != null ? 'Saved: $path' : 'Download failed'),
        backgroundColor: path != null ? const Color(0xFF22C55E) : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Download failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t       = widget.task;
    final pColor  = widget.priorityColor[t.priority] ?? AppColors.textMuted;
    final sColor  = widget.statusColor[t.status] ?? AppColors.textMuted;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pColor.withOpacity(0.25)),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(
              color: pColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textH)),
            Text(t.product['name'] as String? ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: sColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(t.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: sColor)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: pColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('${t.priority.toUpperCase()} PRIORITY',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: pColor)),
            ),
            if (t.recurrenceLabel != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D28D9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.repeat_rounded, size: 9, color: Color(0xFF6D28D9)),
                  const SizedBox(width: 3),
                  Text(t.recurrenceLabel!,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                          color: Color(0xFF6D28D9))),
                ]),
              ),
            ],
          ]),
        ]),
        if (t.description != null && t.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(t.description!, style: const TextStyle(fontSize: 12,
              color: AppColors.textBody, height: 1.4)),
        ],
        const Divider(height: 16, color: AppColors.border),
        Row(children: [
          if (t.assignedTo != null) ...[
            const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(t.assignedTo!['name'] as String? ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.textBody)),
            const SizedBox(width: 12),
          ],
          if (t.scheduledDate != null) ...[
            const Icon(Icons.schedule_outlined, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(t.scheduledDate!.substring(0, 10),
                style: const TextStyle(fontSize: 11, color: AppColors.textBody)),
          ],
          const Spacer(),
          _downloading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              : GestureDetector(
                  onTap: _downloadReport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.download_rounded, size: 13, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Report', style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ]),
                  ),
                ),
        ]),
        if (widget.isStaff && t.status != 'done' && t.status != 'cancelled') ...[
          const SizedBox(height: 12),
          Row(children: [
            if (t.status == 'scheduled')
              Expanded(child: _Btn('Start', const Color(0xFF0EA5E9), _busy,
                  () => _setStatus('in_progress'))),
            if (t.status == 'in_progress') ...[
              Expanded(child: _Btn('Done', const Color(0xFF22C55E), _busy,
                  () => _setStatus('done'))),
              const SizedBox(width: 8),
            ],
            Expanded(child: _Btn('Cancel', AppColors.error, _busy,
                () => _setStatus('cancelled'))),
          ]),
        ],
      ]),
    ));
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final bool busy;
  final VoidCallback onTap;
  const _Btn(this.label, this.color, this.busy, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: busy ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3))),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ),
  );
}

// ── Create task sheet ──────────────────────────────────────────────────────────

class _CreateTaskSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateTaskSheet({required this.onCreated});
  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  List<dynamic> _products = [];
  List<dynamic> _staff    = [];
  String? _productId, _assignedTo;
  String  _priority = 'medium';
  int?    _recurrenceDays;
  DateTime? _scheduledDate;
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _loading = true, _saving = false;

  static const _recurrenceOptions = [
    (null,  'None'),
    (7,     'Weekly'),
    (30,    'Monthly'),
    (90,    'Quarterly'),
    (180,   'Biannual'),
    (365,   'Annual'),
  ];

  @override
  void initState() { super.initState(); _loadData(); }

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    try {
      final prod  = await ApiService.getProducts(limit: 200);
      final staff = await ApiService.getStaff();
      if (!mounted) return;
      setState(() {
        _products = (prod['data'] as List? ?? []);
        _staff    = staff;
        _loading  = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _submit() async {
    if (_productId == null || _titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiService.createMaintenanceTask(
        productId:     _productId!,
        title:         _titleCtrl.text.trim(),
        description:   _descCtrl.text.trim(),
        priority:      _priority,
        assignedTo:    _assignedTo,
        scheduledDate: _scheduledDate,
        recurrenceIntervalDays: _recurrenceDays,
      );
      if (!mounted) return;
      widget.onCreated();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Maintenance task created'),
        backgroundColor: Color(0xFF22C55E), behavior: SnackBarBehavior.floating));
    } catch (_) { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(color: AppColors.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4, decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 4, 0),
          child: Row(children: [
            const Text('New Maintenance Task', style: TextStyle(fontSize: 17,
                fontWeight: FontWeight.w800, color: AppColors.textH)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context)),
          ])),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), children: [
              _label('Product *'),
              DropdownButtonFormField<String>(
                value: _productId,
                hint: const Text('Select product'),
                decoration: _deco(),
                items: _products.map((p) => DropdownMenuItem<String>(
                    value: p['id'] as String,
                    child: Text(p['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _productId = v),
              ),
              const SizedBox(height: 14),
              _label('Title *'),
              TextField(controller: _titleCtrl,
                  decoration: _deco().copyWith(hintText: 'e.g. Replace battery')),
              const SizedBox(height: 14),
              _label('Description'),
              TextField(controller: _descCtrl, maxLines: 3,
                  decoration: _deco().copyWith(hintText: 'Details about the issue...')),
              const SizedBox(height: 14),
              _label('Priority'),
              Row(children: ['low','medium','high'].map((p) {
                final sel = _priority == p;
                final col = p == 'high' ? AppColors.error : p == 'medium' ? AppColors.warning : const Color(0xFF22C55E);
                return Padding(padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? col.withOpacity(0.15) : AppColors.bgPage,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? col : AppColors.border)),
                      child: Text(p.toUpperCase(), style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: sel ? col : AppColors.textMuted)))));
              }).toList()),
              const SizedBox(height: 14),
              _label('Assign to'),
              DropdownButtonFormField<String>(
                value: _assignedTo,
                hint: const Text('Assign to technician'),
                decoration: _deco(),
                items: _staff.map((u) => DropdownMenuItem<String>(
                    value: u['id'] as String,
                    child: Text(u['name'] as String))).toList(),
                onChanged: (v) => setState(() => _assignedTo = v),
              ),
              const SizedBox(height: 14),
              _label('Scheduled date'),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setState(() => _scheduledDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(color: AppColors.bgPage,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Text(_scheduledDate == null ? 'Pick a date' :
                        '${_scheduledDate!.year}-${_scheduledDate!.month.toString().padLeft(2,'0')}-${_scheduledDate!.day.toString().padLeft(2,'0')}',
                        style: TextStyle(fontSize: 14,
                            color: _scheduledDate == null ? AppColors.textMuted : AppColors.textH)),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              _label('Recurrence'),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _recurrenceOptions.map((opt) {
                  final (days, label) = opt;
                  final sel = _recurrenceDays == days;
                  return GestureDetector(
                    onTap: () => setState(() => _recurrenceDays = days),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary.withOpacity(0.12) : AppColors.bgPage,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(label, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? AppColors.primary : AppColors.textMuted,
                      )),
                    ),
                  );
                }).toList(),
              ),
            ])),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _productId == null || _titleCtrl.text.isEmpty || _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                disabledBackgroundColor: AppColors.border,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Task', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ))),
      ]),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6),
      child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textBody)));

  InputDecoration _deco() => InputDecoration(
    filled: true, fillColor: AppColors.bgPage,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12));
}

// ── Product maintenance history sheet ──────────────────────────────────────────

class _ProductHistorySheet extends StatefulWidget {
  final String productId;
  final String productName;
  const _ProductHistorySheet({required this.productId, required this.productName});
  @override
  State<_ProductHistorySheet> createState() => _ProductHistorySheetState();
}

class _ProductHistorySheetState extends State<_ProductHistorySheet> {
  List<MaintenanceTask> _tasks = [];
  bool _loading = true;

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
  static const _statusIcon = {
    'scheduled':   Icons.schedule_rounded,
    'in_progress': Icons.autorenew_rounded,
    'done':        Icons.check_circle_rounded,
    'cancelled':   Icons.cancel_rounded,
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
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Center(child: Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 4),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_rounded, size: 18, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Maintenance History', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w800, color: AppColors.textH)),
              Text(widget.productName, style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            if (!_loading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_tasks.length} record${_tasks.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textMuted),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _tasks.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF22C55E)),
                  SizedBox(height: 12),
                  Text('No maintenance records', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _HistoryEntry(
                    task: _tasks[i],
                    priorityColor: _priorityColor,
                    statusColor: _statusColor,
                    statusIcon: _statusIcon,
                    isFirst: i == 0,
                    isLast: i == _tasks.length - 1,
                  ),
                )),
      ]),
    );
  }
}

class _HistoryEntry extends StatefulWidget {
  final MaintenanceTask task;
  final Map<String, Color> priorityColor;
  final Map<String, Color> statusColor;
  final Map<String, IconData> statusIcon;
  final bool isFirst;
  final bool isLast;
  const _HistoryEntry({required this.task, required this.priorityColor,
      required this.statusColor, required this.statusIcon,
      required this.isFirst, required this.isLast});
  @override
  State<_HistoryEntry> createState() => _HistoryEntryState();
}

class _HistoryEntryState extends State<_HistoryEntry> {
  bool _showNotes = false;

  @override
  Widget build(BuildContext context) {
    final task   = widget.task;
    final pColor = widget.priorityColor[task.priority] ?? AppColors.textMuted;
    final sColor = widget.statusColor[task.status]     ?? AppColors.textMuted;
    final sIcon  = widget.statusIcon[task.status]      ?? Icons.circle_outlined;

    final rawDate = task.completedAt ?? task.scheduledDate ?? task.createdAt;
    final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Timeline column
      SizedBox(width: 32, child: Column(children: [
        if (!widget.isFirst)
          Container(width: 2, height: 8, color: AppColors.border),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: sColor.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: sColor.withOpacity(0.4)),
          ),
          child: Icon(sIcon, size: 14, color: sColor),
        ),
        if (!widget.isLast)
          Expanded(child: Container(width: 2, color: AppColors.border, height: 40)),
      ])),
      const SizedBox(width: 10),
      // Content
      Expanded(child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgPage,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pColor.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textH))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: sColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(task.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: sColor)),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: pColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(task.priority.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: pColor)),
            ),
          ]),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(task.description!, style: const TextStyle(fontSize: 12,
                color: AppColors.textBody, height: 1.4)),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 4, children: [
            if (task.assignedTo != null)
              _chip(Icons.person_outline_rounded,
                  task.assignedTo!['name'] as String? ?? ''),
            _chip(Icons.calendar_today_outlined, dateStr),
            if (task.completedAt != null)
              _chip(Icons.check_circle_outline, 'Completed ${task.completedAt!.substring(0, 10)}',
                  color: const Color(0xFF22C55E)),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showNotes = !_showNotes),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notes_rounded, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(_showNotes ? 'Hide notes' : 'View / add notes',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              Icon(_showNotes ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 14, color: AppColors.primary),
            ]),
          ),
          if (_showNotes) ...[
            const SizedBox(height: 8),
            _NotesPanel(taskId: task.id),
          ],
        ]),
      )),
    ]);
  }

  Widget _chip(IconData icon, String label, {Color? color}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: color ?? AppColors.textMuted),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 11,
          color: color ?? AppColors.textMuted)),
    ],
  );
}

// ── Notes panel ────────────────────────────────────────────────────────────────

class _NotesPanel extends StatefulWidget {
  final String taskId;
  const _NotesPanel({required this.taskId});
  @override
  State<_NotesPanel> createState() => _NotesPanelState();
}

class _NotesPanelState extends State<_NotesPanel> {
  List<dynamic> _notes = [];
  bool _loading = true;
  bool _saving  = false;
  final _ctrl   = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final notes = await ApiService.getMaintenanceNotes(widget.taskId);
      if (mounted) setState(() { _notes = notes; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _add() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.addMaintenanceNote(widget.taskId, text);
      if (res['success'] == true && mounted) {
        _ctrl.clear();
        await _load();
      }
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.muted(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_loading)
          const Center(child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ))
        else if (_notes.isEmpty)
          const Text('No notes yet.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
        else
          ..._notes.map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(
                  ((n['author']?['name'] as String?) ?? '?')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                )),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(n['author']?['name'] as String? ?? '—',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.textH)),
                  const SizedBox(width: 6),
                  Text(_fmt(n['created_at'] as String? ?? ''),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ]),
                const SizedBox(height: 2),
                Text(n['note'] as String? ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textBody, height: 1.4)),
              ])),
            ]),
          )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(
            controller: _ctrl,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Add a repair note…',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.card(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
            ),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _saving ? null : _add,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: _saving
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 14, color: Colors.white),
            ),
          ),
        ]),
      ]),
    );
  }

  String _fmt(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}
