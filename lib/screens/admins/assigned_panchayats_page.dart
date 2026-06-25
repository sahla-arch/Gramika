import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignedPanchayatsPage extends StatelessWidget {
  const AssignedPanchayatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(title: const Text("Assigned Panchayats")),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Panchayats Assigned"));
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

          final panchayats = List<String>.from(
            data['assignedPanchayats'] ?? [],
          );

          return ListView.builder(
            itemCount: panchayats.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(panchayats[index]),
              );
            },
          );
        },
      ),
    );
  }
}
