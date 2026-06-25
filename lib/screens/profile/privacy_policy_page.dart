import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1008),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
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
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header card ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8651A), Color(0xFFB84A0E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8651A).withOpacity(0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Last updated: June 2026',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.80),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Intro ────────────────────────────────────────
                  _WhiteCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8651A).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Color(0xFFE8651A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Gramika respects your privacy and is committed to protecting your personal information. This policy explains how we collect, use, and safeguard your data.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4A5568),
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Policy points ────────────────────────────────
                  const _SectionLabel(label: 'OUR COMMITMENTS'),
                  const SizedBox(height: 10),
                  _WhiteCard(
                    child: Column(
                      children: const [
                        _PolicyTile(
                          icon: Icons.person_rounded,
                          iconColor: Color(0xFF1877F2),
                          title: 'Personal Information',
                          body:
                              'Your personal information is used solely for providing our services and improving your experience within Gramika.',
                        ),
                        _PolicyDivider(),
                        _PolicyTile(
                          icon: Icons.phone_rounded,
                          iconColor: Color(0xFF25D366),
                          title: 'Contact Details',
                          body:
                              'Phone numbers and email addresses are never shared publicly or sold to third parties.',
                        ),
                        _PolicyDivider(),
                        _PolicyTile(
                          icon: Icons.location_on_rounded,
                          iconColor: Color(0xFFE8651A),
                          title: 'Location Data',
                          body:
                              'Location details are used exclusively for delivering panchayat-specific services relevant to your area.',
                        ),
                        _PolicyDivider(),
                        _PolicyTile(
                          icon: Icons.feedback_rounded,
                          iconColor: Color(0xFFB84A0E),
                          title: 'Complaints & Feedback',
                          body:
                              'All complaints and feedback you submit are securely stored and accessible only to authorised administrators.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Footer note ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8651A).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE8651A).withOpacity(0.20),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFE8651A),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'By using Gramika, you agree to the terms outlined in this Privacy Policy. We may update this policy from time to time and will notify you of any significant changes.',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFB84A0E),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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

// ── Policy item ────────────────────────────────────────────────────────────
class _PolicyTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _PolicyTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1008),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A94A6),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Shared helpers ─────────────────────────────────────────────────────────
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

class _PolicyDivider extends StatelessWidget {
  const _PolicyDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 68,
    endIndent: 0,
    color: Color(0xFFF0F1F5),
  );
}
