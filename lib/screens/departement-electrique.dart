import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GEDepartmentScreen(),
  ));
}

class GEDepartmentScreen extends StatelessWidget {
  const GEDepartmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          // --- ORANGE HEADER SECTION ---
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9100), Color(0xFFFF6D00)],
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
                      const Icon(Icons.arrow_back, color: Colors.white),
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
                          Text("GE",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text("Génie Électrique",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          Text("الهندسة الكهربائية",
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
                      _TopStatCard(label: "Équip.", value: "4"),
                      _TopStatCard(label: "Étud.", value: "280"),
                      _TopStatCard(label: "Ens.", value: "15"),
                    ],
                  )
                ],
              ),
            ),
          ),

          // --- ÉTAT DU MATÉRIEL SECTION ---
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ÉTAT DU MATÉRIEL",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF283593),
                          letterSpacing: 1.1)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                          child: _StatusCard(
                              label: "Op.",
                              value: "3",
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
                              value: "1",
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
                              value: "0",
                              color: Colors.grey,
                              bgColor: const Color(0xFFF5F5F5))),
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

          // --- SALLES DU DÉPARTEMENT SECTION ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Salles du département",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D1B3E))),
                      Text("2 salle(s)", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _RoomCard(
                    title: "Lab Électronique",
                    subtitle: "B101 · Bloc B · Étage 1",
                    qrData: "room_b101",
                    equipCount: 3,
                    opCount: 2,
                    defectCount: 1,
                    capacity: 24,
                  ),
                  const SizedBox(height: 15),
                  _RoomCard(
                    title: "Lab Automatisme",
                    subtitle: "B201 · Bloc B · Étage 2",
                    qrData: "room_b201",
                    equipCount: 1,
                    opCount: 1,
                    defectCount: 0,
                    capacity: 20,
                  ),
                ],
              ),
            ),
          ),

          // --- RESPONSABLE SECTION ---
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Responsable du Département",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B3E))),
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
                          backgroundColor: Colors.orange[800],
                          child: const Text("DL",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Dr. Leila Gharbi",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D1B3E))),
                            Text("Chef de département — GE",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// --- SUB-WIDGETS ---

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
                      color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String title, subtitle, qrData;
  final int equipCount, opCount, defectCount, capacity;

  const _RoomCard(
      {required this.title,
      required this.subtitle,
      required this.qrData,
      required this.equipCount,
      required this.opCount,
      required this.defectCount,
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR CODE SECTION
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF5F5F5)),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 65.0,
                  eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square, color: Color(0xFFFFA000)),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFFFFA000)),
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
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline)),
              )
            ],
          ),
          const SizedBox(width: 15),
          // INFO SECTION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.biotech_outlined,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text("Laboratoire",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B3E))),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text("$equipCount équip.",
                        style: const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(width: 10),
                    _badge(
                        Icons.check_circle_outline, "$opCount", Colors.green),
                    const SizedBox(width: 6),
                    if (defectCount > 0)
                      _badge(Icons.error_outline, "$defectCount", Colors.red),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("Capacité: $capacity pers.",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
