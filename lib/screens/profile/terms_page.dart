import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  final List<Map<String, dynamic>> _sections = const [
    {
      "icon": Icons.person_outline_rounded,
      "title": "User Responsibilities",
      "body":
          "Users must provide accurate, truthful, and up-to-date information at all times. Submitting false or misleading details may result in account suspension or removal from the platform.",
    },
    {
      "icon": Icons.report_gmailerrorred_rounded,
      "title": "Complaints & Reports",
      "body":
          "Misuse of the complaints or reporting system is strictly prohibited. Filing false complaints, spam reports, or using the system for personal disputes unrelated to civic services will be treated as a violation.",
    },
    {
      "icon": Icons.storefront_outlined,
      "title": "Service Provider Obligations",
      "body":
          "Service providers are solely responsible for the accuracy, legality, and quality of their listings. Gramika acts as a platform and does not verify or endorse any individual listing.",
    },
    {
      "icon": Icons.admin_panel_settings_outlined,
      "title": "Content Moderation",
      "body":
          "Panchayat administration reserves the right to review, edit, or permanently remove any content deemed inappropriate, misleading, or in violation of community guidelines without prior notice.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: false,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.gavel_rounded,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Please read carefully",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "By using Gramika, you agree to the following terms. These guidelines ensure a safe and trustworthy experience for all citizens.",
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: colorScheme.onPrimaryContainer.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "Terms of Use",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 10),

              // Terms sections
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: _sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final section = entry.value;
                      final isLast = index == _sections.length - 1;
                      return _TermsSection(
                        icon: section["icon"] as IconData,
                        title: section["title"] as String,
                        body: section["body"] as String,
                        showDivider: !isLast,
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Last updated footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 15,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Last updated: ",
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      "June 2026",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool showDivider;

  const _TermsSection({
    required this.icon,
    required this.title,
    required this.body,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 68,
            endIndent: 16,
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),
      ],
    );
  }
}
