import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  bool   _obscurePassword  = true;
  bool   _obscureConfirm   = true;
  bool   _agreedToTerms    = false;
  bool   _isLoading        = false;
  String _selectedRole     = 'technicien';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmController.text;

    if (name.isEmpty)                    { _snack('Please enter your full name'); return; }
    if (email.isEmpty)                   { _snack('Please enter your email'); return; }
    if (!_validEmail(email))             { _snack('Please enter a valid email address'); return; }
    if (password.length < 6)            { _snack('Password must be at least 6 characters'); return; }
    if (password != confirm)            { _snack('Passwords do not match'); return; }
    if (!_agreedToTerms)                { _snack('Please agree to the terms'); return; }

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.register(name, email, password, role: _selectedRole);
      if (!mounted) return;
      if (data['success'] == true && data['requiresVerification'] == true) {
        Navigator.pushNamedAndRemoveUntil(
          context, '/verify-email', (_) => false,
          arguments: {'email': email, 'devOtp': data['devOtp'] as String?},
        );
      } else if (data['success'] == true) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        // Prefer the first specific field error over the generic "Validation failed" message
        final errors = data['errors'] as List<dynamic>?;
        final msg = (errors != null && errors.isNotEmpty)
            ? (errors.first as Map<String, dynamic>)['message'] as String? ?? 'Registration failed'
            : data['message'] as String? ?? 'Registration failed';
        _snack(msg);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static bool _validEmail(String email) {
    final i = email.indexOf('@');
    return i > 0 && i < email.length - 1 && email.contains('.', i);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Stack(
        children: [
          // Gradient blobs — top-left
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(0.10),
                  AppColors.primary.withOpacity(0),
                ]),
              ),
            ),
          ),
          // Gradient blob — bottom-right
          Positioned(
            bottom: -60, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withOpacity(0.08),
                  AppColors.accent.withOpacity(0),
                ]),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildCard(),
                  const SizedBox(height: 24),
                  _buildLoginLink(),
                  const SizedBox(height: 16),
                  const Text(
                    '© 2026 Smart Inventory · ISET Mahdia',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo block ─────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.gradPrimary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.shadowColored(AppColors.primary),
          ),
          child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          'Smart Inventory',
          style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: AppColors.textH, letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'ISET Mahdia · Equipment management',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ── Form card ──────────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
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
          // Header badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryGlow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Create account',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.primary, letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Get started',
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textH,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fill in your details to create an account',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // Full name
          _label('Full name'),
          const SizedBox(height: 6),
          _field(
            controller: _nameController,
            hint: 'John Doe',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),

          // Email
          _label('Email address'),
          const SizedBox(height: 6),
          _field(
            controller: _emailController,
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Password
          _label('Password'),
          const SizedBox(height: 6),
          _field(
            controller: _passwordController,
            hint: 'Create a password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20, color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm password
          _label('Confirm password'),
          const SizedBox(height: 6),
          _field(
            controller: _confirmController,
            hint: 'Re-enter your password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20, color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 20),

          // Role selector
          _label('Role'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _RoleChip(
                label: 'Technicien',
                icon: Icons.build_rounded,
                selected: _selectedRole == 'technicien',
                onTap: () => setState(() => _selectedRole = 'technicien'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RoleChip(
                label: 'Magazinier',
                icon: Icons.inventory_2_rounded,
                selected: _selectedRole == 'magazinier',
                onTap: () => setState(() => _selectedRole = 'magazinier'),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // Terms checkbox
          GestureDetector(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: _agreedToTerms ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _agreedToTerms ? AppColors.primary : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: _agreedToTerms
                      ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 13, color: AppColors.textBody),
                      children: [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  )
                : _GradientButton(
                    label: 'Create Account',
                    gradient: AppColors.gradPrimary,
                    onTap: _handleCreateAccount,
                  ),
          ),
          const SizedBox(height: 20),

          // Divider
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or sign up with',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 16),

          // Social buttons
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  label: 'Google',
                  icon: Icons.g_mobiledata_rounded,
                  onTap: null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SocialButton(
                  label: 'GitHub',
                  icon: Icons.code_rounded,
                  onTap: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Login link ─────────────────────────────────────────────────────────────

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(fontSize: 14, color: AppColors.textBody),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/login'),
          child: const Text(
            'Sign in',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textH,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.textH),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        suffixIcon: suffix,
      ),
    );
  }
}

// ── Role chip ─────────────────────────────────────────────────────────────────

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGlow : AppColors.bgMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22,
              color: selected ? AppColors.primary : AppColors.textMuted),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textBody,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Shared button widgets (mirrors login_screen.dart) ────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.shadowColored(AppColors.primary),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SocialButton({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.bgMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textBody),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textH,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
