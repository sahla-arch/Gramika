import 'package:flutter/material.dart';

class AdminNotificationSettingsPage extends StatefulWidget {
  const AdminNotificationSettingsPage({super.key});

  @override
  State<AdminNotificationSettingsPage> createState() =>
      _AdminNotificationSettingsPageState();
}

class _AdminNotificationSettingsPageState
    extends State<AdminNotificationSettingsPage> {
  bool notices = true;
  bool complaints = true;
  bool feedbacks = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Admin Notices"),
            value: notices,
            onChanged: (v) {
              setState(() => notices = v);
            },
          ),
          SwitchListTile(
            title: const Text("Complaints"),
            value: complaints,
            onChanged: (v) {
              setState(() => complaints = v);
            },
          ),
          SwitchListTile(
            title: const Text("Feedbacks"),
            value: feedbacks,
            onChanged: (v) {
              setState(() => feedbacks = v);
            },
          ),
        ],
      ),
    );
  }
}
