import 'package:flutter/material.dart';

class AdminNotificationSettingsPage extends StatefulWidget {
  const AdminNotificationSettingsPage({super.key});

  @override
  State<AdminNotificationSettingsPage> createState() =>
      _AdminNotificationSettingsPageState();
}

class _AdminNotificationSettingsPageState
    extends State<AdminNotificationSettingsPage> {
  bool _notices = true;
  bool _complaints = true;
  bool _feedbacks = true;

  static const _orange = Colors.orange;
  static const _bg = Color(0xFFF5F6FA);
  static const _dark = Color(0xFF1A1A2E);

  bool get _allEnabled => _notices && _complaints && _feedbacks;

  void _toggleAll(bool value) {
    setState(() {
      _notices = value;
      _complaints = value;
      _feedbacks = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // ── Header banner ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: _orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Notifications',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _dark,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Choose which alerts you want to receive as an admin. You can turn these on or off at any time.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Master toggle ────────────────────────────────────────
            const _SectionLabel(label: 'MASTER CONTROL'),
            const SizedBox(height: 10),

            Container(
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
              child: _NotifToggleTile(
                icon: Icons.notifications_rounded,
                iconColor: _orange,
                title: 'All Notifications',
                subtitle: _allEnabled
                    ? 'All alerts are enabled'
                    : 'Some alerts are disabled',
                value: _allEnabled,
                isLast: true,
                onChanged: _toggleAll,
              ),
            ),

            const SizedBox(height: 24),

            // ── Individual toggles ───────────────────────────────────
            const _SectionLabel(label: 'NOTIFICATION TYPES'),
            const SizedBox(height: 10),

            Container(
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
                child: Column(
                  children: [
                    _NotifToggleTile(
                      icon: Icons.campaign_rounded,
                      iconColor: const Color(0xFF8E24AA),
                      title: 'Admin Notices',
                      subtitle: 'Broadcasts and announcements',
                      value: _notices,
                      onChanged: (v) => setState(() => _notices = v),
                    ),
                    _NotifToggleTile(
                      icon: Icons.report_problem_outlined,
                      iconColor: const Color(0xFFE53935),
                      title: 'Complaints',
                      subtitle: 'New and updated citizen complaints',
                      value: _complaints,
                      onChanged: (v) => setState(() => _complaints = v),
                    ),
                    _NotifToggleTile(
                      icon: Icons.rate_review_outlined,
                      iconColor: const Color(0xFF43A047),
                      title: 'Feedbacks',
                      subtitle: 'Ratings and reviews from citizens',
                      value: _feedbacks,
                      isLast: true,
                      onChanged: (v) => setState(() => _feedbacks = v),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Status summary card ──────────────────────────────────
            Container(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: Colors.black38,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Current Status',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatusChip(
                        label: 'Notices',
                        enabled: _notices,
                        color: const Color(0xFF8E24AA),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Complaints',
                        enabled: _complaints,
                        color: const Color(0xFFE53935),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Feedbacks',
                        enabled: _feedbacks,
                        color: const Color(0xFF43A047),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Save button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Notification preferences saved!',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Save Preferences'),
                  ],
                ),
              ),
            ),
          ],
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

// ── Toggle tile ───────────────────────────────────────────────────────────────
class _NotifToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  const _NotifToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: Colors.orange,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.black12,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.enabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? color.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? color.withOpacity(0.25) : Colors.black12,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 16,
              color: enabled ? color : Colors.black26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: enabled ? color : Colors.black26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
