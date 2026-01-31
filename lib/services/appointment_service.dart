import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection reference
  CollectionReference get _appointmentsCollection =>
      _firestore.collection('appointments');

  // Book a new appointment
  Future<String> bookAppointment({
    required String centerId,
    required String centerName,
    required String centerAddress,
    required String centerPhone,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String purpose,
    String? notes,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user details
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data();

      // Get center details to find owner ID
      final centerDoc = await _firestore.collection('centers').doc(centerId).get();
      final centerData = centerDoc.data();
      final centerOwnerId = centerData?['ownerId'] ?? centerData?['userId'] ?? '';

      final appointmentData = {
        'userId': currentUserId,
        'userName': userData?['name'] ?? 'Unknown User',
        'userEmail': userData?['email'] ?? _auth.currentUser?.email,
        'userPhone': userData?['phone'] ?? '',
        'centerId': centerId,
        'centerName': centerName,
        'centerAddress': centerAddress,
        'centerPhone': centerPhone,
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'appointmentTime': appointmentTime,
        'purpose': purpose,
        'notes': notes ?? '',
        'status': 'pending', // pending, confirmed, completed, cancelled
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _appointmentsCollection.add(appointmentData);
      
      // Create notification for center owner
      if (centerOwnerId.isNotEmpty) {
        await _notificationService.createAppointmentNotification(
          centerId: centerId,
          centerOwnerId: centerOwnerId,
          centerName: centerName,
          userName: userData?['name'] ?? 'Unknown User',
          appointmentId: docRef.id,
          appointmentDate: appointmentDate,
          appointmentTime: appointmentTime,
          purpose: purpose,
        );
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to book appointment: $e');
    }
  }

  // Get user's appointments stream
  Stream<List<Map<String, dynamic>>> getUserAppointmentsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _appointmentsCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Get upcoming appointments
  Stream<List<Map<String, dynamic>>> getUpcomingAppointmentsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _appointmentsCollection
        .where('userId', isEqualTo: currentUserId)
        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.now())
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('appointmentDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Get past appointments
  Stream<List<Map<String, dynamic>>> getPastAppointmentsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _appointmentsCollection
        .where('userId', isEqualTo: currentUserId)
        .where('appointmentDate', isLessThan: Timestamp.now())
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Reschedule appointment
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
  }) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'appointmentDate': Timestamp.fromDate(newDate),
        'appointmentTime': newTime,
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  // Get appointment by ID
  Future<Map<String, dynamic>?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _appointmentsCollection.doc(appointmentId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get appointment: $e');
    }
  }

  // Check if time slot is available
  Future<bool> isTimeSlotAvailable({
    required String centerId,
    required DateTime date,
    required String time,
  }) async {
    try {
      final count = await getTimeSlotBookingCount(
        centerId: centerId,
        date: date,
        time: time,
      );
      return count < 20; // Max 20 bookings per 30-minute slot
    } catch (e) {
      return true; // Allow booking if check fails
    }
  }

  // Get booking count for a specific time slot
  Future<int> getTimeSlotBookingCount({
    required String centerId,
    required DateTime date,
    required String time,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingAppointments = await _appointmentsCollection
          .where('centerId', isEqualTo: centerId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('appointmentTime', isEqualTo: time)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return existingAppointments.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get all time slot booking counts for a date
  Future<Map<String, int>> getAllTimeSlotCounts({
    required String centerId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final appointments = await _appointmentsCollection
          .where('centerId', isEqualTo: centerId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      final Map<String, int> counts = {};
      for (var doc in appointments.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final time = data['appointmentTime'] as String?;
        if (time != null) {
          counts[time] = (counts[time] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      return {};
    }
  }

  // Approve appointment
  Future<void> approveAppointment(String appointmentId) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to approve appointment: $e');
    }
  }

  // Reject appointment
  Future<void> rejectAppointment(String appointmentId, {String? reason}) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'status': 'rejected',
        'rejectionReason': reason ?? 'Rejected by center',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject appointment: $e');
    }
  }

  // Get appointment status
  Future<String?> getAppointmentStatus(String appointmentId) async {
    try {
      final doc = await _appointmentsCollection.doc(appointmentId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
