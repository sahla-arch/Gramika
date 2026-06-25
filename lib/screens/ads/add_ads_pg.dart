import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AddAdsPage extends StatefulWidget {
  final String? adId;
  final Map<String, dynamic>? existingData;

  const AddAdsPage({super.key, this.adId, this.existingData});

  @override
  State<AddAdsPage> createState() => _AddAdsPageState();
}

class _AddAdsPageState extends State<AddAdsPage> {
  final titleController = TextEditingController();
  final businessNameController = TextEditingController();
  final phoneController = TextEditingController();
  final websiteController = TextEditingController();
  final nameController = TextEditingController();

  bool isActive = true;
  bool _isSaving = false;
  Uint8List? selectedImage;

  // For edit mode: existing network/base64 image
  String? existingImgUrl;

  DateTime validFrom = DateTime.now();
  DateTime validTo = DateTime.now().add(const Duration(days: 30));

  bool get isEditMode => widget.adId != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode && widget.existingData != null) {
      final d = widget.existingData!;
      titleController.text = d['title'] ?? '';
      businessNameController.text = d['bussinessName'] ?? '';
      phoneController.text = d['phone'] ?? '';
      websiteController.text = d['websiteUrl'] ?? '';
      nameController.text = d['name'] ?? '';
      isActive = d['isActive'] ?? true;
      existingImgUrl = d['imgUrl'] ?? '';

      if (d['validFrom'] != null) {
        validFrom = (d['validFrom'] as dynamic).toDate();
      }
      if (d['validTo'] != null) {
        validTo = (d['validTo'] as dynamic).toDate();
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    businessNameController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    nameController.dispose();
    super.dispose();
  }

  // ── Image picker (device only, no URL) ──────────────────────────────
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      selectedImage = bytes;
      existingImgUrl = null; // clear old URL if replacing
    });
  }

  Future<String> uploadToCloudinary(Uint8List imageBytes) async {
    const cloudName = 'dj0ykuyyv';
    const uploadPreset = 'ads_images';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: 'ad.jpg'),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final data = jsonDecode(await response.stream.bytesToString());

      return data['secure_url'];
    }

    throw Exception('Cloudinary upload failed');
  }

  // ── Date picker helpers ─────────────────────────────────────────────
  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? validFrom : validTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFE8651A),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom)
        validFrom = picked;
      else
        validTo = picked;
    });
  }

  // ── Validation ──────────────────────────────────────────────────────
  bool _validate() {
    if (titleController.text.trim().isEmpty) {
      _showSnack('Please enter a title', isError: true);
      return false;
    }
    if (businessNameController.text.trim().isEmpty) {
      _showSnack('Please enter a business name', isError: true);
      return false;
    }
    if (selectedImage == null &&
        (existingImgUrl == null || existingImgUrl!.isEmpty)) {
      _showSnack('Please upload an ad image', isError: true);
      return false;
    }
    return true;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Save / Update ───────────────────────────────────────────────────
  Future<void> saveAds() async {
    if (!_validate()) return;

    setState(() => _isSaving = true);

    try {
      String imgValue = existingImgUrl ?? '';

      if (selectedImage != null) {
        imgValue = await uploadToCloudinary(selectedImage!);
      }

      final payload = {
        'title': titleController.text.trim(),
        'bussinessName': businessNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'websiteUrl': websiteController.text.trim(),
        'name': nameController.text.trim(),
        'imgUrl': imgValue,
        'isActive': isActive,
        'createdAt': isEditMode
            ? widget.existingData!['createdAt']
            : Timestamp.now(),
        'validFrom': Timestamp.fromDate(validFrom),
        'validTo': Timestamp.fromDate(validTo),
        'createdBy': 'Super Admin',
        'youtubeLinks': [],
      };

      if (isEditMode) {
        await FirebaseFirestore.instance
            .collection('ads')
            .doc(widget.adId)
            .update(payload);
      } else {
        await FirebaseFirestore.instance.collection('ads').add(payload);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('ADS SAVE ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ── Formatters ──────────────────────────────────────────────────────
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1008),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditMode ? 'Edit Ad' : 'Add New Ad',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      body: Column(
        children: [
          Container(height: 4, color: const Color(0xFFE8651A)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image upload area ──────────────────────────────
                  _SectionLabel(label: 'AD IMAGE'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              selectedImage != null ||
                                  (existingImgUrl != null &&
                                      existingImgUrl!.isNotEmpty)
                              ? const Color(0xFFE8651A)
                              : const Color(0xFFE4E7EC),
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
                      child: _buildImagePreview(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Replace / Upload button
                  Center(
                    child: TextButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(
                        Icons.upload_rounded,
                        color: Color(0xFFE8651A),
                        size: 18,
                      ),
                      label: Text(
                        selectedImage != null ||
                                (existingImgUrl != null &&
                                    existingImgUrl!.isNotEmpty)
                            ? 'Replace Image'
                            : 'Upload from Device',
                        style: const TextStyle(
                          color: Color(0xFFE8651A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Ad details ─────────────────────────────────────
                  _SectionLabel(label: 'AD DETAILS'),
                  const SizedBox(height: 8),
                  _WhiteCard(
                    child: Column(
                      children: [
                        _FieldTile(
                          icon: Icons.campaign_rounded,
                          hint: 'Ad title  (e.g. 50% discount on dresses)',
                          controller: titleController,
                        ),
                        _FieldDivider(),
                        _FieldTile(
                          icon: Icons.badge_rounded,
                          hint: 'Internal name  (e.g. ads1)',
                          controller: nameController,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Business info ──────────────────────────────────
                  _SectionLabel(label: 'BUSINESS INFO'),
                  const SizedBox(height: 8),
                  _WhiteCard(
                    child: Column(
                      children: [
                        _FieldTile(
                          icon: Icons.storefront_rounded,
                          hint: 'Business name',
                          controller: businessNameController,
                        ),
                        _FieldDivider(),
                        _FieldTile(
                          icon: Icons.phone_rounded,
                          hint: 'Phone number',
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        _FieldDivider(),
                        _FieldTile(
                          icon: Icons.language_rounded,
                          hint: 'Website URL  (optional)',
                          controller: websiteController,
                          keyboardType: TextInputType.url,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Validity period ────────────────────────────────
                  _SectionLabel(label: 'VALIDITY PERIOD'),
                  const SizedBox(height: 8),
                  _WhiteCard(
                    child: Column(
                      children: [
                        _DateTile(
                          icon: Icons.calendar_today_rounded,
                          label: 'Valid From',
                          value: _fmtDate(validFrom),
                          onTap: () => _pickDate(isFrom: true),
                        ),
                        _FieldDivider(),
                        _DateTile(
                          icon: Icons.event_rounded,
                          label: 'Valid To',
                          value: _fmtDate(validTo),
                          onTap: () => _pickDate(isFrom: false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Publish toggle ─────────────────────────────────
                  _SectionLabel(label: 'VISIBILITY'),
                  const SizedBox(height: 8),
                  _WhiteCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        secondary: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                (isActive
                                        ? const Color(0xFFE8651A)
                                        : const Color(0xFF8A94A6))
                                    .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isActive
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: isActive
                                ? const Color(0xFFE8651A)
                                : const Color(0xFF8A94A6),
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Publish Ad',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1008),
                          ),
                        ),
                        subtitle: Text(
                          isActive ? 'Visible to users' : 'Hidden from users',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                        value: isActive,
                        activeColor: const Color(0xFFE8651A),
                        onChanged: (v) => setState(() => isActive = v),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Save button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : saveAds,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8651A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFFE8651A,
                        ).withOpacity(0.5),
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
                          : Text(
                              isEditMode ? 'Update Ad' : 'Save Ad',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
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

  // ── Image preview widget ─────────────────────────────────────────────
  Widget _buildImagePreview() {
    // New image picked from device
    if (selectedImage != null) {
      return Image.memory(
        selectedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 190,
      );
    }

    // Existing URL from Firestore (edit mode)
    if (existingImgUrl != null && existingImgUrl!.isNotEmpty) {
      if (existingImgUrl!.startsWith('http')) {
        return Image.network(
          existingImgUrl!,
          headers: const {'Cache-Control': 'no-cache'},
          gaplessPlayback: false,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 190,
          // No cache — fresh load every time
          errorBuilder: (_, __, ___) => _uploadPlaceholder(),
        );
      }
      // base64 stored image
      try {
        return Image.memory(
          base64Decode(existingImgUrl!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 190,
        );
      } catch (_) {
        return _uploadPlaceholder();
      }
    }

    return _uploadPlaceholder();
  }

  Widget _uploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFE8651A).withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.add_photo_alternate_rounded,
            color: Color(0xFFE8651A),
            size: 30,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tap to upload ad image',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8A94A6),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'JPG, PNG from your device',
          style: TextStyle(fontSize: 11, color: Color(0xFFB0B7C3)),
        ),
      ],
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF8A94A6),
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

class _FieldTile extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _FieldTile({
    required this.icon,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE8651A).withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFFE8651A), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1C1008),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF8A94A6),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8651A).withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFFE8651A), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A94A6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1C1008),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFD0D5DD),
            size: 20,
          ),
        ],
      ),
    ),
  );
}

class _FieldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 64,
    endIndent: 0,
    color: Color(0xFFF0F1F5),
  );
}
