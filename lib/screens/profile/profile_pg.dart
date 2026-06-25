import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

import '/screens/login_pg.dart';
import 'edit_profile_page.dart';
import 'hlp_sprt_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _selectedImage;

  // ── Image pick & save ────────────────────────────────────────────────
  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final email = FirebaseAuth.instance.currentUser?.email;

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      await result.docs.first.reference.update({
        'photoUrl': base64Encode(bytes),
      });
    }

    if (mounted) setState(() {});
  }

  // ── Fetch user doc ───────────────────────────────────────────────────
  Future<QueryDocumentSnapshot?> getUserData() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (result.docs.isEmpty) return null;
    return result.docs.first;
  }

  // ── Logout ───────────────────────────────────────────────────────────
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ── Support sheet ────────────────────────────────────────────────────
  void _showSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1008),
              ),
            ),
            const SizedBox(height: 16),
            _SupportTile(
              icon: Icons.call_rounded,
              iconColor: const Color(0xFF2E7D32),
              bgColor: const Color(0xFF2E7D32),
              label: 'Call Admin',
              onTap: () async =>
                  await launchUrl(Uri.parse('tel:+919876543210')),
            ),
            const SizedBox(height: 10),
            _SupportTile(
              icon: Icons.chat_rounded,
              iconColor: const Color(0xFF25D366),
              bgColor: const Color(0xFF25D366),
              label: 'WhatsApp',
              onTap: () async => await launchUrl(
                Uri.parse('https://wa.me/919876543210'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const SizedBox(height: 10),
            _SupportTile(
              icon: Icons.email_rounded,
              iconColor: const Color(0xFFE8651A),
              bgColor: const Color(0xFFE8651A),
              label: 'Email Admin',
              onTap: () async =>
                  await launchUrl(Uri.parse('mailto:admin@gramika.com')),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout dialog ────────────────────────────────────────────────────
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8A94A6)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) logout(context);
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final email = user.email;

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      await result.docs.first.reference.update({
        'accountDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FutureBuilder<QueryDocumentSnapshot?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8651A)),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Profile not found'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final name = data['name'] as String? ?? 'User';
          final email = data['email'] as String? ?? '';
          final professions = data['professions'] != null
              ? List<String>.from(data['professions'] as List)
              : <String>[];
          final profString = professions.join(', ');
          final photoUrl = data['photoUrl'] as String? ?? '';

          return CustomScrollView(
            slivers: [
              // ── Hero AppBar ────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                backgroundColor: const Color(0xFF1C1008),
                foregroundColor: Colors.white,
                title: const Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1C1008), Color(0xFFE8651A)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Avatar + name overlay
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            // Avatar with camera button
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 48,
                                    backgroundColor: const Color(0xFFFFF3E0),
                                    backgroundImage: photoUrl.isNotEmpty
                                        ? MemoryImage(base64Decode(photoUrl))
                                        : null,
                                    child: photoUrl.isEmpty
                                        ? const Icon(
                                            Icons.person_rounded,
                                            size: 52,
                                            color: Color(0xFFE8651A),
                                          )
                                        : null,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE8651A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (profString.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                profString,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.80),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Info card ────────────────────────────────
                      _SectionLabel(label: 'ACCOUNT INFO'),
                      const SizedBox(height: 8),
                      _WhiteCard(
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.person_rounded,
                              label: 'Name',
                              value: name,
                            ),
                            const _RowDivider(),
                            _InfoTile(
                              icon: Icons.email_rounded,
                              label: 'Email',
                              value: email,
                            ),
                            if (professions.isNotEmpty) ...[
                              const _RowDivider(),
                              _InfoTile(
                                icon: Icons.work_rounded,
                                label: 'Profession',
                                value: profString,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Account actions ──────────────────────────
                      _SectionLabel(label: 'ACCOUNT'),
                      const SizedBox(height: 8),
                      _WhiteCard(
                        child: Column(
                          children: [
                            _MenuTile(
                              icon: Icons.edit_rounded,
                              iconColor: const Color(0xFF1877F2),
                              label: 'Edit Profile',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfilePage(),
                                ),
                              ),
                            ),
                            const _RowDivider(),
                            _MenuTile(
                              icon: Icons.settings_rounded,
                              iconColor: const Color(0xFF8A94A6),
                              label: 'Settings',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsPage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Support ──────────────────────────────────
                      _SectionLabel(label: 'SUPPORT'),
                      const SizedBox(height: 8),
                      _WhiteCard(
                        child: Column(
                          children: [
                            _MenuTile(
                              icon: Icons.support_agent_rounded,
                              iconColor: const Color(0xFF25D366),
                              label: 'Contact Support',
                              subtitle: 'Call, WhatsApp or Email',
                              onTap: () => _showSupportSheet(context),
                            ),
                            const _RowDivider(),
                            _MenuTile(
                              icon: Icons.help_outline_rounded,
                              iconColor: const Color(0xFFE8651A),
                              label: 'Help & Support',
                              subtitle: 'FAQ, About Gramika & Support',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FAQPage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      const SizedBox(height: 16),

                      _WhiteCard(
                        child: _MenuTile(
                          icon: Icons.delete_forever_rounded,
                          iconColor: const Color(0xFFD32F2F),
                          label: 'Delete Account',
                          labelColor: const Color(0xFFD32F2F),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Account'),
                                content: const Text(
                                  'Your login account will be deleted. Your complaints, feedbacks, reviews and records will remain stored.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),

                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _deleteAccount();
                            }
                          },
                        ),
                      ),
                      // ── Logout ───────────────────────────────────
                      _WhiteCard(
                        child: _MenuTile(
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFE53935),
                          label: 'Logout',
                          labelColor: const Color(0xFFE53935),
                          onTap: () => _confirmLogout(context),
                          showChevron: false,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── App version ──────────────────────────────
                      Center(
                        child: Text(
                          'Gramika v1.0.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Support bottom-sheet tile ──────────────────────────────────────────────
class _SupportTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            color: iconColor.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    ),
  );
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE8651A).withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFE8651A), size: 19),
        ),
        const SizedBox(width: 14),
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
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1008),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.subtitle,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? const Color(0xFF1C1008),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A94A6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (showChevron)
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

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 68,
    endIndent: 0,
    color: Color(0xFFF0F1F5),
  );
}
