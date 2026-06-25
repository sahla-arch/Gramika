import 'package:flutter/material.dart';
import 'privacy_policy_page.dart';
import 'terms_page.dart';
import 'language_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1008),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              children: [
                // ── Legal ────────────────────────────────────────────
                const _SectionLabel(label: 'LEGAL'),
                const SizedBox(height: 8),
                _WhiteCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.lock_rounded,
                      iconColor: const Color(0xFF1877F2),
                      label: 'Privacy Policy',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      ),
                    ),
                    const _RowDivider(),
                    _SettingsTile(
                      icon: Icons.description_rounded,
                      iconColor: const Color(0xFF8A94A6),
                      label: 'Terms & Conditions',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsPage()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Preferences ──────────────────────────────────────
                const _SectionLabel(label: 'PREFERENCES'),
                const SizedBox(height: 8),
                _WhiteCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      iconColor: const Color(0xFFE8651A),
                      label: 'Notification Preferences',
                      onTap: () {
                        // wire up your NotificationsPage here
                      },
                    ),
                    const _RowDivider(),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF00B4A6),
                      label: 'Language',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LanguagePage()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── About ────────────────────────────────────────────
                const _SectionLabel(label: 'ABOUT'),
                const SizedBox(height: 8),
                _WhiteCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.info_rounded,
                      iconColor: const Color(0xFFB84A0E),
                      label: 'About Gramika',
                      subtitle:
                          'Version 1.0.0 · Digital Citizen Service Platform',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'Gramika',
                        applicationVersion: '1.0.0',
                        children: const [
                          Text('Digital Citizen Service Platform'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── App badge ────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8651A), Color(0xFFB84A0E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE8651A).withOpacity(0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_city_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Gramika',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C1008),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'v1.0.0 · Digital Citizen Service Platform',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable card wrapper ──────────────────────────────────────────────────
class _WhiteCard extends StatelessWidget {
  final List<Widget> children;
  const _WhiteCard({required this.children});

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
    child: Column(children: children),
  );
}

// ── Single settings row ────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.subtitle,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1008),
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

// ── Section label ──────────────────────────────────────────────────────────
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

// ── Divider ────────────────────────────────────────────────────────────────
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
