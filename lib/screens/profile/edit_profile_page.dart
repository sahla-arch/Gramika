import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();

  bool isLoading = true;
  bool _isSaving = false;

  List<String> selectedServices = [];

  final List<String> services = [
    'Common Citizen',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Mechanic',
    'Teacher',
    'Tutor',
    'Student',
    'Doctor',
    'Nurse',
    'Pharmacist',
    'Shop Owner',
    'Catering',
    'Event Organizer',
    'IT Services',
    'Driver',
    'Farmer',
    'Tailor',
    'Photographer',
    'Other',
  ];

  // ── Load user ────────────────────────────────────────────────────────
  Future<void> loadUser() async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        final data = result.docs.first.data();
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        whatsappController.text = data['whatsapp'] ?? '';
        selectedServices = List<String>.from(data['professions'] ?? []);
      }
    } catch (e) {
      debugPrint('EDIT PROFILE ERROR = $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    super.dispose();
  }

  // ── Save ─────────────────────────────────────────────────────────────
  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);

    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (result.docs.isEmpty) return;

      await result.docs.first.reference.update({
        'phone': phoneController.text.trim(),
        'whatsapp': whatsappController.text.trim(),
        'professions': selectedServices,
      });

      // Delete old job entries
      final oldJobs = await FirebaseFirestore.instance
          .collection('jobs')
          .where('uid', isEqualTo: user.uid)
          .get();
      for (final doc in oldJobs.docs) {
        await doc.reference.delete();
      }

      // Create updated job entries
      for (final profession in selectedServices) {
        await FirebaseFirestore.instance.collection('jobs').add({
          'uid': user.uid,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'profession': profession,
          'isApproved': true,
          'isActive': true,
          'createdAt': Timestamp.now(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('SAVE ERROR = $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save. Please try again.'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE8651A)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1008),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
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
                  // ── Personal info ──────────────────────────────────
                  _SectionLabel(label: 'PERSONAL INFO'),
                  const SizedBox(height: 8),
                  _WhiteCard(
                    child: Column(
                      children: [
                        // Name — read only
                        _FieldTile(
                          icon: Icons.person_rounded,
                          hint: 'Name',
                          controller: nameController,
                          readOnly: true,
                          readOnlyBadge: true,
                        ),
                        const _RowDivider(),
                        // Email — read only
                        _FieldTile(
                          icon: Icons.email_rounded,
                          hint: 'Email',
                          controller: emailController,
                          readOnly: true,
                          readOnlyBadge: true,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Contact info ───────────────────────────────────
                  _SectionLabel(label: 'CONTACT INFO'),
                  const SizedBox(height: 8),
                  _WhiteCard(
                    child: Column(
                      children: [
                        _FieldTile(
                          icon: Icons.phone_rounded,
                          hint: 'Phone Number',
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const _RowDivider(),
                        _FieldTile(
                          icon: Icons.chat_rounded,
                          hint: 'WhatsApp Number',
                          controller: whatsappController,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── My Services ────────────────────────────────────
                  Row(
                    children: [
                      _SectionLabel(label: 'MY SERVICES'),
                      const SizedBox(width: 8),
                      if (selectedServices.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8651A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${selectedServices.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select all that apply — these appear in job services',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 12),

                  _WhiteCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: services.map((service) {
                          final selected = selectedServices.contains(service);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selected
                                    ? selectedServices.remove(service)
                                    : selectedServices.add(service);
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFE8651A)
                                    : const Color(0xFFF5F6FA),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFE8651A)
                                      : const Color(0xFFE4E7EC),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selected) ...[
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    service,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF8A94A6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Save button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : saveProfile,
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
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
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
}

// ── Shared helpers ─────────────────────────────────────────────────────────

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
  final bool readOnly;
  final bool readOnlyBadge;
  final TextInputType keyboardType;

  const _FieldTile({
    required this.icon,
    required this.hint,
    required this.controller,
    this.readOnly = false,
    this.readOnlyBadge = false,
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
            color:
                (readOnly ? const Color(0xFF8A94A6) : const Color(0xFFE8651A))
                    .withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: readOnly ? const Color(0xFF8A94A6) : const Color(0xFFE8651A),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 14,
              color: readOnly
                  ? const Color(0xFF8A94A6)
                  : const Color(0xFF1C1008),
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
              suffixIcon: readOnlyBadge
                  ? Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8A94A6).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'locked',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8A94A6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 64,
    endIndent: 0,
    color: Color(0xFFF0F1F5),
  );
}
