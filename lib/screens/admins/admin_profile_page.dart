import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  static const _orange = Colors.orange;
  static const _bg = Color(0xFFF5F6FA);
  static const _dark = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Profile',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get(),
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _orange),
                    SizedBox(height: 14),
                    Text(
                      'Loading profile…',
                      style: TextStyle(color: Colors.black38, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            // Error
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 34,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Could not load your profile.\nPlease try again later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black38,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Empty
            if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_off_outlined,
                          size: 38,
                          color: _orange,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'No Profile Found',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No admin profile is linked\nto this account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final name = (data['name'] as String?)?.trim() ?? '';
            final dataEmail = (data['email'] as String?)?.trim() ?? email;
            final role = (data['role'] as String?)?.trim() ?? 'Admin';
            final phone = (data['phone'] as String?)?.trim() ?? '';
            final panchayat = (data['panchayat'] as String?)?.trim() ?? '';
            final district = (data['district'] as String?)?.trim() ?? '';
            final joinedAt = data['createdAt'] as Timestamp?;

            final initial = name.isNotEmpty
                ? name[0].toUpperCase()
                : dataEmail.isNotEmpty
                ? dataEmail[0].toUpperCase()
                : 'A';

            String? joinedDate;
            if (joinedAt != null) {
              final dt = joinedAt.toDate();
              const months = [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec',
              ];
              joinedDate = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // ── Avatar + name banner ───────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (name.isNotEmpty)
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            color: _orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      if (joinedDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: Colors.black38,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Member since $joinedDate',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Contact details ────────────────────────────────
                const _SectionLabel(label: 'CONTACT INFORMATION'),
                const SizedBox(height: 10),

                _ProfileCard(
                  items: [
                    _ProfileField(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFF1E88E5),
                      label: 'Email Address',
                      value: dataEmail,
                    ),
                    if (phone.isNotEmpty)
                      _ProfileField(
                        icon: Icons.phone_outlined,
                        iconColor: const Color(0xFF43A047),
                        label: 'Phone Number',
                        value: phone,
                        isLast: true,
                      )
                    else
                      const _ProfileField(
                        icon: Icons.phone_outlined,
                        iconColor: Color(0xFF43A047),
                        label: 'Phone Number',
                        value: 'Not provided',
                        isLast: true,
                        muted: true,
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Admin details ──────────────────────────────────
                const _SectionLabel(label: 'ADMIN DETAILS'),
                const SizedBox(height: 10),

                _ProfileCard(
                  items: [
                    _ProfileField(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: _orange,
                      label: 'Role',
                      value: role,
                    ),
                    if (panchayat.isNotEmpty)
                      _ProfileField(
                        icon: Icons.location_city_rounded,
                        iconColor: const Color(0xFF8E24AA),
                        label: 'Assigned Panchayat',
                        value: panchayat,
                      ),
                    if (district.isNotEmpty)
                      _ProfileField(
                        icon: Icons.map_outlined,
                        iconColor: const Color(0xFF43A047),
                        label: 'District',
                        value: district,
                        isLast: true,
                      )
                    else if (panchayat.isEmpty)
                      const _ProfileField(
                        icon: Icons.location_city_rounded,
                        iconColor: Color(0xFF8E24AA),
                        label: 'Assigned Panchayat',
                        value: 'Not assigned',
                        isLast: true,
                        muted: true,
                      ),
                  ],
                ),

                if (joinedDate != null) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel(label: 'ACCOUNT'),
                  const SizedBox(height: 10),
                  _ProfileCard(
                    items: [
                      _ProfileField(
                        icon: Icons.calendar_today_rounded,
                        iconColor: const Color(0xFF78909C),
                        label: 'Member Since',
                        value: joinedDate,
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.black38,
        letterSpacing: 1.1,
      ),
    );
  }
}

// ── Profile card wrapper ──────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final List<Widget> items;
  const _ProfileCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: items),
      ),
    );
  }
}

// ── Profile field row ─────────────────────────────────────────────────────────
class _ProfileField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isLast;
  final bool muted;

  const _ProfileField({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isLast = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 20),
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
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: muted ? Colors.black26 : const Color(0xFF1A1A2E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 70,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }
}
