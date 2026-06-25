import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_home.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();

  String _selectedDistrict = 'Malappuram';
  String _localBodyType = 'Municipality';
  String? _selectedLocalBody;
  List<String> _selectedProfessions = [];
  bool _sameAsPhone = false;

  bool _isLoading = false;

  // Inline errors
  String? _phoneError;
  String? _whatsappError;
  String? _localBodyError;
  String? _professionError;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Data ───────────────────────────────────────────────────────

  final List<String> _districts = [
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];

  final Map<String, List<String>> _municipalities = {
    'Malappuram': [
      'Perinthalmanna Municipality',
      'Manjeri Municipality',
      'Parappanangadi Municipality',
      'Tirur Municipality',
      'Nilambur Municipality',
      'Malappuram Municipality',
    ],
    'Kozhikode': [
      'Kozhikode Corporation',
      'Vadakara Municipality',
      'Koyilandy Municipality',
      'Ramanattukara Municipality',
    ],
    'Palakkad': [
      'Palakkad Municipality',
      'Ottapalam Municipality',
      'Shornur Municipality',
      'Mannarkkad Municipality',
    ],
    'Thrissur': [
      'Thrissur Corporation',
      'Irinjalakuda Municipality',
      'Chalakudy Municipality',
      'Kodungallur Municipality',
    ],
  };

  final Map<String, List<String>> _panchayats = {
    'Malappuram': [
      'Thirurangadi Panchayat',
      'Angadipuram Panchayat',
      'Mankada Panchayat',
      'Karuvarakundu Panchayat',
      'Tirur Panchayat',
      'Tanur Panchayat',
    ],
    'Kozhikode': [
      'Beypore Panchayat',
      'Feroke Panchayat',
      'Chelannur Panchayat',
      'Kakkodi Panchayat',
    ],
    'Palakkad': [
      'Palakkad Panchayat',
      'Malampuzha Panchayat',
      'Kuzhalmannam Panchayat',
      'Alathur Panchayat',
    ],
    'Thrissur': [
      'Ollur Panchayat',
      'Wadakkanchery Panchayat',
      'Anthikkad Panchayat',
      'Mala Panchayat',
    ],
  };

  List<String> get _currentLocalBodies {
    final map = _localBodyType == 'Municipality'
        ? _municipalities
        : _panchayats;
    return map[_selectedDistrict] ?? [];
  }

  List<String> _professionCategories = [];

  static const int _maxProfessions = 4;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _loadCategories();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  // ── Validators ────────────────────────────────────────────────

  String? _validatePhone(String v) {
    final digits = v.trim().replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return 'Phone number cannot be empty';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  String? _validateWhatsapp(String v) {
    if (v.trim().isEmpty) return null; // optional
    final digits = v.trim().replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid 10-digit WhatsApp number';
    }
    return null;
  }

  bool _validateAll() {
    final pErr = _validatePhone(_phoneController.text);
    final wErr = _validateWhatsapp(_whatsappController.text);
    final lErr = _selectedLocalBody == null || _selectedLocalBody!.isEmpty
        ? 'Please select your ${_localBodyType.toLowerCase()}'
        : null;
    final prErr = _selectedProfessions.isEmpty
        ? 'Select at least 1 service (max $_maxProfessions)'
        : null;

    setState(() {
      _phoneError = pErr;
      _whatsappError = wErr;
      _localBodyError = lErr;
      _professionError = prErr;
    });
    return pErr == null && wErr == null && lErr == null && prErr == null;
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('job_categories')
        .orderBy('name')
        .get();

    setState(() {
      _professionCategories = snapshot.docs
          .map((e) => e['name'].toString())
          .toList();
    });
  }
  // ── Save ──────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    if (!_validateAll()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final phone = _phoneController.text.trim();
      final whatsapp = _sameAsPhone
          ? phone
          : _whatsappController.text.trim().isEmpty
          ? phone
          : _whatsappController.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'phone': phone,
        'whatsapp': whatsapp,
        'district': _selectedDistrict,
        'local_body_type': _localBodyType,
        'local_body': _selectedLocalBody ?? '',
        'professions': _selectedProfessions,
        'role': 'public',
        'isProfileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final oldJobs = await FirebaseFirestore.instance
          .collection('jobs')
          .where('uid', isEqualTo: user.uid)
          .get();

      for (var doc in oldJobs.docs) {
        await doc.reference.delete();
      }

      for (String profession in _selectedProfessions) {
        await FirebaseFirestore.instance.collection('jobs').add({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': phone,
          'profession': profession,
          'district': _selectedDistrict,
          'panchayat': _selectedLocalBody ?? '',
          'isApproved': false,
          'isActive': true,
          'createdAt': Timestamp.now(),
        });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHome()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: Colors.red.shade500,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildProgressHeader(),
                      const SizedBox(height: 24),
                      _buildSection(
                        icon: Icons.phone_rounded,
                        title: 'Contact Details',
                        child: _buildContactSection(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        icon: Icons.location_on_rounded,
                        title: 'Location',
                        child: _buildLocationSection(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        icon: Icons.work_rounded,
                        title: 'Your Services',
                        child: _buildServicesSection(),
                      ),
                      const SizedBox(height: 28),
                      _buildSaveButton(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.location_city_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'Gramika',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade500, Colors.deepOrange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.badge_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Help your community discover you',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Step 2 of 3',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: Colors.orange.shade600, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }

  // ── Contact section ───────────────────────────────────────────

  Widget _buildContactSection() {
    return Column(
      children: [
        // Phone
        _fieldLabel('Phone Number *'),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _phoneController,
          hint: 'e.g. 9876543210',
          icon: Icons.phone_rounded,
          error: _phoneError,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (v) {
            if (_phoneError != null) {
              setState(() => _phoneError = _validatePhone(v));
            }
            if (_sameAsPhone) {
              _whatsappController.text = v;
            }
          },
        ),
        if (_phoneError != null) _inlineError(_phoneError!),

        const SizedBox(height: 16),

        // WhatsApp
        _fieldLabel('WhatsApp Number'),
        const SizedBox(height: 6),

        // Same as phone toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _sameAsPhone = !_sameAsPhone;
              if (_sameAsPhone) {
                _whatsappController.text = _phoneController.text;
              } else {
                _whatsappController.clear();
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _sameAsPhone ? Colors.green.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _sameAsPhone
                    ? Colors.green.shade300
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _sameAsPhone ? Colors.green.shade500 : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _sameAsPhone
                          ? Colors.green.shade500
                          : Colors.grey.shade400,
                    ),
                  ),
                  child: _sameAsPhone
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Same as phone number',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _sameAsPhone
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),

        _buildInputField(
          controller: _whatsappController,
          hint: 'e.g. 9876543210',
          icon: Icons.chat_rounded,
          error: _whatsappError,
          enabled: !_sameAsPhone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (v) {
            if (_whatsappError != null) {
              setState(() => _whatsappError = _validateWhatsapp(v));
            }
          },
        ),
        if (_whatsappError != null) _inlineError(_whatsappError!),

        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 5),
            Text(
              'WhatsApp number is optional',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }

  // ── Location section ──────────────────────────────────────────

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // District
        _fieldLabel('District *'),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          value: _selectedDistrict,
          hint: 'Select district',
          icon: Icons.map_rounded,
          items: _districts,
          itemLabel: (d) => d,
          onChanged: (v) {
            setState(() {
              _selectedDistrict = v!;
              _selectedLocalBody = null;
            });
          },
        ),

        const SizedBox(height: 18),

        // Local body type toggle
        _fieldLabel('Local Body Type *'),
        const SizedBox(height: 10),
        Row(
          children: ['Municipality', 'Panchayat'].map((type) {
            final sel = _localBodyType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _localBodyType = type;
                  _selectedLocalBody = null;
                  _localBodyError = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(
                    right: type == 'Municipality' ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? Colors.orange.shade500 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel
                          ? Colors.orange.shade500
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type == 'Municipality'
                            ? Icons.location_city_rounded
                            : Icons.grass_rounded,
                        size: 16,
                        color: sel ? Colors.white : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Local body dropdown
        _fieldLabel('$_localBodyType *'),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          value: _selectedLocalBody,
          hint: 'Select $_localBodyType',
          icon: Icons.location_on_rounded,
          items: _currentLocalBodies,
          itemLabel: (d) => d,
          onChanged: (v) => setState(() {
            _selectedLocalBody = v;
            _localBodyError = null;
          }),
        ),
        if (_localBodyError != null) _inlineError(_localBodyError!),
      ],
    );
  }

  // ── Services section ──────────────────────────────────────────

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select up to $_maxProfessions services',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedProfessions.length} / $_maxProfessions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _professionCategories.map((profession) {
            final isSelected = _selectedProfessions.contains(profession);

            final isDisabled =
                !isSelected && _selectedProfessions.length >= _maxProfessions;

            return FilterChip(
              label: Text(profession),
              selected: isSelected,
              onSelected: isDisabled
                  ? null
                  : (value) {
                      setState(() {
                        if (value) {
                          _selectedProfessions.add(profession);
                        } else {
                          _selectedProfessions.remove(profession);
                        }
                      });
                    },
            );
          }).toList(),
        ),
      ],
    );
  }
  // ── Save button ───────────────────────────────────────────────

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _saveProfile,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade500, Colors.deepOrange.shade500],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Save Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Shared input widgets ──────────────────────────────────────

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    ),
  );

  Widget _inlineError(String msg) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 13, color: Colors.red.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(fontSize: 12, color: Colors.red.shade600),
          ),
        ),
      ],
    ),
  );

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? error,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    final hasErr = error != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: !enabled
            ? Colors.grey.shade100
            : hasErr
            ? Colors.red.shade50
            : const Color(0xFFF8F8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasErr
              ? Colors.red.shade300
              : !enabled
              ? Colors.grey.shade200
              : const Color(0xFFE0DDD7),
          width: 1.4,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14.5,
          color: enabled ? const Color(0xFF1A1A1A) : Colors.grey.shade400,
        ),
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
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DDD7), width: 1.4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
