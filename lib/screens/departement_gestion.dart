import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const MaterialApp(
    debugShowCheckedModeBanner: false, home: TCDepartmentScreen()));

class TCDepartmentScreen extends StatelessWidget {
  const TCDepartmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          // 1. Teal/Green Header Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.qr_code_scanner,
                                color: Colors.white, size: 18),
                            SizedBox(width: 5),
                            Text("QR Dépt.",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.menu_book,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("TC",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text("Commerce Techniques",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          Text("تقنيات التجارة",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopStatCard(label: "Salles", value: "2"),
                      _TopStatCard(label: "Équip.", value: "3"),
                      _TopStatCard(label: "Étud.", value: "240"),
                      _TopStatCard(label: "Ens.", value: "12"),
                    ],
                  )
                ],
              ),
            ),
          ),

          // 2. État du Matériel Section
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ÉTAT DU MATÉRIEL",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                          letterSpacing: 1.1)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                          child: _StatusCard(
                              label: "Op.",
                              value: "2",
                              color: Colors.green,
                              bgColor: const Color(0xFFE8F5E9))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatusCard(
                              label: "Maint.",
                              value: "0",
                              color: Colors.orange,
                              bgColor: const Color(0xFFFFF8E1))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatusCard(
                              label: "Défect.",
                              value: "0",
                              color: Colors.red,
                              bgColor: const Color(0xFFFFEBEE))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _StatusCard(
                              label: "Réformé",
                              value: "1",
                              color: Colors.blueGrey,
                              bgColor: const Color(0xFFF1F4F6))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatusCard(
                              label: "Réservé",
                              value: "0",
                              color: Colors.blue,
                              bgColor: const Color(0xFFE3F2FD))),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Salles du département Section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Department Rooms",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("2 salle(s)", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _RoomCard(
                    title: "Salle Informatique TC",
                    subtitle: "C101 · Bloc C · Étage 1",
                    roomType: "Laboratoire",
                    icon: Icons.science_outlined,
                    equipCount: 2,
                    opCount: 1,
                    capacity: 25,
                  ),
                  const SizedBox(height: 15),
                  _RoomCard(
                    title: "Amphithéâtre TC",
                    subtitle: "C001 · Bloc C · Étage 0",
                    roomType: "Amphithéâtre",
                    icon: Icons.theater_comedy_outlined,
                    equipCount: 1,
                    opCount: 1,
                    capacity: 120,
                  ),
                ],
              ),
            ),
          ),

          // 4. Responsable Section
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Department Head",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF00BFA5),
                          child: const Text("DY",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Dr. Youssef Slimi",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("Department Head — TC",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class _TopStatCard extends StatelessWidget {
  final String label, value;
  const _TopStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label, value;
  final Color color, bgColor;
  const _StatusCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String title, subtitle, roomType;
  final IconData icon;
  final int equipCount, opCount, capacity;

  const _RoomCard(
      {required this.title,
      required this.subtitle,
      required this.roomType,
      required this.icon,
      required this.equipCount,
      required this.opCount,
      required this.capacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: QrImageView(
                  data: title,
                  version: QrVersions.auto,
                  size: 70.0,
                  eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square, color: Color(0xFF00BFA5)),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF00BFA5)),
                ),
              ),
              const SizedBox(height: 2),
              TextButton.icon(
                onPressed: () {},
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.file_download_outlined,
                    size: 14, color: Colors.blue),
                label: const Text("QR",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(icon, size: 18, color: Colors.indigo.shade300),
                      const SizedBox(width: 5),
                      Text(roomType, style: const TextStyle(color: Colors.grey))
                    ]),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238))),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text("$equipCount équip.",
                        style: const TextStyle(
                            color: Color(0xFF546E7A),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 14, color: Colors.green),
                          const SizedBox(width: 2),
                          Text("$opCount",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text("Capacité: $capacity pers.",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
