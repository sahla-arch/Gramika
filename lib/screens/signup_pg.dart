import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cmplt_profile.dart';
import 'terms_conditions_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // Inline error strings — null means no error shown yet
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _generalError;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Validators ────────────────────────────────────────────────

  String? _validateName(String v) {
    if (v.trim().isEmpty) return 'Full name cannot be empty';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String v) {
    if (v.trim().isEmpty) return 'Email address cannot be empty';
    final re = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
    if (!re.hasMatch(v.trim())) return 'Please enter a valid email address';
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return 'Password cannot be empty';
    if (v.length < 8) return 'At least 8 characters required';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must include 1 uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must include 1 number';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) {
      return 'Must include 1 special character';
    }
    return null;
  }

  String? _validateConfirm(String v) {
    if (v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  bool _validateAll() {
    final nErr = _validateName(_nameController.text);
    final eErr = _validateEmail(_emailController.text);
    final pErr = _validatePassword(_passwordController.text);
    final cErr = _validateConfirm(_confirmController.text);
    setState(() {
      _nameError = nErr;
      _emailError = eErr;
      _passwordError = pErr;
      _confirmError = cErr;
      _generalError = null;
    });
    return nErr == null && eErr == null && pErr == null && cErr == null;
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return '';
      case 'invalid-email':
        return 'This email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use the requirements below.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }

  // ── Auth actions ──────────────────────────────────────────────

  Future<void> _handleSignUp() async {
    if (!_validateAll()) return;
    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save name to Firebase Auth profile
      await cred.user?.updateDisplayName(_nameController.text.trim());

      // Create user doc in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'uid': cred.user!.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'photoUrl': '',
            'createdAt': FieldValue.serverTimestamp(),
            'isProfileComplete': false,
            'termsAccepted': false,
            'role': 'customer',
          });

      await FirebaseFirestore.instance.collection('visitor_logs').add({
        'userId': cred.user!.uid,
        'email': _emailController.text.trim(),
        'role': 'user',
        'panchayat': '',
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .get();

          final data = doc.data() ?? {};

          final termsAccepted = data['termsAccepted'] ?? false;

          final profileComplete = data['isProfileComplete'] ?? false;

          if (!mounted) return;

          if (!termsAccepted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
            );
          } else if (!profileComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
            );
          } else {
            setState(() {
              _generalError =
                  'An account with this email already exists. Please sign in.';
            });
          }

          return;
        } on FirebaseAuthException {
          setState(() {
            _generalError =
                'This email is already registered with another password.';
          });

          return;
        }
      }

      setState(() {
        _generalError = _friendlyError(e.code);
      });
    } catch (e) {
      setState(() => _generalError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isGoogleLoading = true;
      _generalError = null;
    });
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      if (!googleSignIn.supportsAuthenticate()) {
        throw Exception('Google sign-in is not supported on this platform.');
      }

      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);

      // Only create Firestore doc if new user
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        await docRef.set({
          'uid': cred.user!.uid,
          'name': cred.user!.displayName ?? '',
          'email': cred.user!.email ?? '',
          'photoUrl': cred.user!.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'isProfileComplete': false,
          'termsAccepted': false,
          'role': 'customer',
        });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _generalError = _friendlyError(e.code));
    } catch (e) {
      setState(
        () => _generalError = 'Google sign-up failed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildCard(),
                      const SizedBox(height: 20),
                      _buildLoginRow(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.38),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Join Gramika',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create your community account',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // ── Card ──────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fill in your details to get started',
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
          ),

          // General error banner
          if (_generalError != null) ...[
            const SizedBox(height: 16),
            _errorBanner(_generalError!),
          ],

          const SizedBox(height: 22),

          // Full Name
          _label('Full Name'),
          const SizedBox(height: 6),
          _inputField(
            controller: _nameController,
            hint: 'e.g. Arjun Menon',
            icon: Icons.person_outline_rounded,
            error: _nameError,
            onChanged: (v) {
              if (_nameError != null)
                setState(() => _nameError = _validateName(v));
            },
          ),

          const SizedBox(height: 18),

          // Email
          _label('Email Address'),
          const SizedBox(height: 6),
          _inputField(
            controller: _emailController,
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            error: _emailError,
            onChanged: (v) {
              if (_emailError != null)
                setState(() => _emailError = _validateEmail(v));
            },
          ),

          const SizedBox(height: 18),

          // Password
          _label('Password'),
          const SizedBox(height: 6),
          _passwordField(
            controller: _passwordController,
            hint: 'Create a strong password',
            hide: _hidePassword,
            error: _passwordError,
            onToggle: () => setState(() => _hidePassword = !_hidePassword),
            onChanged: (v) {
              if (_passwordError != null)
                setState(() => _passwordError = _validatePassword(v));
              // Also revalidate confirm if already touched
              if (_confirmError != null)
                setState(
                  () =>
                      _confirmError = _validateConfirm(_confirmController.text),
                );
            },
          ),

          // Live password requirements
          if (_passwordError != null) ...[
            const SizedBox(height: 10),
            _passwordRequirements(),
          ],

          const SizedBox(height: 18),

          // Confirm Password
          _label('Confirm Password'),
          const SizedBox(height: 6),
          _passwordField(
            controller: _confirmController,
            hint: 'Re-enter your password',
            hide: _hideConfirm,
            error: _confirmError,
            onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
            onChanged: (v) {
              if (_confirmError != null)
                setState(() => _confirmError = _validateConfirm(v));
            },
          ),

          const SizedBox(height: 26),

          // Create Account button
          _primaryButton(
            label: 'Create Account',
            isLoading: _isLoading,
            onTap: _handleSignUp,
          ),

          const SizedBox(height: 18),
          _divider(),
          const SizedBox(height: 18),

          // Google button
          _googleButton(),
        ],
      ),
    );
  }

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Sign In',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ── Reusable sub-widgets ──────────────────────────────────────

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: Color(0xFF333333),
    ),
  );

  Widget _errorBanner(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade500, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? error,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    final hasErr = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: hasErr ? Colors.red.shade50 : const Color(0xFFF8F8F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasErr ? Colors.red.shade300 : const Color(0xFFE0DDD7),
              width: 1.4,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: hasErr ? Colors.red.shade400 : Colors.grey.shade500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (hasErr) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 13,
                color: Colors.red.shade500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool hide,
    String? error,
    required VoidCallback onToggle,
    void Function(String)? onChanged,
  }) {
    final hasErr = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: hasErr ? Colors.red.shade50 : const Color(0xFFF8F8F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasErr ? Colors.red.shade300 : const Color(0xFFE0DDD7),
              width: 1.4,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: hide,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: hasErr ? Colors.red.shade400 : Colors.grey.shade500,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  hide
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (hasErr) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 13,
                color: Colors.red.shade500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _passwordRequirements() {
    final pwd = _passwordController.text;
    final rules = [
      _Rule('At least 8 characters', pwd.length >= 8),
      _Rule('1 uppercase letter (A–Z)', RegExp(r'[A-Z]').hasMatch(pwd)),
      _Rule('1 number (0–9)', RegExp(r'[0-9]').hasMatch(pwd)),
      _Rule(
        '1 special character (!@#\$…)',
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(pwd),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 6),
          ...rules.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    r.met
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: r.met ? Colors.green.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    r.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: r.met
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade500, Colors.deepOrange.shade500],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.38),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _divider() => Row(
    children: [
      Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.2)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'or continue with',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.2)),
    ],
  );

  Widget _googleButton() {
    return GestureDetector(
      onTap: _isGoogleLoading ? null : _handleGoogleSignUp,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFE0DDD7), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: _isGoogleLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.grey.shade600,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Real Google G icon via CustomPainter
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(painter: _GoogleGPainter()),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Sign up with Google',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Google "G" brand icon ─────────────────────────────────────────
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(c, r, Paint()..color = Colors.white);

    // Four coloured arc segments
    final segs = [
      [-0.52, 1.57, const Color(0xFF4285F4)], // blue
      [1.05, 1.57, const Color(0xFF34A853)], // green
      [2.62, 1.00, const Color(0xFFFBBC05)], // yellow
      [3.62, 1.10, const Color(0xFFEA4335)], // red
    ];
    for (final s in segs) {
      canvas.drawArc(
        rect.deflate(size.width * 0.14),
        s[0] as double,
        s[1] as double,
        false,
        Paint()
          ..color = s[2] as Color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.28,
      );
    }

    // White cutout bar for inner "G" horizontal arm
    canvas.drawRect(
      Rect.fromLTWH(
        c.dx,
        c.dy - size.height * 0.14,
        size.width * 0.42,
        size.height * 0.28,
      ),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Helper ────────────────────────────────────────────────────────
class _Rule {
  final String label;
  final bool met;
  const _Rule(this.label, this.met);
}
