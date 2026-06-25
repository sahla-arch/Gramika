import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/ads/ads_management_pg.dart';
import '/screens/directories/add_directory_page.dart';
// import '/screens/directories/directory_details_page.dart';
import '/screens/directories/directory_list_pg.dart';
import '/screens/news/news_management_pg.dart';
import '/screens/emergency/emergency_management_pg.dart';
import '/screens/jobs/jobs_management_pg.dart';
import '/screens/reports_feedbacks/reports_feedback_page.dart';
import '/screens/reports_feedbacks/admin_notice_page.dart';
import '/screens/login_pg.dart';
// import '/screens/profile/faq_list_page.dart';
import 'admin_settings_page.dart';
import 'ad_not_icon_pg.dart';

// ─── Color Tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFE65100);
const _kPrimaryLight = Color(0xFFFF6D00);
const _kSurface = Color(0xFFF8F9FB);
const _kText = Color(0xFF1A1A2E);
const _kSubtext = Color(0xFF6B7280);

const _headerGradient = LinearGradient(
  colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─────────────────────────────────────────────────────────────────────────────
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<String> assignedPanchayats = [];
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadAssignedPanchayats();
  }

  String adminName = "Admin";
  String adminEmail = "";

  Future<void> loadAssignedPanchayats() async {
    final email = FirebaseAuth.instance.currentUser?.email;

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      final data = result.docs.first.data();

      setState(() {
        adminName = data['name'] ?? 'Admin';

        adminEmail = data['email'] ?? '';

        assignedPanchayats = List<String>.from(
          data['assignedPanchayats'] ?? [],
        );
      });
    }
  }

  final List<_NavItem> _navItems = const [
    _NavItem("Dashboard", Icons.dashboard_rounded),
    _NavItem("News Management", Icons.newspaper_rounded),
    _NavItem("Advertisements", Icons.campaign_rounded),
    _NavItem("Emergency Contacts", Icons.emergency_rounded),
    _NavItem("Directories", Icons.folder_rounded),
    _NavItem("Jobs Management", Icons.work_rounded),
    _NavItem("Reports & Feedback", Icons.feedback_rounded),
    _NavItem("Settings", Icons.settings_rounded),
  ];

  Widget _getSelectedScreen() {
    switch (selectedIndex) {
      case 0:
        return DashboardScreen(assignedPanchayats: assignedPanchayats);
      case 1:
        return const NewsManagementPage();
      case 2:
        return const AdsManagementPage();
      case 3:
        return const EmergencyManagementPage();
      case 4:
        return const DirectoriesScreen();
      case 5:
        return const JobManagementPage();
      case 6:
        return const ReportsFeedbackPage(isSuperAdmin: false);
      case 7:
        return const AdminSettingsPage();
      default:
        return DashboardScreen(assignedPanchayats: assignedPanchayats);
    }
  }

  Widget _placeholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.orange.shade200),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _kSubtext,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _headerGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Admin Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              "Malappuram Panchayat Portal",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminNotificationsPage(),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _getSelectedScreen(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: _headerGradient),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  adminName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  adminEmail,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: assignedPanchayats
                      .map(
                        (p) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: Material(
                    color: isSelected
                        ? _kPrimary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        item.icon,
                        color: isSelected ? _kPrimary : _kSubtext,
                        size: 22,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? _kPrimary : _kText,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _kPrimary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : null,
                      onTap: () {
                        setState(() => selectedIndex = index);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 22,
              ),
              title: const Text(
                "Sign Out",
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to sign out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                await FirebaseAuth.instance.signOut();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  const _NavItem(this.title, this.icon);
}

// ─── Dashboard Screen ─────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final List<String> assignedPanchayats;

  const DashboardScreen({super.key, required this.assignedPanchayats});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalUsers = 0;
  int totalAdmins = 0;
  int totalComplaints = 0;
  int totalBusinesses = 0;
  int totalAds = 0;

  Future<void> loadDashboardCounts() async {
    final users = await FirebaseFirestore.instance.collection('users').get();

    final complaints = await FirebaseFirestore.instance
        .collection('issues')
        .get();

    final directories = await FirebaseFirestore.instance
        .collection('directories')
        .get();

    final ads = await FirebaseFirestore.instance.collection('ads').get();

    setState(() {
      totalUsers = users.docs.length;

      totalAdmins = users.docs.where((d) {
        final role = (d.data() as Map<String, dynamic>)['role'] ?? '';
        return role.toString().toLowerCase().contains('admin');
      }).length;

      totalComplaints = complaints.docs.length;
      totalBusinesses = directories.docs.length;
      totalAds = ads.docs.length;
    });
  }

  @override
  void initState() {
    super.initState();
    loadDashboardCounts();
  }

  String selectedAnalytics = "Weekly";
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kText,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting Banner ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
                        "Good Morning 👋",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (context.findAncestorStateOfType<_AdminPageState>())
                                ?.adminName ??
                            "Admin",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Assigned Panchayats pill
                      if (widget.assignedPanchayats.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.assignedPanchayats
                              .take(3)
                              .map((p) => _PillBadge(p))
                              .toList(),
                        )
                      else
                        const _PillBadge("Malappuram Panchayat Portal"),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),

          // ── Assigned Panchayats chip row ─────────────────────────
          if (widget.assignedPanchayats.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionLabel("Assigned Panchayats"),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.assignedPanchayats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kPrimary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: _kPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.assignedPanchayats[i],
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),
          _sectionLabel("Overview"),
          const SizedBox(height: 12),

          // ── Stats Grid ────────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatCard(
                title: "Total Users",
                value: totalUsers.toString(),
                icon: Icons.people_rounded,
                color: const Color(0xFF3B82F6),
              ),

              StatCard(
                title: "Admins",
                value: totalAdmins.toString(),
                icon: Icons.manage_accounts_rounded,
                color: const Color(0xFFE65100),
              ),

              StatCard(
                title: "New Complaints",
                value: totalComplaints.toString(),
                icon: Icons.feedback_rounded,
                color: const Color(0xFFEF4444),
              ),

              StatCard(
                title: "Businesses",
                value: totalBusinesses.toString(),
                icon: Icons.store_rounded,
                color: const Color(0xFF10B981),
              ),

              StatCard(
                title: "Active Ads",
                value: totalAds.toString(),
                icon: Icons.campaign_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionLabel("Visitor Analytics"),
          const SizedBox(height: 12),

          // ── Single Analytics Card ─────────────────────────────────
          _AnalyticsCard(
            selectedAnalytics: selectedAnalytics,
            onChanged: (v) {
              if (v != null) setState(() => selectedAnalytics = v);
            },
          ),

          const SizedBox(height: 24),
          _sectionLabel("Quick Actions"),
          const SizedBox(height: 12),

          // ── Quick Actions ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 20,
              runSpacing: 20,
              children: [
                _QuickActionTile(
                  label: "Directories",
                  icon: Icons.folder_rounded,
                  color: const Color(0xFF0EA5E9),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddDirectoryPage(),
                      ),
                    );
                  },
                ),
                _QuickActionTile(
                  label: "Send Notice",
                  icon: Icons.notifications_active_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminNoticePage(),
                      ),
                    );
                  },
                ),
                _QuickActionTile(
                  label: "Reports",
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ReportsFeedbackPage(isSuperAdmin: true),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _sectionLabel("Recent Activity"),
          const SizedBox(height: 12),
          const RecentActivityCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Pill Badge ───────────────────────────────────────────────────────────────
class _PillBadge extends StatelessWidget {
  final String text;
  const _PillBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Quick Action Tile ────────────────────────────────────────────────────────
class _QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 64,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: Colors.green.shade400,
                size: 16,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: _kSubtext),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Analytics Card (single, no duplicate) ───────────────────────────────────
class _AnalyticsCard extends StatelessWidget {
  final String selectedAnalytics;
  final ValueChanged<String?> onChanged;

  const _AnalyticsCard({
    required this.selectedAnalytics,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final weeklyData = [120, 220, 180, 260, 240, 320, 300];
    final monthlyData = [200, 350, 450, 300, 550, 650, 480];
    final data = selectedAnalytics == "Weekly" ? weeklyData : monthlyData;
    final labels = selectedAnalytics == "Weekly"
        ? ["M", "T", "W", "T", "F", "S", "S"]
        : ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"];
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Visitors",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kPrimary.withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  value: selectedAnalytics,
                  underline: const SizedBox(),
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(value: "Weekly", child: Text("Weekly")),
                    DropdownMenuItem(value: "Monthly", child: Text("Monthly")),
                  ],
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            selectedAnalytics == "Weekly"
                ? "This week's visits"
                : "Monthly visit trends",
            style: const TextStyle(fontSize: 12, color: _kSubtext),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(data.length, (i) {
                final barH = (data[i] / maxVal) * 130;
                final isMax = data[i] == data.reduce((a, b) => a > b ? a : b);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isMax)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          data[i].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Container(
                      width: 22,
                      height: barH,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isMax
                              ? [_kPrimary, _kPrimaryLight]
                              : [
                                  _kPrimary.withOpacity(0.35),
                                  _kPrimary.withOpacity(0.15),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: const TextStyle(fontSize: 10, color: _kSubtext),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Activity Card ─────────────────────────────────────────────────────
class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    // final activities = [
    //   _Activity(
    //     "New User Registered",
    //     "2 minutes ago",
    //     Icons.person_add_rounded,
    //     Color(0xFF3B82F6),
    //   ),
    //   _Activity(
    //     "News Article Published",
    //     "14 minutes ago",
    //     Icons.article_rounded,
    //     Color(0xFF10B981),
    //   ),
    //   _Activity(
    //     "Advertisement Approved",
    //     "1 hour ago",
    //     Icons.campaign_rounded,
    //     Color(0xFF8B5CF6),
    //   ),
    //   _Activity(
    //     "New Directory Added",
    //     "3 hours ago",
    //     Icons.folder_rounded,
    //     const Color.fromARGB(255, 112, 6, 87),
    //   ),

    //   _Activity(
    //     "New Questions Added",
    //     "3 hours ago",
    //     Icons.question_answer_rounded,
    //     _kPrimary,
    //   ),
    // ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Activity",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(foregroundColor: _kPrimary),
                  child: const Text("See all", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('faqs')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No questions asked yet"),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(height: 1),
                      ),

                      ListTile(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(data['question'] ?? ''),

                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Asked By: ${data['askedBy'] ?? ''}"),
                                  const SizedBox(height: 8),
                                  Text("Panchayat: ${data['panchayat'] ?? ''}"),
                                  const SizedBox(height: 8),
                                  Text("Status: ${data['status'] ?? ''}"),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Answer: ${data['answer'] ?? 'Pending'}",
                                  ),
                                ],
                              ),
                            ),
                          );
                        },

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),

                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.question_answer_rounded,
                            color: Colors.orange,
                          ),
                        ),

                        title: Text(
                          data['question'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        subtitle: Text(data['askedBy'] ?? ''),

                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Activity {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  const _Activity(this.title, this.time, this.icon, this.color);
}

// ─── Directories Screen ───────────────────────────────────────────────────────
class DirectoriesScreen extends StatelessWidget {
  const DirectoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Directory"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddDirectoryPage(isSuperAdmin: false),
            ),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('directory_categories')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong."));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_off_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "No directories yet",
                    style: TextStyle(color: _kSubtext, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final color = Color(int.parse(data['colors'] ?? '0xFF3B82F6'));

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DirectoryListPage(
                        categoryId: docs[index].id,
                        categoryName: data['name'],
                        isSuperAdmin: false,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getIcon(data['icon']),
                          size: 24,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          data['name'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Graph Bar (kept for compatibility) ──────────────────────────────────────
class GraphBar extends StatelessWidget {
  final double height;
  const GraphBar({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimary, _kPrimaryLight],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// ─── Icon Resolver ────────────────────────────────────────────────────────────
IconData _getIcon(String? iconName) {
  switch (iconName) {
    case 'school_rounded':
      return Icons.school_rounded;
    case 'local_hospital_rounded':
      return Icons.local_hospital_rounded;
    case 'account_balance_rounded':
      return Icons.account_balance_rounded;
    case 'directions_bus_rounded':
      return Icons.directions_bus_rounded;
    case 'store_rounded':
      return Icons.store_rounded;
    case 'travel_explore_rounded':
      return Icons.travel_explore_rounded;
    case 'ev_station_rounded':
      return Icons.ev_station_rounded;
    default:
      return Icons.folder_rounded;
  }
}
