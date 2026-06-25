import 'package:flutter/material.dart';
import 'job_services_management_pg.dart';
import 'job_vacancies_management_pg.dart';
import 'job_applications_management_pg.dart';

class JobManagementPage extends StatelessWidget {
  const JobManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,

      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          title: const Text("Jobs Management"),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,

          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_search), text: "Service Providers"),
              Tab(icon: Icon(Icons.work), text: "Job Vacancies"),
              Tab(icon: Icon(Icons.assignment), text: "Applications"),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            JobServicesManagementPage(),
            JobVacanciesManagementPage(),
            JobApplicationsManagementPage(),
          ],
        ),
      ),
    );
  }
}
