import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_category_page.dart';
import '/screens/location/location_picker_page.dart';

class AddDirectoryPage extends StatefulWidget {
  final String? preselectedCategoryId;
  final bool isSuperAdmin;
  final String? directoryId;
  final Map<String, dynamic>? existingData;

  const AddDirectoryPage({
    super.key,
    this.preselectedCategoryId,
    this.isSuperAdmin = false,
    this.directoryId,
    this.existingData,
  });

  @override
  State<AddDirectoryPage> createState() => _AddDirectoryPageState();
}

class _AddDirectoryPageState extends State<AddDirectoryPage> {
  // ── Controllers ───────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _tagsController = TextEditingController();
  List<TextEditingController> _phoneControllers = [TextEditingController()];

  // ── State ─────────────────────────────────────────────────────
  String? _selectedCategoryId;
  String? _selectedDistrict;
  String? _selectedPanchayat;
  bool _isActive = true;
  bool _isSaving = false;
  Uint8List? _selectedImage;
  double? _latitude;
  double? _longitude;

  static const _orange = Color(0xFFFF6B00);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _bg = Color(0xFFF5F4F0);

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

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.preselectedCategoryId;
    final d = widget.existingData;
    if (d != null) {
      _nameController.text = d['name'] ?? '';
      _emailController.text = d['email'] ?? '';
      _websiteController.text = d['website'] ?? '';
      _facebookController.text = d['facebook'] ?? '';
      _instagramController.text = d['instagram'] ?? '';
      _whatsappController.text = d['whatsapp'] ?? '';
      _youtubeController.text = d['youtube'] ?? '';
      _tagsController.text = (d['tags'] as List<dynamic>? ?? []).join(', ');
      _selectedDistrict = d['district'];
      _selectedPanchayat = d['panchayat'];
      _isActive = d['isActive'] ?? true;
      if (d['phones'] != null) {
        _phoneControllers = (d['phones'] as List<dynamic>)
            .map((p) => TextEditingController(text: p.toString()))
            .toList();
        if (_phoneControllers.isEmpty) {
          _phoneControllers = [TextEditingController()];
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _tagsController.dispose();
    for (final c in _phoneControllers) c.dispose();
    super.dispose();
  }

  // ── Image picker ──────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _selectedImage = bytes);
  }

  // ── Save ──────────────────────────────────────────────────────
  Future<void> _saveDirectory() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter a directory name', isError: true);
      return;
    }
    if (_selectedCategoryId == null) {
      _showSnack('Please select a category', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final categoryDoc = await FirebaseFirestore.instance
          .collection('directory_categories')
          .doc(_selectedCategoryId)
          .get();
      if (!categoryDoc.exists || categoryDoc.data() == null) {
        _showSnack('Selected category not found', isError: true);
        setState(() => _isSaving = false);
        return;
      }

      final categoryData = categoryDoc.data()!;
      if (!widget.isSuperAdmin) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        final userData = userDoc.data() as Map<String, dynamic>? ?? {};

        _selectedPanchayat = userData['panchayat'];
        _selectedDistrict = userData['district'];
      }
      final data = {
        'name': _nameController.text.trim(),
        'categoryId': _selectedCategoryId,
        'category': categoryData['name'],
        'district': _selectedDistrict,
        'panchayat': _selectedPanchayat,
        'panchayatId': '',
        'location': _latitude != null && _longitude != null
            ? GeoPoint(_latitude!, _longitude!)
            : null,
        'phones': _phoneControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'whatsapp': _whatsappController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'youtube': _youtubeController.text.trim(),
        'tags': _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'imageUrl': _selectedImage != null
            ? base64Encode(_selectedImage!)
            : (widget.existingData?['imageUrl'] ?? ''),
        'isActive': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.directoryId == null) {
        await FirebaseFirestore.instance.collection('directories').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('directories')
            .doc(widget.directoryId)
            .update(data);
      }

      if (!mounted) return;
      _showSnack(
        widget.directoryId == null
            ? 'Directory added successfully'
            : 'Directory updated successfully',
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade500 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.directoryId != null;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isEdit),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Basic Info ──
                    _section(
                      icon: Icons.info_rounded,
                      title: 'Basic Information',
                      child: _buildBasicInfo(),
                    ),
                    const SizedBox(height: 14),

                    // ── Location ──
                    _section(
                      icon: Icons.location_on_rounded,
                      title: 'Location',
                      child: _buildLocationSection(),
                    ),
                    const SizedBox(height: 14),

                    // ── Contact ──
                    _section(
                      icon: Icons.contact_phone_rounded,
                      title: 'Contact Details',
                      child: _buildContactSection(),
                    ),
                    const SizedBox(height: 14),

                    // ── Social ──
                    _section(
                      icon: Icons.share_rounded,
                      title: 'Social & Web',
                      child: _buildSocialSection(),
                    ),
                    const SizedBox(height: 14),

                    // ── Image ──
                    _section(
                      icon: Icons.image_rounded,
                      title: 'Directory Image',
                      child: _buildImageSection(),
                    ),
                    const SizedBox(height: 14),

                    // ── Settings ──
                    _section(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      child: _buildSettingsSection(),
                    ),
                    const SizedBox(height: 28),

                    _buildSaveButton(isEdit),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(bool isEdit) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _orangeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: _orange,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_orange, Color(0xFFFF4500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Directory' : 'Add Directory',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  widget.isSuperAdmin ? 'Super Admin' : 'Admin',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Active badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isActive ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isActive
                        ? Colors.green.shade500
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isActive
                        ? Colors.green.shade700
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────
  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _orangeLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _orange, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  // ── Basic info ────────────────────────────────────────────────
  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Directory Name *'),
        const SizedBox(height: 6),
        _input(
          controller: _nameController,
          hint: 'e.g. ABC Hospital',
          icon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),

        _label('Category *'),
        const SizedBox(height: 6),

        // ── CATEGORY DROPDOWN — super admin gets + button ──────
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('directory_categories')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: _orange,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            final categoryDropdown = Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0DDD7), width: 1.4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  hint: Text(
                    'Select category',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF1A1A1A),
                  ),
                  items: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['name']),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
              ),
            );

            // Super admin: dropdown + add category button
            if (widget.isSuperAdmin) {
              return Row(
                children: [
                  Expanded(child: categoryDropdown),
                  const SizedBox(width: 10),
                  // ── ADD CATEGORY BUTTON (super admin only) ──
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddCategoryPage(),
                        ),
                      );
                      if (result != null) {
                        setState(
                          () => _selectedCategoryId = result['categoryId'],
                        );
                      }
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_orange, Color(0xFFFF4500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _orange.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              );
            }

            // Admin: dropdown only
            return categoryDropdown;
          },
        ),

        const SizedBox(height: 16),

        _label('Tags'),
        const SizedBox(height: 6),
        _input(
          controller: _tagsController,
          hint: 'hospital, emergency, 24x7  (comma separated)',
          icon: Icons.tag_rounded,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 12,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              'Separate tags with commas',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }

  // ── Location ──────────────────────────────────────────────────
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('District'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0DDD7), width: 1.4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.map_rounded,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              hint: Text(
                'Select district',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A)),
              items: _districts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedDistrict = v;
                _selectedPanchayat = null;
              }),
            ),
          ),
        ),

        if (_selectedDistrict != null) ...[
          const SizedBox(height: 14),
          _label('Panchayat'),
          const SizedBox(height: 6),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('panchayats')
                .where('district', isEqualTo: _selectedDistrict)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE0DDD7),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading…'
                            : 'No panchayats for $_selectedDistrict',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0DDD7),
                    width: 1.4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPanchayat,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.account_balance_rounded,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    hint: Text(
                      'Select panchayat',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFF1A1A1A),
                    ),
                    items: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: data['name'],
                        child: Text(data['name']),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedPanchayat = v),
                  ),
                ),
              );
            },
          ),
        ],

        const SizedBox(height: 16),

        // Map picker button
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationPickerPage()),
            );
            if (result != null) {
              setState(() {
                _latitude = result['lat'];
                _longitude = result['lng'];
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: _latitude != null ? Colors.green.shade50 : _orangeLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _latitude != null
                    ? Colors.green.shade300
                    : Colors.orange.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _latitude != null
                      ? Icons.location_on_rounded
                      : Icons.add_location_alt_rounded,
                  color: _latitude != null ? Colors.green.shade600 : _orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _latitude != null
                      ? 'Location set  (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                      : 'Pick Location on Map',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _latitude != null ? Colors.green.shade700 : _orange,
                  ),
                ),
                if (_latitude != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _latitude = _longitude = null),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Contact ───────────────────────────────────────────────────
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Phone Numbers'),
        const SizedBox(height: 8),
        ..._phoneControllers.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: _input(
                    controller: entry.value,
                    hint: 'Phone ${entry.key + 1}',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                ),
                if (_phoneControllers.length > 1) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _phoneControllers[entry.key].dispose();
                        _phoneControllers.removeAt(entry.key);
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.remove_rounded,
                        color: Colors.red.shade400,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        GestureDetector(
          onTap: () =>
              setState(() => _phoneControllers.add(TextEditingController())),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _orangeLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_rounded, color: _orange, size: 18),
                SizedBox(width: 6),
                Text(
                  'Add Phone Number',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _orange,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        _label('WhatsApp Number'),
        const SizedBox(height: 6),
        _input(
          controller: _whatsappController,
          hint: 'WhatsApp number',
          icon: Icons.chat_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),

        const SizedBox(height: 16),
        _label('Email'),
        const SizedBox(height: 6),
        _input(
          controller: _emailController,
          hint: 'email@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  // ── Social & Web ──────────────────────────────────────────────
  Widget _buildSocialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Website'),
        const SizedBox(height: 6),
        _input(
          controller: _websiteController,
          hint: 'https://example.com',
          icon: Icons.language_rounded,
          keyboardType: TextInputType.url,
        ),

        const SizedBox(height: 14),
        _label('Facebook'),
        const SizedBox(height: 6),
        _input(
          controller: _facebookController,
          hint: 'Facebook page URL',
          icon: Icons.facebook_rounded,
        ),

        const SizedBox(height: 14),
        _label('Instagram'),
        const SizedBox(height: 6),
        _input(
          controller: _instagramController,
          hint: 'Instagram profile URL',
          icon: Icons.camera_alt_rounded,
        ),

        const SizedBox(height: 14),
        _label('YouTube'),
        const SizedBox(height: 6),
        _input(
          controller: _youtubeController,
          hint: 'YouTube channel URL',
          icon: Icons.smart_display_rounded,
        ),
      ],
    );
  }

  // ── Image ─────────────────────────────────────────────────────
  Widget _buildImageSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: _selectedImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _selectedImage!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: _orangeLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        color: Colors.orange.shade400,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload image',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'JPG, PNG supported',
                        style: TextStyle(
                          color: Colors.orange.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ── Settings ──────────────────────────────────────────────────
  Widget _buildSettingsSection() {
    return GestureDetector(
      onTap: () => setState(() => _isActive = !_isActive),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isActive ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isActive ? Colors.green.shade200 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _isActive ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isActive
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: _isActive ? Colors.green.shade600 : Colors.grey.shade500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isActive ? 'Listing is Active' : 'Listing is Inactive',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    _isActive
                        ? 'Visible to all users in the directory'
                        : 'Hidden from public directory',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _isActive
                          ? Colors.green.shade500
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeColor: Colors.green.shade500,
              activeTrackColor: Colors.green.shade100,
            ),
          ],
        ),
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────
  Widget _buildSaveButton(bool isEdit) {
    return GestureDetector(
      onTap: _isSaving ? null : _saveDirectory,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_orange, Color(0xFFFF4500)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _orange.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEdit
                          ? Icons.update_rounded
                          : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Update Directory' : 'Save Directory',
                      style: const TextStyle(
                        fontSize: 15,
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

  // ── Shared input widget ───────────────────────────────────────
  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: Color(0xFF333333),
    ),
  );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DDD7), width: 1.4),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
