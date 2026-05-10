import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/department.dart';
import '../models/room.dart';
import '../utils/app_colors.dart';

class ListEquipmentScreen extends StatefulWidget {
  const ListEquipmentScreen({Key? key}) : super(key: key);

  @override
  State<ListEquipmentScreen> createState() => _ListEquipmentScreenState();
}

class _ListEquipmentScreenState extends State<ListEquipmentScreen> {
  List<Product> _all = [];
  List<Product> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String? _filterStatus;

  static const _statusOptions = [
    (null,             'All',         Color(0xFF6366F1)),
    ('in_stock',       'In Stock',    Color(0xFF10B981)),
    ('in_maintenance', 'Maintenance', Color(0xFFF59E0B)),
    ('critical_issue', 'Critical',    Color(0xFFEF4444)),
    ('retired',        'Retired',     Color(0xFF6B7280)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getProducts(limit: 200);
      if (!mounted) return;
      final rows = (res['data'] as List<dynamic>? ?? [])
          .map((r) => Product.fromJson(r as Map<String, dynamic>))
          .toList();
      setState(() { _all = rows; _loading = false; });
      _applyFilter();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((p) {
        final matchSearch = q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            (p.categoryName?.toLowerCase().contains(q) ?? false);
        final matchStatus = _filterStatus == null || p.status == _filterStatus;
        return matchSearch && matchStatus;
      }).toList();
    });
  }

  void _onStatusChanged(Product p, String newStatus) {
    _replaceProduct(p.copyWith(status: newStatus));
  }

  void _onLocationChanged(Product updated) {
    _replaceProduct(updated);
  }

  void _replaceProduct(Product updated) {
    setState(() {
      final idx = _all.indexWhere((p) => p.id == updated.id);
      if (idx != -1) _all[idx] = updated;
    });
    _applyFilter();
  }

  Widget _statCard(String label, int count, Color color, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(count.toString(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: Builder(builder: (ctx) {
          final auth = ctx.watch<AuthProvider>();
          final hints = [
            if (auth.canChangeStatus) 'Tap status to change',
            if (auth.canViewMaps) 'Tap pin to place',
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Equipment List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textH)),
              if (hints.isNotEmpty)
                Text(hints.join(' · '),
                    style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (!_loading && _error == null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _statCard('In Stock',    _all.where((p) => p.status == 'in_stock').length,       const Color(0xFF10B981), const Color(0xFFE6F9F2), Icons.check_circle),
                  const SizedBox(width: 8),
                  _statCard('Maintenance', _all.where((p) => p.status == 'in_maintenance').length, const Color(0xFFF59E0B), const Color(0xFFFFF8E6), Icons.build),
                  const SizedBox(width: 8),
                  _statCard('Critical',    _all.where((p) => p.status == 'critical_issue').length, const Color(0xFFEF4444), const Color(0xFFFFEEEE), Icons.warning_amber),
                  const SizedBox(width: 8),
                  _statCard('Retired',     _all.where((p) => p.status == 'retired').length,        const Color(0xFF6B7280), const Color(0xFFF3F4F6), Icons.archive),
                ],
              ),
            ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name, SKU, category…',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.bgMuted,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((opt) {
                      final (key, label, color) = opt;
                      final selected = _filterStatus == key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () { setState(() => _filterStatus = key); _applyFilter(); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected ? color : AppColors.bgMuted,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white : const Color(0xFF6B7280))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${_filtered.length} equipment found',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text('No equipment found',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                              ],
                            ),
                          )
                        : Builder(builder: (ctx) {
                            final auth = ctx.watch<AuthProvider>();
                            return RefreshIndicator(
                              onRefresh: _load,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                itemBuilder: (ctx2, i) => _EquipmentRow(
                                  product: _filtered[i],
                                  canPlace: auth.canViewMaps,
                                  canChangeStatus: auth.canChangeStatus,
                                  onStatusChanged:  (s) => _onStatusChanged(_filtered[i], s),
                                  onLocationChanged: (p) => _onLocationChanged(p),
                                ),
                              ),
                            );
                          }),
          ),
        ],
      ),
    );
  }
}

// ─── Row card ─────────────────────────────────────────────────────────────────

class _EquipmentRow extends StatefulWidget {
  final Product product;
  final bool canPlace;
  final bool canChangeStatus;
  final void Function(String newStatus) onStatusChanged;
  final void Function(Product updated) onLocationChanged;

  const _EquipmentRow({
    required this.product,
    required this.canPlace,
    required this.canChangeStatus,
    required this.onStatusChanged,
    required this.onLocationChanged,
  });

  @override
  State<_EquipmentRow> createState() => _EquipmentRowState();
}

class _EquipmentRowState extends State<_EquipmentRow> {
  static const _labels   = {'in_stock': 'In Stock', 'in_maintenance': 'Maintenance', 'critical_issue': 'Critical', 'retired': 'Retired'};
  static const _colors   = {'in_stock': Color(0xFF10B981), 'in_maintenance': Color(0xFFF59E0B), 'critical_issue': Color(0xFFEF4444), 'retired': Color(0xFF6B7280)};
  static const _bgColors = {'in_stock': Color(0xFFE6F9F2), 'in_maintenance': Color(0xFFFFF8E6), 'critical_issue': Color(0xFFFFEEEE), 'retired': Color(0xFFF3F4F6)};
  static const _icons    = {'in_stock': Icons.check_circle, 'in_maintenance': Icons.build, 'critical_issue': Icons.warning_amber, 'retired': Icons.archive};

  bool _savingStatus   = false;
  bool _savingLocation = false;

  Color _hexColor(String? hex) {
    if (hex == null) return const Color(0xFF6B7280);
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Color _hexBg(String? hex) => _hexColor(hex).withValues(alpha: 0.15);

  Future<void> _pickStatus() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _StatusSheet(current: widget.product.status),
    );
    if (picked == null || picked == widget.product.status) return;
    setState(() => _savingStatus = true);
    try {
      await ApiService.updateProductStatus(widget.product.id, picked);
      widget.onStatusChanged(picked);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _savingStatus = false);
    }
  }

  Future<void> _pickLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    final roomId = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LocationSheet(currentRoomId: widget.product.roomId),
    );
    // null means user dismissed; empty string means "unplace"
    if (roomId == null) return;
    setState(() => _savingLocation = true);
    try {
      final res = await ApiService.updateProductLocation(
        widget.product.id,
        roomId: roomId.isEmpty ? null : roomId,
      );
      if (res['success'] == true) {
        widget.onLocationChanged(
          Product.fromJson(res['data'] as Map<String, dynamic>),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _savingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final baseHost = ApiService.baseUrl.replaceAll('/api', '');
    final color  = _colors[p.status]   ?? const Color(0xFF6B7280);
    final bg     = _bgColors[p.status] ?? const Color(0xFFF3F4F6);
    final icon   = _icons[p.status]    ?? Icons.help_outline;
    final dColor = _hexColor(p.departmentColor);
    final dBg    = _hexBg(p.departmentColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: p.photoUrl != null
                  ? Image.network('$baseHost${p.photoUrl}', width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumb())
                  : _thumb(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(p.sku, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      if (p.categoryName != null) ...[
                        const Text('  ·  ', style: TextStyle(color: AppColors.textMuted)),
                        Flexible(
                          child: Text(p.categoryName!,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Location badge
                  if (p.roomId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: dBg, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 11, color: dColor),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${p.departmentCode ?? ''} · ${p.roomName ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: dColor),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text('Not placed yet',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status badge — tappable only for admin / magazinier
                GestureDetector(
                  onTap: (widget.canChangeStatus && !_savingStatus) ? _pickStatus : null,
                  child: _savingStatus
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 11, color: color),
                              const SizedBox(width: 3),
                              Text(_labels[p.status] ?? p.status,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                              if (widget.canChangeStatus) ...[
                                const SizedBox(width: 2),
                                Icon(Icons.expand_more, size: 11, color: color),
                              ],
                            ],
                          ),
                        ),
                ),
                if (widget.canPlace) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _savingLocation ? null : _pickLocation,
                    child: _savingLocation
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGlow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.push_pin_outlined, size: 11, color: AppColors.primary),
                                SizedBox(width: 3),
                                Text('Place', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              ],
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb() => Container(
        width: 50, height: 50,
        decoration: BoxDecoration(color: AppColors.bgMuted, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.devices_other, color: AppColors.textMuted, size: 24),
      );
}

// ─── Status sheet ─────────────────────────────────────────────────────────────

class _StatusSheet extends StatelessWidget {
  final String current;
  const _StatusSheet({required this.current});

  static const _options = [
    ('in_stock',       'In Stock',       Icons.check_circle,  Color(0xFF10B981), Color(0xFFE6F9F2)),
    ('in_maintenance', 'In Maintenance', Icons.build,         Color(0xFFF59E0B), Color(0xFFFFF8E6)),
    ('critical_issue', 'Critical Issue', Icons.warning_amber, Color(0xFFEF4444), Color(0xFFFFEEEE)),
    ('retired',        'Retired',        Icons.archive,       Color(0xFF6B7280), Color(0xFFF3F4F6)),
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

// ─── Location sheet (loads from API) ─────────────────────────────────────────

class _LocationSheet extends StatefulWidget {
  final String? currentRoomId;
  const _LocationSheet({this.currentRoomId});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  List<Department> _departments = [];
  final Map<String, List<Room>> _roomsCache = {};
  Department? _selectedDept;
  Room? _selectedRoom;
  bool _loadingDepts = true;
  bool _loadingRooms = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final raw = await ApiService.getDepartments();
      if (!mounted) return;
      setState(() {
        _departments = raw.map((d) => Department.fromJson(d as Map<String, dynamic>)).toList();
        _loadingDepts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDepts = false);
    }
  }

  Future<void> _selectDept(Department dept) async {
    setState(() { _selectedDept = dept; _selectedRoom = null; });

    if (_roomsCache.containsKey(dept.id)) return; // already loaded

    setState(() => _loadingRooms = true);
    try {
      final raw = await ApiService.getDepartmentRooms(dept.id);
      if (!mounted) return;
      _roomsCache[dept.id] = raw.map((r) => Room.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loadingRooms = false);
  }

  Color _deptColor(Department d) => d.flutterColor;
  Color _deptBg(Department d)    => d.flutterBg;

  @override
  Widget build(BuildContext context) {
    final rooms = _selectedDept != null ? (_roomsCache[_selectedDept!.id] ?? []) : <Room>[];

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Place Equipment',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
                    SizedBox(height: 2),
                    Text('Choose department then classroom',
                        style: TextStyle(fontSize: 13, color: AppColors.textBody)),
                  ],
                ),
              ),
              if (widget.currentRoomId != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, ''), // empty = unplace
                  child: const Text('Unplace', style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Departments
          const Text('Department',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textH)),
          const SizedBox(height: 10),
          _loadingDepts
              ? const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _departments.map((dept) {
                    final selected = _selectedDept?.id == dept.id;
                    final color = _deptColor(dept);
                    final bg    = _deptBg(dept);
                    return GestureDetector(
                      onTap: () => _selectDept(dept),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? color : bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? color : Colors.transparent, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.domain, color: selected ? Colors.white : color, size: 20),
                            const SizedBox(height: 4),
                            Text(dept.code,
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold,
                                    color: selected ? Colors.white : color)),
                            Text(dept.name,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: selected ? Colors.white70 : color.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

          // Rooms
          if (_selectedDept != null) ...[
            const SizedBox(height: 20),
            const Text('Classroom / Lab',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textH)),
            const SizedBox(height: 10),
            if (_loadingRooms)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ))
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: rooms.map((room) {
                      final selected = _selectedRoom?.id == room.id;
                      final color = _deptColor(_selectedDept!);
                      final bg    = _deptBg(_selectedDept!);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRoom = room),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: selected ? bg : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selected ? color : AppColors.border,
                                width: selected ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.meeting_room_outlined, size: 18,
                                  color: selected ? color : AppColors.textMuted),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(room.name,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                        color: selected ? color : AppColors.textH)),
                              ),
                              if (room.productCount > 0)
                                Text('${room.productCount} items',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              if (selected) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.check_circle, color: color, size: 18),
                              ],
                            ],
                          ),
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
              onPressed: _selectedRoom == null
                  ? null
                  : () => Navigator.pop(context, _selectedRoom!.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.bgMuted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Confirm Placement',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
