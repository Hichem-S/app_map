import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/room.dart';
import '../models/department.dart';
import '../widgets/live_room_card.dart';
import 'room_items_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GI Department',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B5BDB)),
        useMaterial3: true,
      ),
      home: const DepartementGIScreen(),
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class DepartementGIScreen extends StatefulWidget {
  const DepartementGIScreen({super.key});

  @override
  State<DepartementGIScreen> createState() => _DepartementGIScreenState();
}

class _DepartementGIScreenState extends State<DepartementGIScreen> {
  static const Color _headerBlue     = Color(0xFF3B5BDB);
  static const Color _headerBlueDark = Color(0xFF2F4AC0);

  List<Room> _rooms = [];
  bool _roomsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final data = await ApiService.getDepartmentRoomsByCode('I');
      if (mounted) setState(() {
        _rooms = data.map((r) => Room.fromJson(r as Map<String, dynamic>)).toList();
        _roomsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _roomsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_headerBlue, _headerBlueDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                  const Spacer(),
                  _qrDeptButton(context),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: const Text('GI', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 4),
                      const Text('Génie Informatique', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text('هندسة المعلوماتية', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _statCard('${_rooms.length}', 'Salles'),
                  const SizedBox(width: 8),
                  _statCard('${_rooms.fold(0, (s, r) => s + r.productCount)}', 'Équip.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _qrDeptButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDeptQrDialog(context, 'I', 'Génie Informatique'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text('QR Dépt.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showDeptQrDialog(BuildContext context, String code, String name) {
    ApiService.addDeptQrHistory(code, name);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _headerBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.qr_code_2_rounded, color: _headerBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('Code: $code', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ApiService.departmentQrUrlByCode(code),
                  width: 220, height: 220, fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null ? child :
                      const SizedBox(width: 220, height: 220, child: Center(child: CircularProgressIndicator())),
                  errorBuilder: (_, __, ___) => const SizedBox(width: 220, height: 220,
                      child: Center(child: Icon(Icons.error_outline, color: Colors.red, size: 40))),
                ),
              ),
              const SizedBox(height: 12),
              Text('Scan to access $name inventory', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final path = await ApiService.saveDeptQrToGallery(code, name);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(path != null ? 'Saved: ${path.split('/').last}' : 'Failed to save QR code'),
                      ));
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download QR'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ─── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildEtatMateriel(),
          const SizedBox(height: 24),
          _buildSallesSection(),
          const SizedBox(height: 24),
          _buildResponsable(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── État du Matériel ────────────────────────────────────────────────────

  Widget _buildEtatMateriel() {
    final inStock  = _rooms.fold(0, (s, r) => s + r.inStock);
    final inMaint  = _rooms.fold(0, (s, r) => s + r.inMaintenance);
    final critical = _rooms.fold(0, (s, r) => s + r.criticalIssue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ÉTAT DU MATÉRIEL',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: Colors.black54)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statusCard(value: '$inStock', label: 'Op.', dotColor: const Color(0xFF22C55E), bg: const Color(0xFFDCFCE7), valueColor: const Color(0xFF16A34A))),
            const SizedBox(width: 10),
            Expanded(child: _statusCard(value: '$inMaint', label: 'Maint.', dotColor: const Color(0xFFF59E0B), bg: const Color(0xFFFEF9C3), valueColor: const Color(0xFFD97706))),
            const SizedBox(width: 10),
            Expanded(child: _statusCard(value: '$critical', label: 'Défect.', dotColor: const Color(0xFFEF4444), bg: const Color(0xFFFFE4E4), valueColor: const Color(0xFFDC2626))),
          ],
        ),
      ],
    );
  }

  Widget _statusCard({required String value, required String label, required Color dotColor, required Color bg, required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: valueColor)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Salles ───────────────────────────────────────────────────────────────

  Widget _buildSallesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Department Rooms',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A2340))),
            Text('${_rooms.length} salle(s)', style: const TextStyle(fontSize: 13, color: Colors.black45)),
          ],
        ),
        const SizedBox(height: 12),
        if (_roomsLoading)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_rooms.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Aucune salle trouvée', style: TextStyle(color: Colors.grey[400])),
          ))
        else
          ..._rooms.map((room) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LiveRoomCard(
                  room: room,
                  deptColor: _headerBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomItemsScreen(
                        room: room,
                        department: const Department(
                          id: '', code: 'I', name: 'Génie Informatique', color: '3B5BDB'),
                      ),
                    ),
                  ),
                  onRoomUpdated: (updated) {
                    setState(() {
                      final idx = _rooms.indexWhere((r) => r.id == updated.id);
                      if (idx != -1) _rooms[idx] = updated;
                    });
                  },
                ),
              )),
      ],
    );
  }

  // ─── Responsable ─────────────────────────────────────────────────────────

  Widget _buildResponsable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Department Head', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: _headerBlue, borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('TJ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tarek Jellad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2340))),
                  SizedBox(height: 2),
                  Text('Department Head — GI', style: TextStyle(fontSize: 13, color: Colors.black45)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
