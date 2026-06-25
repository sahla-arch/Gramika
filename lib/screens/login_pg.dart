import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'superadmin/super_admin_dash.dart';
import 'customer_home.dart';
import 'signup_pg.dart';
import '/screens/admins/admin.dart';
import 'change_password_page.dart';
import 'terms_conditions_page.dart';
import 'cmplt_profile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  bool isGoogleLoading = false;

  String? emailError;
  String? passwordError;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ── Validators ──────────────────────────────────────────────

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email address cannot be empty';
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim()))
      return 'Please enter a valid email address';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password cannot be empty';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return 'Must contain at least 1 uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value))
      return 'Must contain at least 1 number';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value)) {
      return 'Must contain at least 1 special character';
    }
    return null;
  }

  bool _validateAll() {
    final eErr = _validateEmail(emailController.text);
    final pErr = _validatePassword(passwordController.text);
    setState(() {
      emailError = eErr;
      passwordError = pErr;
    });
    return eErr == null && pErr == null;
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_validateAll()) return;

    try {
      setState(() => isLoading = true);

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String email = userCredential.user!.email!.trim();

      QuerySnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userData.docs.isEmpty) {
        throw Exception("User not found in Firestore");
      }
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        final userMap = result.docs.first.data() as Map<String, dynamic>;

        if ((userMap['accountDeleted'] ?? false) == true) {
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This account has been deleted.')),
          );

          return;
        }
      }

      String role = userData.docs.first['role'].toString().toLowerCase();
      await FirebaseFirestore.instance.collection('visitor_logs').add({
        'userId': userCredential.user!.uid,
        'email': email,
        'role': role,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      if (role == 'superadmin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminPage()),
        );
      } else if (role == 'admin') {
        final userDoc = userData.docs.first;

        final mustChangePassword =
            userDoc.data().toString().contains('mustChangePassword')
            ? userDoc['mustChangePassword']
            : false;

        if (mustChangePassword == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminPage()),
          );
        }
      } else {
        final userMap = userData.docs.first.data() as Map<String, dynamic>;

        final termsAccepted = userMap['termsAccepted'] ?? true;

        final profileComplete = userMap['isProfileComplete'] ?? false;

        if (termsAccepted != true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
          );
        } else if (profileComplete != true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHome()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Login Failed")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      setState(() => isGoogleLoading = true);

      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      final userCredential = await FirebaseAuth.instance.signInWithPopup(
        googleProvider,
      );

      final user = userCredential.user!;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? '',
          'role': 'customer',
          'isProfileComplete': false,
          'termsAccepted': false,
          'createdAt': Timestamp.now(),
        });

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
        );

        return;
      }

      final data = userDoc.data() ?? {};

      final termsAccepted = data['termsAccepted'] ?? true;

      final profileComplete = data['isProfileComplete'] ?? false;

      if (!mounted) return;

      if (termsAccepted != true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
        );
      } else if (profileComplete != true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHome()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
    } finally {
      if (mounted) {
        setState(() => isGoogleLoading = false);
      }
    }
  }
  // ── UI ───────────────────────────────────────────────────────

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
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ──
                      _buildHeader(),

                      const SizedBox(height: 36),

                      // ── Card ──
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to your Gramika account',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.grey.shade500,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Email
                            _buildLabel('Email Address'),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: emailController,
                              hint: 'you@example.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              error: emailError,
                              onChanged: (v) {
                                if (emailError != null) {
                                  setState(
                                    () => emailError = _validateEmail(v),
                                  );
                                }
                              },
                            ),

                            const SizedBox(height: 20),

                            // Password
                            _buildLabel('Password'),
                            const SizedBox(height: 6),
                            _buildPasswordField(),

                            // Password hints
                            if (passwordError != null) ...[
                              const SizedBox(height: 10),
                              _buildPasswordRequirements(),
                            ],

                            const SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  // Forgot Password logic
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Login button
                            _buildPrimaryButton(
                              label: 'Sign In',
                              isLoading: isLoading,
                              onTap: _handleLogin,
                            ),

                            const SizedBox(height: 20),

                            _buildDivider(),

                            const SizedBox(height: 20),

                            // Google button
                            _buildGoogleButton(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign up prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignUpPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
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

  // ── Sub-widgets ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_city_rounded,
            size: 38,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Gramika',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Connect with your local community',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? error,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: hasError ? Colors.red.shade50 : const Color(0xFFF8F8F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red.shade300 : const Color(0xFFE0DDD7),
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
                color: hasError ? Colors.red.shade400 : Colors.grey.shade500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 13,
                color: Colors.red.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                error,
                style: TextStyle(fontSize: 12, color: Colors.red.shade600),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField() {
    final hasError = passwordError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: hasError ? Colors.red.shade50 : const Color(0xFFF8F8F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red.shade300 : const Color(0xFFE0DDD7),
              width: 1.4,
            ),
          ),
          child: TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            onChanged: (v) {
              if (passwordError != null) {
                setState(() => passwordError = _validatePassword(v));
              }
            },
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A)),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: hasError ? Colors.red.shade400 : Colors.grey.shade500,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
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
                  passwordError!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final pwd = passwordController.text;
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

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade500, Colors.deepOrange.shade500],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
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
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: isGoogleLoading ? null : _handleGoogleLogin,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0DDD7), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isGoogleLoading
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
                    // Google "G" icon drawn manually with colours
                    _GoogleIcon(),
                    const SizedBox(width: 10),
                    const Text(
                      'Continue with Google',
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

// ── Google coloured "G" ──────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    // Draw arcs for each colour segment of the G
    final rect = Rect.fromCircle(center: center, radius: radius);
    final segments = [
      // [startAngle, sweepAngle, color]
      [-0.52, 1.57, const Color(0xFF4285F4)], // blue (top right)
      [1.05, 1.57, const Color(0xFF34A853)], // green (bottom right)
      [2.62, 1.0, const Color(0xFFFBBC05)], // yellow (bottom left)
      [3.62, 1.1, const Color(0xFFEA4335)], // red (top left)
    ];

    for (final s in segments) {
      final paint = Paint()
        ..color = s[2] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.28;
      canvas.drawArc(
        rect.deflate(size.width * 0.14),
        s[0] as double,
        s[1] as double,
        false,
        paint,
      );
    }

    // White cutout for inner "G" bar
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - size.height * 0.14,
        size.width * 0.42,
        size.height * 0.28,
      ),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Helper model ─────────────────────────────────────────────────
class _Rule {
  final String label;
  final bool met;
  const _Rule(this.label, this.met);
}
