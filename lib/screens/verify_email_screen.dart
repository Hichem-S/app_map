import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({Key? key}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes  = List.generate(6, (_) => FocusNode());
  bool _loading    = false;
  bool _resending  = false;
  String _email    = '';
  String? _devOtp;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) {
      _email = arg;
    } else if (arg is Map) {
      _email  = arg['email'] as String? ?? '';
      _devOtp = arg['devOtp'] as String?;
      if (_devOtp != null && _devOtp!.length == 6) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = _devOtp![i];
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes)  f.dispose();
    super.dispose();
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    final otp = _otpValue;
    if (otp.length < 6) {
      _snack('Enter the complete 6-digit code');
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService.verifyEmail(_email, otp);
      if (!mounted) return;
      if (data['success'] == true) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        _snack(data['message'] ?? 'Invalid or expired code');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final data = await ApiService.resendVerification(_email);
      if (!mounted) return;
      final newDevOtp = data['devOtp'] as String?;
      if (newDevOtp != null && newDevOtp.length == 6) {
        setState(() => _devOtp = newDevOtp);
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = newDevOtp[i];
        }
        _snack('Email failed â€” code auto-filled: $newDevOtp');
      } else {
        _snack('New code sent â€” check your inbox');
      }
    } catch (_) {
      if (mounted) _snack('Could not resend. Try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Dev-mode banner
              if (_devOtp != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Email delivery failed. Code auto-filled: $_devOtp',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Icon with subtle glow ring
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  gradient: AppColors.gradPrimary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppColors.shadowColored(AppColors.primary),
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),

              const Text(
                'Verify your email',
                style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textH,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14, color: AppColors.textBody, height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to\n'),
                    TextSpan(
                      text: _email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.shadowLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGlow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'EMAIL VERIFICATION',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.primary, letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Enter verification code',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textH,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The code expires in 24 hours',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),

                    // OTP boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => _OtpBox(
                        controller: _otpControllers[i],
                        focusNode: _otpFocusNodes[i],
                        onChanged: (v) => _onOtpChanged(i, v),
                        onBackspace: i > 0
                            ? () {
                                if (_otpControllers[i].text.isEmpty) {
                                  _otpFocusNodes[i - 1].requestFocus();
                                  _otpControllers[i - 1].clear();
                                }
                              }
                            : null,
                      )),
                    ),
                    const SizedBox(height: 24),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Verify email',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Resend link
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Didn't get the email? ",
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    _resending
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : GestureDetector(
                            onTap: _resend,
                            child: const Text(
                              'Resend code',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
                  child: const Text(
                    'Use a different account',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ OTP box â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40, height: 52,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace?.call();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textH,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}


