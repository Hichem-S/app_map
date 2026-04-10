import 'package:flutter/material.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isCameraTab = true;
  bool _isFlashOn = false;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  final List<Map<String, String>> _recentScans = [
    {'name': 'Wireless Mouse', 'code': 'QR-2024-001', 'time': '2 hours ago'},
    {'name': 'Laptop Stand', 'code': 'QR-2024-002', 'time': '5 hours ago'},
    {'name': 'USB-C Cable', 'code': 'QR-2024-003', 'time': '1 day ago'},
  ];

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  void _simulateScan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('QR Code Detected'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item found:',
                style: TextStyle(color: Color(0xFF707070), fontSize: 13)),
            SizedBox(height: 4),
            Text('Wireless Keyboard',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 4),
            Text('QR-2024-004',
                style: TextStyle(color: Color(0xFF707070), fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF707070))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C63FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add to Inventory',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QR Code Scanner',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            Text('Scan to add items to inventory',
                style: TextStyle(fontSize: 12, color: Color(0xFF707070))),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4C63FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE0E0E0)),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tab switcher
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTab(
                        Icons.camera_alt_outlined, 'Camera Scan', _isCameraTab,
                        () {
                      setState(() => _isCameraTab = true);
                    }),
                    _buildTab(
                        Icons.keyboard_outlined, 'Manual Entry', !_isCameraTab,
                        () {
                      setState(() => _isCameraTab = false);
                    }),
                  ],
                ),
              ),
            ),

            if (_isCameraTab) ...[
              // Info banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4C63FF), Color(0xFF3D52CC)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Position QR Code in Frame',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        SizedBox(height: 2),
                        Text(
                            'Align the QR code within the scanning area for best results',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Active',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Camera view
              Container(
                width: double.infinity,
                height: 320,
                color: const Color(0xFF0D1117),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Scanner frame
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Stack(
                        children: [
                          // Corner accents
                          _corner(Alignment.topLeft, true, true),
                          _corner(Alignment.topRight, false, true),
                          _corner(Alignment.bottomLeft, true, false),
                          _corner(Alignment.bottomRight, false, false),
                          // Scan line
                          AnimatedBuilder(
                            animation: _scanLineAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _scanLineAnimation.value * 200,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF4C63FF),
                                        Colors.transparent
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // QR icon in center
                          const Center(
                            child: Icon(Icons.qr_code_2,
                                color: Colors.white24, size: 60),
                          ),
                        ],
                      ),
                    ),
                    // Scanning label
                    Positioned(
                      bottom: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.sync, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Scanning for QR codes...',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlButton(
                      icon: _isFlashOn
                          ? Icons.flash_on
                          : Icons.flashlight_on_outlined,
                      label: _isFlashOn ? 'Flash On' : 'Flash Off',
                      filled: false,
                      onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                    ),
                    _controlButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Simulate Scan',
                      filled: true,
                      onTap: _simulateScan,
                    ),
                    _controlButton(
                      icon: Icons.image_outlined,
                      label: 'Upload Image',
                      filled: false,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Manual Entry Tab
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter QR Code manually',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'e.g. QR-2024-001',
                        hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                        prefixIcon:
                            const Icon(Icons.qr_code, color: Color(0xFFB0B0B0)),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _simulateScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Search',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Scanning Tips
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                    left: BorderSide(color: Color(0xFF4C63FF), width: 4)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF4C63FF), size: 20),
                      SizedBox(width: 8),
                      Text('Scanning Tips',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'Ensure adequate lighting for better scan accuracy',
                    'Hold your device steady and keep the QR code within the frame',
                    'Clean your camera lens if the scanner is having trouble focusing',
                    'If scanning fails, try manual entry or upload an image of the QR code',
                  ].map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: Color(0xFF4C63FF), fontSize: 16)),
                            Expanded(
                                child: Text(tip,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF707070)))),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            // Recent Scans
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: Color(0xFF4C63FF), size: 20),
                      SizedBox(width: 8),
                      Text('Recent Scans',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Your recently scanned items',
                      style: TextStyle(fontSize: 13, color: Color(0xFF707070))),
                  const SizedBox(height: 16),
                  ..._recentScans.map((scan) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.qr_code_2,
                                  color: Color(0xFF4C63FF), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(scan['name']!,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A))),
                                  Text('${scan['code']} • ${scan['time']}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF707070))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F9F2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.4)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Color(0xFF10B981), size: 14),
                                  SizedBox(width: 4),
                                  Text('Success',
                                      style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
      IconData icon, String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFF707070)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF707070))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF4C63FF) : Colors.transparent,
          border: Border.all(
              color: filled ? Colors.transparent : const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: filled ? Colors.white : const Color(0xFF1A1A1A)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: filled ? Colors.white : const Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }

  Widget _corner(Alignment alignment, bool left, bool top) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            left: left
                ? const BorderSide(color: Color(0xFF4C63FF), width: 3)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: Color(0xFF4C63FF), width: 3)
                : BorderSide.none,
            top: top
                ? const BorderSide(color: Color(0xFF4C63FF), width: 3)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: Color(0xFF4C63FF), width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
