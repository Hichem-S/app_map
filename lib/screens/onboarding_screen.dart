import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF4F46E5),
      bg: Color(0xFFEEF2FF),
      title: 'Smart Inventory',
      subtitle: 'ISET Mahdia',
      body: 'Track, manage and monitor all IT equipment across departments — from computers to servers, in real time.',
    ),
    _Slide(
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF0EA5E9),
      bg: Color(0xFFE0F2FE),
      title: 'Scan Anything',
      subtitle: 'QR · RFID · Barcode',
      body: 'Point your camera at any QR code or barcode to instantly pull up equipment details, location and history.',
    ),
    _Slide(
      icon: Icons.build_rounded,
      color: Color(0xFFF59E0B),
      bg: Color(0xFFFEF3C7),
      title: 'Maintenance Tracking',
      subtitle: 'Schedule · Track · Report',
      body: 'Create maintenance tasks, add repair notes, set recurring schedules and generate PDF reports in one tap.',
    ),
    _Slide(
      icon: Icons.bar_chart_rounded,
      color: Color(0xFF22C55E),
      bg: Color(0xFFDCFCE7),
      title: 'Analytics & Alerts',
      subtitle: 'Real-time insights',
      body: 'Get instant alerts for critical equipment, low stock and expiring warranties. View trends on the analytics dashboard.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _slides[_page].bg,
      body: SafeArea(
        child: Column(children: [
          // Skip button
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: _finish,
              child: const Text('Skip', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            ),
          ),

          // Pages
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
            ),
          ),

          // Dots + button
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Column(children: [
              // Dot indicators
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? _slides[_page].color : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )),
              const SizedBox(height: 24),

              // Next / Get Started button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_page < _slides.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slides[_page].color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _page < _slides.length - 1 ? 'Next' : 'Get Started',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Icon circle
        Container(
          width: 140, height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: slide.color.withOpacity(0.2), blurRadius: 40, spreadRadius: 8),
            ],
          ),
          child: Icon(slide.icon, size: 70, color: slide.color),
        ),
        const SizedBox(height: 48),

        // Title
        Text(slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: slide.color)),
        const SizedBox(height: 6),

        // Subtitle chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: slide.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(slide.subtitle,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: slide.color)),
        ),
        const SizedBox(height: 24),

        // Body
        Text(slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.textBody, height: 1.6)),
      ]),
    );
  }
}

class _Slide {
  final IconData icon;
  final Color color, bg;
  final String title, subtitle, body;
  const _Slide({required this.icon, required this.color, required this.bg,
      required this.title, required this.subtitle, required this.body});
}
