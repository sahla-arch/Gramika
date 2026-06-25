import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ── Theme constants ─────────────────────────────────────────────────────────
const _kAccent = Color(0xFFE8651A);
const _kDark = Color(0xFF1C1008);
const _kBg = Color(0xFFF5F6FA);
const _kHint = Color(0xFF8A94A6);
const _kBorder = Color(0xFFE4E7EC);
const _kDivider = Color(0xFFF0F1F5);

// ── Tag colours (matches add_news_page) ─────────────────────────────────────
const Map<String, Color> _tagColor = {
  'General': Color(0xFF546E7A),
  'Government': Color(0xFF1E88E5),
  'Education': Color(0xFF43A047),
  'Health': Color(0xFFE53935),
};

// ═══════════════════════════════════════════════════════════════════════════
//  EditNewsPage
// ═══════════════════════════════════════════════════════════════════════════
class EditNewsPage extends StatefulWidget {
  final String newsId;
  final Map<String, dynamic> news;

  const EditNewsPage({super.key, required this.newsId, required this.news});

  @override
  State<EditNewsPage> createState() => _EditNewsPageState();
}

class _EditNewsPageState extends State<EditNewsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _shortCtrl = TextEditingController();
  final _fullCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();

  String _tag = 'General';
  Uint8List? _selectedImage;
  String _existingImage = '';
  bool _removeExisting = false;
  bool _isSaving = false;
  bool _isActive = true;

  static const _tags = ['General', 'Government', 'Education', 'Health'];

  // ── Init ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final d = widget.news;
    _titleCtrl.text = d['title'] ?? '';
    _shortCtrl.text = d['shortDescription'] ?? '';
    _fullCtrl.text = d['fullDescription'] ?? '';
    _sourceCtrl.text = d['source'] ?? '';
    _existingImage = d['coverImage'] ?? '';
    _tag = d['tag'] ?? 'General';
    _isActive = d['isActive'] ?? true;

    final yt = d['youtubeLinks'];
    if (yt is List && yt.isNotEmpty) {
      _youtubeCtrl.text = yt.first.toString();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _shortCtrl.dispose();
    _fullCtrl.dispose();
    _sourceCtrl.dispose();
    _youtubeCtrl.dispose();
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
    setState(() {
      _selectedImage = bytes;
      _removeExisting = false;
    });
  }

  void _clearImage() => setState(() {
    _selectedImage = null;
    _removeExisting = true;
  });

  // ── Snackbar ─────────────────────────────────────────────────────────────
  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
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
              Flexible(child: Text(msg)),
            ],
          ),
          backgroundColor: isError
              ? const Color(0xFFE53935)
              : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ── Save ─────────────────────────────────────────────────────────────────
  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Determine final cover image
      String coverImage = _existingImage;
      if (_removeExisting && _selectedImage == null) coverImage = '';

      await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.newsId)
          .update({
            'title': _titleCtrl.text.trim(),
            'shortDescription': _shortCtrl.text.trim(),
            'fullDescription': _fullCtrl.text.trim(),
            'coverImage': coverImage,
            'source': _sourceCtrl.text.trim(),
            'youtubeLinks': _youtubeCtrl.text.trim().isEmpty
                ? []
                : [_youtubeCtrl.text.trim()],
            'tag': _tag,
            'isActive': _isActive,
            'updatedAt': Timestamp.now(),
            'validFrom': Timestamp.now(),
            'validTo': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 30)),
            ),
            'createdBy': 'Admin',
          });

      _snack('News updated successfully!');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Failed to update: $e', isError: true);
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
          'Edit News',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: _kAccent),
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
              _buildImageSection(),

              const SizedBox(height: 24),

              // ── News details ───────────────────────────────────────
              const _SectionLabel(label: 'NEWS DETAILS'),
              const SizedBox(height: 10),
              _WhiteCard(
                child: Column(
                  children: [
                    _ValidatedField(
                      icon: Icons.title_rounded,
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
                      maxLines: 3,
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

              // ── Source & media ─────────────────────────────────────
              const _SectionLabel(label: 'SOURCE & MEDIA'),
              const SizedBox(height: 10),
              _WhiteCard(
                child: Column(
                  children: [
                    _ValidatedField(
                      icon: Icons.link_rounded,
                      hint: 'Source  (e.g. The Hindu, PTI) — optional',
                      controller: _sourceCtrl,
                    ),
                    const _FieldDivider(),
                    _ValidatedField(
                      icon: Icons.smart_display_rounded,
                      hint: 'YouTube link  (optional)',
                      controller: _youtubeCtrl,
                      keyboardType: TextInputType.url,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || !uri.hasScheme) {
                          return 'Enter a valid URL';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Tag selector ───────────────────────────────────────
              const _SectionLabel(label: 'CATEGORY TAG'),
              const SizedBox(height: 10),
              _WhiteCard(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _kAccent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.label_rounded,
                          color: _kAccent,
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
                            final tColor = _tagColor[t] ?? _kAccent;
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
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: tColor.withOpacity(0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selected) ...[
                                      const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 5),
                                    ],
                                    Text(
                                      t,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: selected ? Colors.white : tColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Visibility toggle ──────────────────────────────────
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
                        color: (_isActive ? _kAccent : _kHint).withOpacity(
                          0.12,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isActive
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: _isActive ? _kAccent : _kHint,
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
                      style: const TextStyle(fontSize: 12, color: _kHint),
                    ),
                    value: _isActive,
                    activeColor: _kAccent,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Update button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveNews,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _kAccent.withOpacity(0.5),
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
                            Icon(Icons.save_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Update News',
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

  // ── Image section ────────────────────────────────────────────────────────
  Widget _buildImageSection() {
    final hasNew = _selectedImage != null;
    final hasExisting = _existingImage.isNotEmpty && !_removeExisting;
    final hasAny = hasNew || hasExisting;

    return Column(
      children: [
        GestureDetector(
          onTap: _isSaving ? null : _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: hasAny ? _kAccent : _kBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImagePreview(hasNew, hasExisting),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _isSaving ? null : _pickImage,
              icon: Icon(
                hasAny ? Icons.swap_horiz_rounded : Icons.upload_rounded,
                color: _kAccent,
                size: 16,
              ),
              label: Text(
                hasAny ? 'Replace Image' : 'Upload from Device',
                style: const TextStyle(
                  color: _kAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (hasAny) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _isSaving ? null : _clearImage,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 16,
                ),
                label: const Text(
                  'Remove',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(bool hasNew, bool hasExisting) {
    if (hasNew) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_selectedImage!, fit: BoxFit.cover),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: _clearImage,
              child: Container(
                padding: const EdgeInsets.all(6),
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
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'New image selected',
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
      );
    }

    if (hasExisting) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _existingImage,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, prog) {
              if (prog == null) return child;
              return Container(
                color: Colors.orange.shade50,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: _kAccent,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => _imgPlaceholder(),
          ),
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    color: Colors.greenAccent,
                    size: 13,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Current cover',
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
      );
    }

    return _imgPlaceholder();
  }

  Widget _imgPlaceholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _kAccent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.add_photo_alternate_rounded,
          color: _kAccent,
          size: 30,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Tap to upload cover image',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _kHint,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'JPG, PNG · Max 5 MB',
        style: TextStyle(fontSize: 11, color: Color(0xFFB0B7C3)),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Shared widgets
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
      color: _kHint,
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
      color: Colors.white,
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
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _ValidatedField({
    required this.icon,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
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
              color: _kAccent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _kAccent, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              fontSize: 14,
              color: _kDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _kHint, fontSize: 13),
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
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 64, endIndent: 0, color: _kDivider);
}
