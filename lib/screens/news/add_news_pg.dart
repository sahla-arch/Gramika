import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Tag metadata ────────────────────────────────────────────────────────────
const Map<String, Color> _tagColor = {
  'General': Color(0xFF546E7A),
  'Government': Color(0xFF1E88E5),
  'Education': Color(0xFF43A047),
  'Health': Color(0xFFE53935),
};

// ── Theme constants ─────────────────────────────────────────────────────────
const _kDark = Color(0xFF1C1008);
const _kOrange = Color(0xFFE8651A);
const _kBg = Color(0xFFF5F6FA);
const _kCard = Colors.white;
const _kMuted = Color(0xFF8A94A6);
const _kBorder = Color(0xFFE4E7EC);

// ═══════════════════════════════════════════════════════════════════════════
//  AddNewsPage
// ═══════════════════════════════════════════════════════════════════════════
class AddNewsPage extends StatefulWidget {
  const AddNewsPage({super.key});

  @override
  State<AddNewsPage> createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _shortCtrl = TextEditingController();
  final _fullCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();

  String _tag = 'General';
  bool _isActive = true;
  bool _isSaving = false;
  Uint8List? _selectedImage;

  static const _tags = ['General', 'Government', 'Education', 'Health'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _shortCtrl.dispose();
    _fullCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _selectedImage = bytes);
  }

  void _removeImage() => setState(() => _selectedImage = null);

  // ── Cloudinary upload ───────────────────────────────────────────────────
  Future<String> _uploadToCloudinary(Uint8List bytes) async {
    const cloudName = 'dj0ykuyyv';
    const uploadPreset = 'ads_images';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'news.jpg'),
      );

    final res = await req.send();
    if (res.statusCode == 200) {
      final data = jsonDecode(await res.stream.bytesToString());
      return data['secure_url'] as String;
    }
    throw Exception('Image upload failed (${res.statusCode})');
  }

  // ── Snackbar ────────────────────────────────────────────────────────────
  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────
  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String coverImageUrl = '';
      if (_selectedImage != null) {
        coverImageUrl = await _uploadToCloudinary(_selectedImage!);
      }

      await FirebaseFirestore.instance.collection('news').add({
        'title': _titleCtrl.text.trim(),
        'shortDescription': _shortCtrl.text.trim(),
        'fullDescription': _fullCtrl.text.trim(),
        'coverImage': coverImageUrl,
        'tag': _tag,
        'source': _sourceCtrl.text.trim(),
        'isActive': _isActive,
        'createdAt': Timestamp.now(),
        'validFrom': Timestamp.now(),
        'validTo': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'createdBy': 'Admin',
        'images': [],
        'youtubeLinks': [],
      });

      if (!mounted) return;
      _snack('News published successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,

      appBar: AppBar(
        backgroundColor: _kDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add News',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: _kOrange),
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover image ────────────────────────────────────────
              const _SectionLabel(label: 'COVER IMAGE'),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selectedImage != null ? _kOrange : _kBorder,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_selectedImage!, fit: BoxFit.cover),
                            // Remove button
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            // Replace label
                            Positioned(
                              bottom: 10,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.greenAccent,
                                      size: 13,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Cover added',
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
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _kOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: _kOrange,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap to upload cover image',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'JPG, PNG · Max 5 MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB0B7C3),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(
                      Icons.swap_horiz_rounded,
                      color: _kOrange,
                      size: 16,
                    ),
                    label: const Text(
                      'Replace Image',
                      style: TextStyle(
                        color: _kOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── News details ───────────────────────────────────────
              const _SectionLabel(label: 'NEWS DETAILS'),
              const SizedBox(height: 10),

              _WhiteCard(
                child: Column(
                  children: [
                    _ValidatedField(
                      icon: Icons.newspaper_rounded,
                      hint: 'News title',
                      controller: _titleCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    const _FieldDivider(),
                    _ValidatedField(
                      icon: Icons.short_text_rounded,
                      hint: 'Short description (shown in preview)',
                      controller: _shortCtrl,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Short description is required'
                          : null,
                    ),
                    const _FieldDivider(),
                    _ValidatedField(
                      icon: Icons.article_rounded,
                      hint: 'Full description',
                      controller: _fullCtrl,
                      maxLines: 6,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Full description is required'
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Source & tag ───────────────────────────────────────
              const _SectionLabel(label: 'SOURCE & TAG'),
              const SizedBox(height: 10),

              _WhiteCard(
                child: Column(
                  children: [
                    // Source field (optional)
                    _ValidatedField(
                      icon: Icons.link_rounded,
                      hint: 'Source  (e.g. The Hindu, PTI) — optional',
                      controller: _sourceCtrl,
                    ),
                    const _FieldDivider(),

                    // Tag selector
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _kOrange.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.label_rounded,
                              color: _kOrange,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _tags.map((t) {
                                final selected = _tag == t;
                                final tColor = _tagColor[t] ?? _kOrange;
                                return GestureDetector(
                                  onTap: () => setState(() => _tag = t),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? tColor
                                          : tColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selected
                                            ? tColor
                                            : tColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      t,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: selected ? Colors.white : tColor,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Visibility ─────────────────────────────────────────
              const _SectionLabel(label: 'VISIBILITY'),
              const SizedBox(height: 10),

              _WhiteCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (_isActive ? _kOrange : _kMuted).withOpacity(
                          0.12,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isActive
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: _isActive ? _kOrange : _kMuted,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Publish News',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kDark,
                      ),
                    ),
                    subtitle: Text(
                      _isActive ? 'Visible to users' : 'Hidden from users',
                      style: const TextStyle(fontSize: 12, color: _kMuted),
                    ),
                    value: _isActive,
                    activeColor: _kOrange,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Save button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveNews,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _kOrange.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Publish News',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable widgets
// ═══════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _kMuted,
      letterSpacing: 1.2,
    ),
  );
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _ValidatedField extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ValidatedField({
    required this.icon,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kOrange.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _kOrange, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
              fontSize: 14,
              color: _kDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _kMuted, fontSize: 13),
              border: InputBorder.none,
              errorStyle: const TextStyle(fontSize: 11, height: 0.8),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 64,
    endIndent: 0,
    color: Color(0xFFF0F1F5),
  );
}
