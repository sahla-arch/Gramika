import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,

      'title': title,

      'message': message,

      'read': false,

      'createdAt': Timestamp.now(),
    });
  }
}
