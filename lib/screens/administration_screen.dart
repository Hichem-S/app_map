import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/room.dart';
import '../models/department.dart';
import '../widgets/live_room_card.dart';
import 'room_items_screen.dart';

void main() => runApp(const MaterialApp(
    debugShowCheckedModeBanner: false, home: ADMDepartmentScreen()));

class ADMDepartmentScreen extends StatefulWidget {
  const ADMDepartmentScreen({super.key});

  @override
  State<ADMDepartmentScreen> createState() => _ADMDepartmentScreenState();
}

class _ADMDepartmentScreenState extends State<ADMDepartmentScreen> {
  static const Color _purple = Color(0xFF8E24AA);

  List<Room> _rooms = [];
  bool _roomsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final data = await ApiService.getDepartmentRoomsByCode('ADM');
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
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          // 1. PURPLE HEADER
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () => _showDeptQrDialog(context, 'ADM', 'Administration Générale'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                              SizedBox(width: 5),
                              Text("QR Dépt.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(15)),
                        child: const Icon(Icons.menu_book, color: Colors.white, size: 40),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ADM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text("Administration Générale",
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("الإدارة العامة", style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopStatCard(label: "Salles", value: "${_rooms.length}"),
                      _TopStatCard(label: "Équip.", value: "${_rooms.fold(0, (s, r) => s + r.productCount)}"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. ÉTAT DU MATÉRIEL
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ÉTAT DU MATÉRIEL",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF263238), letterSpacing: 1.1)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _StatusCard(label: "Op.", value: "${_rooms.fold(0, (s, r) => s + r.inStock)}", color: Colors.green, bgColor: const Color(0xFFE8F5E9))),
                      const SizedBox(width: 10),
                      Expanded(child: _StatusCard(label: "Maint.", value: "${_rooms.fold(0, (s, r) => s + r.inMaintenance)}", color: Colors.orange, bgColor: const Color(0xFFFFF8E1))),
                      const SizedBox(width: 10),
                      Expanded(child: _StatusCard(label: "Défect.", value: "${_rooms.fold(0, (s, r) => s + r.criticalIssue)}", color: Colors.red, bgColor: const Color(0xFFFFEBEE))),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. SALLES
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Salles du département",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${_rooms.length} salle(s)", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_roomsLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_rooms.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Aucune salle trouvée', style: TextStyle(color: Colors.grey[400])),
                    ))
                  else
                    ..._rooms.map((room) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: LiveRoomCard(
                        room: room,
                        deptColor: _purple,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomItemsScreen(
                              room: room,
                              department: const Department(
                                id: '', code: 'ADM', name: 'Administration Générale', color: '8E24AA'),
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
              ),
            ),
          ),

          // 4. RESPONSABLE
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Responsable du Département",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: _purple,
                          child: Text("FA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Fathi Ben Ahmed",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("Chef de département — ADM",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
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
                    decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.qr_code_2_rounded, color: _purple, size: 22),
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
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _TopStatCard extends StatelessWidget {
  final String label, value;
  const _TopStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label, value;
  final Color color, bgColor;
  const _StatusCard({required this.label, required this.value, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
