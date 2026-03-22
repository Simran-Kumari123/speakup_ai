import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

// ── Onboarding ────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  final _pages = [
    _OnboardPage(emoji: '🎯', title: 'Crack Your\nDream Interview',
        subtitle: 'Practice real interview questions with AI feedback. Build confidence before the big day.',
        color: AppTheme.primary),
    _OnboardPage(emoji: '🎤', title: 'Speak English\nWith Confidence',
        subtitle: 'Record your voice, get instant feedback on fluency, grammar and pronunciation.',
        color: AppTheme.secondary),
    _OnboardPage(emoji: '📈', title: 'Track Your\nProgress Daily',
        subtitle: 'Earn XP, build streaks, and watch your communication skills improve every day.',
        color: AppTheme.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(child: Column(children: [
        Align(alignment: Alignment.topRight,
            child: Padding(padding: const EdgeInsets.all(20),
                child: TextButton(onPressed: _goToAuth,
                    child: Text('Skip', style: TextStyle(color: Colors.white38))))),
        Expanded(child: PageView.builder(
          controller: _pageCtrl,
          onPageChanged: (i) => setState(() => _page = i),
          itemCount: _pages.length,
          itemBuilder: (_, i) => _buildPage(_pages[i]),
        )),
        Padding(padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8, height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? _pages[_page].color : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ))),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _pages[_page].color, foregroundColor: AppTheme.darkBg),
                onPressed: () {
                  if (_page < _pages.length - 1) {
                    _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else { _goToAuth(); }
                },
                child: Text(_page < _pages.length - 1 ? 'Next →' : 'Get Started 🚀',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ])),
    );
  }

  Widget _buildPage(_OnboardPage p) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 140, height: 140,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: p.color.withOpacity(0.12),
              border: Border.all(color: p.color.withOpacity(0.3), width: 2)),
          child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 64)))),
      const SizedBox(height: 40),
      Text(p.title, textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
      const SizedBox(height: 16),
      Text(p.subtitle, textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 16, color: Colors.white54, height: 1.6)),
    ]),
  );

  void _goToAuth() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const AuthScreen()));
}

class _OnboardPage {
  final String emoji, title, subtitle;
  final Color color;
  const _OnboardPage({required this.emoji, required this.title, required this.subtitle, required this.color});
}

// ── Auth Screen ───────────────────────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLogin    = false;
  bool _loading    = false;
  bool _googleLoad = false;
  bool _obscure    = true;
  String _errorMsg = '';
  String _role     = 'Software Engineer';
  String _level    = 'Fresher';

  final _roles  = ['Software Engineer', 'Data Analyst', 'Product Manager', 'Business Analyst', 'Finance', 'Other'];
  final _levels = ['Fresher', '1-2 Years', '3-5 Years', '5+ Years'];

  // ── Email Auth ────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    // Validate
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please enter your email.'); return;
    }
    if (_passwordCtrl.text.trim().length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters.'); return;
    }
    if (!_isLogin && _nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please enter your name.'); return;
    }

    setState(() { _loading = true; _errorMsg = ''; });

    AuthResult result;
    if (_isLogin) {
      result = await AuthService.signIn(
          email: _emailCtrl.text, password: _passwordCtrl.text);
    } else {
      result = await AuthService.signUp(
          email: _emailCtrl.text, password: _passwordCtrl.text, name: _nameCtrl.text);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.isSuccess) {
      _goHome(result.user!);
    } else {
      setState(() => _errorMsg = result.errorMessage ?? 'Something went wrong.');
    }
  }

  // ── Google Auth ───────────────────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    setState(() { _googleLoad = true; _errorMsg = ''; });
    final result = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoad = false);

    if (result.isSuccess) {
      _goHome(result.user!);
    } else {
      setState(() => _errorMsg = result.errorMessage ?? 'Google sign-in failed.');
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Enter your email first, then tap Forgot Password.');
      return;
    }
    final result = await AuthService.resetPassword(_emailCtrl.text);
    if (!mounted) return;
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Reset email sent to ${_emailCtrl.text}'),
          backgroundColor: AppTheme.primary, behavior: SnackBarBehavior.floating));
    } else {
      setState(() => _errorMsg = result.errorMessage ?? 'Failed to send reset email.');
    }
  }

  void _goHome(User user) {
    final state = context.read<AppState>();
    state.login(
      user.displayName ?? 'Learner',
      user.email ?? '',
      role: _role, level: _level,
    );
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 20),

            // Logo
            Center(child: Column(children: [
              Container(width: 72, height: 72,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary])),
                  child: const Center(child: Text('🎤', style: TextStyle(fontSize: 36)))),
              const SizedBox(height: 12),
              Text('SpeakUp', style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('English & Interview Prep', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white38)),
            ])),

            const SizedBox(height: 36),

            // Toggle
            Container(
              decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.darkBorder)),
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                _tab('Sign Up', !_isLogin, () => setState(() { _isLogin = false; _errorMsg = ''; })),
                _tab('Sign In', _isLogin,  () => setState(() { _isLogin = true;  _errorMsg = ''; })),
              ]),
            ),

            const SizedBox(height: 24),

            // Sign up fields
            if (!_isLogin) ...[
              _label('Full Name'),
              _field(_nameCtrl, 'e.g. Simran Kumari', Icons.person_outline),
              const SizedBox(height: 14),
              _label('Target Role'),
              _dropdown(_roles, _role, (v) => setState(() => _role = v!)),
              const SizedBox(height: 14),
              _label('Experience Level'),
              _dropdown(_levels, _level, (v) => setState(() => _level = v!)),
              const SizedBox(height: 14),
            ],

            _label('Email Address'),
            _field(_emailCtrl, 'your@email.com', Icons.email_outlined),
            const SizedBox(height: 14),

            _label('Password'),
            _passwordField(),

            // Forgot password
            if (_isLogin)
              Align(alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _forgotPassword,
                      child: Text('Forgot Password?',
                          style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 13)))),

            // Error message
            if (_errorMsg.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMsg,
                      style: GoogleFonts.dmSans(color: AppTheme.danger, fontSize: 13))),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            // Submit button
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: AppTheme.darkBg, strokeWidth: 2))
                    : Text(_isLogin ? 'Sign In 🚀' : 'Create Account ✨',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 16),

            // Divider
            Row(children: [
              Expanded(child: Divider(color: AppTheme.darkBorder)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12))),
              Expanded(child: Divider(color: AppTheme.darkBorder)),
            ]),

            const SizedBox(height: 16),

            // Google Sign In
            SizedBox(width: double.infinity, height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.darkBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _googleLoad ? null : _googleSignIn,
                child: _googleLoad
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('G', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppTheme.primary)),
                  const SizedBox(width: 10),
                  Text('Continue with Google',
                      style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // Guest
            Center(child: TextButton(
              onPressed: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomeScreen())),
              child: Text('Continue as Guest →',
                  style: GoogleFonts.dmSans(color: Colors.white30, fontSize: 13)),
            )),

            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8)),
        child: Text(label, textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600,
                color: active ? AppTheme.darkBg : Colors.white38)),
      ),
    ),
  );

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white60)));

  Widget _field(TextEditingController ctrl, String hint, IconData icon) =>
      TextField(controller: ctrl, style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: AppTheme.primary, size: 20)));

  Widget _passwordField() => TextField(
    controller: _passwordCtrl, obscureText: _obscure,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: '••••••••',
      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary, size: 20),
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.white38, size: 20),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    ),
  );

  Widget _dropdown(List<String> items, String value, void Function(String?) onChange) =>
      Container(
        decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.darkBorder)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(value: value, isExpanded: true,
              dropdownColor: AppTheme.darkCard, style: const TextStyle(color: Colors.white, fontSize: 14),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChange),
        ),
      );
}