import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  // Create notification for center owner when appointment is booked
  Future<void> createAppointmentNotification({
    required String centerId,
    required String centerOwnerId,
    required String centerName,
    required String userName,
    required String appointmentId,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String purpose,
  }) async {
    try {
      await _notificationsCollection.add({
        'centerId': centerId,
        'centerOwnerId': centerOwnerId,
        'type': 'appointment_booked',
        'title': 'New Appointment Booking',
        'message': '$userName has booked an appointment for ${_formatDate(appointmentDate)} at $appointmentTime',
        'appointmentId': appointmentId,
        'userName': userName,
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'appointmentTime': appointmentTime,
        'purpose': purpose,
        'centerName': centerName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't fail the appointment booking
      print('Failed to create notification: $e');
    }
  }

  // Get notifications for center owner
  Stream<List<Map<String, dynamic>>> getCenterNotificationsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _notificationsCollection
        .where('centerOwnerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCountStream() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _notificationsCollection
        .where('centerOwnerId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _notificationsCollection
          .where('centerOwnerId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _notificationsCollection
          .where('centerOwnerId', isEqualTo: currentUserId)
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
