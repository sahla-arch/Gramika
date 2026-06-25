import 'package:flutter/material.dart';

import 'admin_issues_page.dart';
import 'superadmin_issues_page.dart';
import 'feedback_management_page.dart';

class ReportsFeedbackPage extends StatelessWidget {
  final bool isSuperAdmin;

  const ReportsFeedbackPage({super.key, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,

      child: Scaffold(
        appBar: AppBar(
          title: const Text("Reports & Feedback"),

          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.report_problem), text: "Issues"),

              Tab(icon: Icon(Icons.feedback), text: "Feedbacks"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            isSuperAdmin
                ? const SuperAdminIssuesPage()
                : const AdminIssuesPage(),

            const FeedbackManagementPage(),
          ],
        ),
      ),
    );
  }
}
