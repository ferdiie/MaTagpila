import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  bool _loading = false;
  String? _error;

  // Login controllers
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  bool _loginPassShow = false;

  // Sign-up controllers
  final _signEmail = TextEditingController();
  final _signPass = TextEditingController();
  final _signConfirm = TextEditingController();
  bool _signPassShow = false;
  bool _signConfirmShow = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tab.indexIsChanging) setState(() => _error = null);
      });
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _signEmail.dispose();
    _signPass.dispose();
    _signConfirm.dispose();
    super.dispose();
  }

  // ── Auth actions ───────────────────────────────────────────────────────────

  Future<void> _login() async {
    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginEmail.text.trim(),
        password: _loginPass.text,
      );
    } on FirebaseAuthException catch (e) {
      _setError(e.code);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _register() async {
    if (_signPass.text != _signConfirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    _setLoading(true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _signEmail.text.trim(),
        password: _signPass.text,
      );
    } on FirebaseAuthException catch (e) {
      _setError(e.code);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_loginEmail.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email above first.');
      return;
    }
    _setLoading(true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _loginEmail.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset email sent! Check your inbox.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      _setError(e.code);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    if (mounted) {
      setState(() {
        _loading = v;
        if (v) _error = null;
      });
    }
  }

  void _setError(String code) {
    if (mounted) setState(() => _error = _friendlyError(code));
  }

  String _friendlyError(String code) => switch (code) {
        'user-not-found' => 'No account found with that email.',
        'wrong-password' => 'Incorrect password. Try again.',
        'invalid-credential' => 'Email or password is incorrect.',
        'email-already-in-use' => 'Email is already registered.',
        'weak-password' => 'Password must be at least 6 characters.',
        'invalid-email' => 'Please enter a valid email address.',
        _ => 'Something went wrong. Please try again.',
      };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Decorative background blobs
          _blob(200, AppColors.orange.withAlpha((0.12 * 255).toInt()),
              top: -60, right: -60),
          _blob(120, AppColors.orangeLight.withAlpha((0.10 * 255).toInt()),
              top: size.height * 0.22, left: -40),
          _blob(260, AppColors.orange.withAlpha((0.08 * 255).toInt()),
              bottom: -80, left: -40),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 44),
                  _Logo(),
                  const SizedBox(height: 18),
                  const Text(
                    'Ma.Tagpila',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find the best prices near you',
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 36),

                  // ── Card ──
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 32,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Segmented tabs
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: _SegmentedTabs(controller: _tab),
                          ),

                          // Forms
                          AnimatedBuilder(
                            animation: _tab,
                            builder: (context, child) => IndexedStack(
                              index: _tab.index,
                              children: [
                                _LoginForm(
                                  emailCtrl: _loginEmail,
                                  passCtrl: _loginPass,
                                  passVisible: _loginPassShow,
                                  onTogglePass: () => setState(
                                      () => _loginPassShow = !_loginPassShow),
                                  onSubmit: _login,
                                  onForgot: _forgotPassword,
                                  loading: _loading,
                                ),
                                _SignupForm(
                                  emailCtrl: _signEmail,
                                  passCtrl: _signPass,
                                  confirmCtrl: _signConfirm,
                                  passVisible: _signPassShow,
                                  confirmVisible: _signConfirmShow,
                                  onTogglePass: () => setState(
                                      () => _signPassShow = !_signPassShow),
                                  onToggleConfirm: () => setState(() =>
                                      _signConfirmShow = !_signConfirmShow),
                                  onSubmit: _register,
                                  loading: _loading,
                                ),
                              ],
                            ),
                          ),

                          // Error banner
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: _ErrorBanner(message: _error!),
                            )
                          else
                            const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(children: [
                    const Expanded(child: Divider(color: Color(0xFFE8E0D8))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(
                              color: AppColors.textGrey
                                  .withAlpha((0.7 * 255).toInt()),
                              fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE8E0D8))),
                  ]),

                  const SizedBox(height: 16),
                  _GoogleButton(onTap: () {}),
                  const SizedBox(height: 28),

                  Text(
                    'By continuing, you agree to our Terms & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            AppColors.textGrey.withAlpha((0.65 * 255).toInt())),
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

  // Helper: positioned blob
  Widget _blob(double size, Color color,
      {double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
            colors: [Color(0xFFFFEEDD), Color(0xFFFFD4A8)]),
        boxShadow: [
          BoxShadow(
              color: AppColors.orange.withAlpha((0.25 * 255).toInt()),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.search_rounded,
              size: 44,
              color: AppColors.orange),
        ),
      ),
    );
  }
}

// ── Segmented tab switcher ────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  const _SegmentedTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _Pill(
                'Log In', controller.index == 0, () => controller.animateTo(0)),
            _Pill('Sign Up', controller.index == 1,
                () => controller.animateTo(1)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppColors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: AppColors.orange.withAlpha((0.35 * 255).toInt()),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.white : AppColors.textGrey,
              )),
        ),
      ),
    );
  }
}

// ── Shared input field ────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
            fontSize: 14,
            color: AppColors.textDark,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: AppColors.textGrey.withAlpha((0.7 * 255).toInt()),
              fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.orange, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ── Orange button ─────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;
  const _PrimaryButton(
      {required this.label, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.orangeLight, AppColors.orangeDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.orange.withAlpha((0.38 * 255).toInt()),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.white))
            : Text(label,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3)),
      ),
    );
  }
}

// ── Login form ────────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl;
  final bool passVisible, loading;
  final VoidCallback onTogglePass, onSubmit, onForgot;

  const _LoginForm({
    required this.emailCtrl,
    required this.passCtrl,
    required this.passVisible,
    required this.onTogglePass,
    required this.onSubmit,
    required this.onForgot,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Field(
            controller: emailCtrl,
            hint: 'Email address',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: passCtrl,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: !passVisible,
            suffix: IconButton(
              icon: Icon(
                passVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textGrey,
                size: 20,
              ),
              onPressed: onTogglePass,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgot,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.orange,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Forgot password?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          _PrimaryButton(label: 'Log In', onTap: onSubmit, loading: loading),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Sign-up form ──────────────────────────────────────────────────────────────

class _SignupForm extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl, confirmCtrl;
  final bool passVisible, confirmVisible, loading;
  final VoidCallback onTogglePass, onToggleConfirm, onSubmit;

  const _SignupForm({
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.passVisible,
    required this.confirmVisible,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Field(
            controller: emailCtrl,
            hint: 'Email address',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: passCtrl,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: !passVisible,
            suffix: IconButton(
              icon: Icon(
                passVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textGrey,
                size: 20,
              ),
              onPressed: onTogglePass,
            ),
          ),
          const SizedBox(height: 12),
          _Field(
            controller: confirmCtrl,
            hint: 'Confirm password',
            icon: Icons.lock_outline_rounded,
            obscure: !confirmVisible,
            suffix: IconButton(
              icon: Icon(
                confirmVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textGrey,
                size: 20,
              ),
              onPressed: onToggleConfirm,
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
              label: 'Create Account', onTap: onSubmit, loading: loading),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Google button ─────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E0D8), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha((0.04 * 255).toInt()),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/favicon.ico',
              width: 20,
              height: 20,
              // If the file is missing or corrupted, show the fallback icon
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.g_mobiledata, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
