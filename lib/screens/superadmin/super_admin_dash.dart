import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/ads/ads_management_pg.dart';
import 'admin_mngmnt_pg.dart';
import 'panchayat_mngmnt_pg.dart';
import '/screens/directories/add_directory_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/screens/directories/directory_list_pg.dart';
import '/screens/news/news_management_pg.dart';
import '/screens/emergency/emergency_management_pg.dart';
import '/screens/jobs/jobs_management_pg.dart';
import '/screens/reports_feedbacks/reports_feedback_page.dart';
import '/screens/reports_feedbacks/admin_notice_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/screens/login_pg.dart';
// import '/screens/faq_reply_page.dart';
import 'super_admin_settings_page.dart';
import '/screens/admins/ad_not_icon_pg.dart';

// ─── Color Tokens ─────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFFE65100);
const _kPrimaryLight = Color(0xFFFF6D00);
const _kAccent = Color(0xFFFFF3E0);
const _kSurface = Color(0xFFF8F9FB);
const _kCard = Colors.white;
const _kText = Color(0xFF1A1A2E);
const _kSubtext = Color(0xFF6B7280);

const _headerGradient = LinearGradient(
  colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─────────────────────────────────────────────────────────────────────────────
class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  int selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem("Dashboard", Icons.dashboard_rounded),
    _NavItem("User Management", Icons.manage_accounts_rounded),
    _NavItem("News", Icons.newspaper_rounded),
    _NavItem("Advertisements", Icons.campaign_rounded),
    _NavItem("Emergency Contacts", Icons.emergency_rounded),
    _NavItem("Directories", Icons.folder_rounded),
    _NavItem("Jobs", Icons.work_rounded),
    _NavItem("Reports & Feedback", Icons.feedback_rounded),
    _NavItem("Settings", Icons.settings_rounded),
  ];

  Widget _getSelectedScreen() {
    switch (selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const AdminManagementPage();
      case 2:
        return const NewsManagementPage();
      case 3:
        return const AdsManagementPage();
      case 4:
        return const EmergencyManagementPage();
      case 5:
        return const DirectoriesScreen();
      case 6:
        return const JobManagementPage();
      case 7:
        return const ReportsFeedbackPage(isSuperAdmin: true);
      case 8:
        return const SuperAdminSettingsPage();
      default:
        return const DashboardScreen();
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
              "Super Admin Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              "Malappuram District",
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
                const Text(
                  "Super Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "superadminmlprm@gmail.com",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
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
                        ? const Color(0xFFE65100).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        item.icon,
                        color: isSelected ? const Color(0xFFE65100) : _kSubtext,
                        size: 22,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? const Color(0xFFE65100) : _kText,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE65100),
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
  const DashboardScreen({super.key});

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
            color: const Color(0xFFE65100),
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
          // Greeting banner
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
                  color: const Color(0xFFE65100).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Good Morning 👋",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Super Admin",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10),
                      _PillBadge("Malappuram District Portal"),
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

          const SizedBox(height: 24),
          _sectionLabel("Overview"),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
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

          _AnalyticsCard(
            selectedAnalytics: selectedAnalytics,
            onChanged: (v) {
              if (v != null) setState(() => selectedAnalytics = v);
            },
          ),

          const SizedBox(height: 24),
          _sectionLabel("Quick Actions"),
          const SizedBox(height: 12),
          const QuickActionsCard(),

          const SizedBox(height: 24),
          _sectionLabel("Recent Activity"),
          const SizedBox(height: 12),
          RecentActivityCard(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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

// ─── Analytics Card ───────────────────────────────────────────────────────────
class _AnalyticsCard extends StatefulWidget {
  final String selectedAnalytics;
  final ValueChanged<String?> onChanged;

  const _AnalyticsCard({
    required this.selectedAnalytics,
    required this.onChanged,
  });

  @override
  State<_AnalyticsCard> createState() => _AnalyticsCardState();
}

class _AnalyticsCardState extends State<_AnalyticsCard> {
  List<int> weeklyData = List.filled(7, 0);
  List<int> monthlyData = List.filled(12, 0);

  @override
  void initState() {
    super.initState();
    loadVisitorData();
  }

  Future<void> loadVisitorData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('visitor_logs')
        .get();

    List<int> week = List.filled(7, 0);
    List<int> month = List.filled(12, 0);

    final now = DateTime.now();

    for (final doc in snapshot.docs) {
      final ts = doc['createdAt'] as Timestamp;
      final date = ts.toDate();

      // Weekly
      final difference = now.difference(date).inDays;

      if (difference >= 0 && difference < 7) {
        week[6 - difference]++;
      }

      // Monthly
      if (date.year == now.year) {
        month[date.month - 1]++;
      }
    }

    setState(() {
      weeklyData = week;
      monthlyData = month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.selectedAnalytics == "Weekly"
        ? weeklyData
        : monthlyData;

    final labels = widget.selectedAnalytics == "Weekly"
        ? ["M", "T", "W", "T", "F", "S", "S"]
        : ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];

    double maxVal = 1;

    if (data.isNotEmpty) {
      maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
      if (maxVal == 0) maxVal = 1;
    }

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
                  border: Border.all(
                    color: const Color(0xFFE65100).withOpacity(0.3),
                  ),
                ),
                child: DropdownButton<String>(
                  value: widget.selectedAnalytics,
                  underline: const SizedBox(),
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(value: "Weekly", child: Text("Weekly")),
                    DropdownMenuItem(value: "Monthly", child: Text("Monthly")),
                  ],
                  onChanged: widget.onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.selectedAnalytics == "Weekly"
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
                          color: const Color(0xFFE65100),
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
                      width: 28,
                      height: barH,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isMax
                              ? [
                                  const Color(0xFFE65100),
                                  const Color(0xFFFF6D00),
                                ]
                              : [
                                  const Color(0xFFE65100).withOpacity(0.35),
                                  const Color(0xFFE65100).withOpacity(0.15),
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

// ─── Quick Actions Card ───────────────────────────────────────────────────────
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label: "Panchayat\nMgmt",
            icon: Icons.map_rounded,
            color: const Color(0xFF0EA5E9),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PanchayatMngmntPg()),
            ),
          ),
          _QuickActionTile(
            label: "Add\nAdmin",
            icon: Icons.person_add_rounded,
            color: const Color(0xFFE65100),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminManagementPage()),
            ),
          ),

          _QuickActionTile(
            label: "Add\nDirectory",
            icon: Icons.add_circle_outline_rounded,
            color: const Color(0xFF14B8A6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddDirectoryPage(isSuperAdmin: true),
                ),
              );
              // Navigate to Add Directory Page
            },
          ),
          _QuickActionTile(
            label: "Send\nNotice",
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminNoticePage()),
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
                  builder: (_) => const ReportsFeedbackPage(isSuperAdmin: true),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

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

// ─── Recent Activity Card ─────────────────────────────────────────────────────
class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      _Activity(
        "New User Registered",
        "2 minutes ago",
        Icons.person_add_rounded,
        Color(0xFF3B82F6),
      ),
      _Activity(
        "News Article Published",
        "14 minutes ago",
        Icons.article_rounded,
        Color(0xFF10B981),
      ),
      _Activity(
        "Advertisement Approved",
        "1 hour ago",
        Icons.campaign_rounded,
        Color(0xFF8B5CF6),
      ),
      _Activity(
        "New Directory Added",
        "3 hours ago",
        Icons.folder_rounded,
        _kPrimary,
      ),
    ];

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
          ...activities.asMap().entries.map((e) {
            final i = e.key;
            final a = e.value;
            return Column(
              children: [
                if (i != 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1),
                  ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(a.icon, color: a.color, size: 20),
                  ),
                  title: Text(
                    a.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                  ),
                  subtitle: Text(
                    a.time,
                    style: const TextStyle(fontSize: 11, color: _kSubtext),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: _kSubtext,
                    size: 18,
                  ),
                ),
              ],
            );
          }),
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

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE65100),
        tooltip: "Add Directory",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDirectoryPage()),
          );
        },
        child: const Icon(Icons.create_new_folder_rounded, color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('directory_categories')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectoryListPage(
                          categoryId: docs[index].id,
                          categoryName: data['name'],
                          isSuperAdmin: true,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIcon(data['icon'] ?? ''),
                              color: Color(
                                int.parse(data['colors'] ?? '0xFF3B82F6'),
                              ),
                              size: 30,
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                data['name'],
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Category'),
                                content: Text('Delete ${data['name']} ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('directory_categories')
                                  .doc(docs[index].id)
                                  .delete();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

IconData _getIcon(String icon) {
  switch (icon) {
    case 'school_rounded':
      return Icons.school_rounded;

    case 'local_hospital_rounded':
      return Icons.local_hospital_rounded;

    case 'directions_bus_rounded':
      return Icons.directions_bus_rounded;

    case 'account_balance_rounded':
      return Icons.account_balance_rounded;

    case 'store_rounded':
      return Icons.store_rounded;

    case 'travel_explore_rounded':
      return Icons.travel_explore_rounded;

    case 'restaurant_rounded':
      return Icons.restaurant_rounded;

    case 'home_rounded':
      return Icons.home_rounded;

    case 'directions_car_rounded':
      return Icons.directions_car_rounded;

    default:
      return Icons.folder;
  }
}

class _DirItem {
  final String title;
  final IconData icon;
  final Color color;
  const _DirItem(this.title, this.icon, this.color);
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
          colors: [Color(0xFFE65100), Color(0xFFFF6D00)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
