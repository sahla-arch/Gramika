import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool notices = true;
  bool complaints = true;
  bool jobs = true;
  bool emergency = true;
  bool faqReplies = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Preferences")),

      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Complaint Updates"),
            subtitle: const Text("Status changes and replies"),
            value: complaints,
            onChanged: (value) {
              setState(() {
                complaints = value;
              });
            },
          ),

          SwitchListTile(
            title: const Text("FAQ Responses"),
            subtitle: const Text("Answers from admins"),
            value: faqReplies,
            onChanged: (value) {
              setState(() {
                faqReplies = value;
              });
            },
          ),

          SwitchListTile(
            title: const Text("Panchayat Notices"),
            subtitle: const Text("Public announcements"),
            value: notices,
            onChanged: (value) {
              setState(() {
                notices = value;
              });
            },
          ),

          SwitchListTile(
            title: const Text("Job Alerts"),
            subtitle: const Text("Vacancies and opportunities"),
            value: jobs,
            onChanged: (value) {
              setState(() {
                jobs = value;
              });
            },
          ),

          SwitchListTile(
            title: const Text("Emergency Alerts"),
            subtitle: const Text("Urgent notifications"),
            value: emergency,
            onChanged: (value) {
              setState(() {
                emergency = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
