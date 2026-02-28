import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// PDF generation
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

  // Get user details by UID (used by the PDF generator)
  Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return doc.data();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Generates a professional PDF document with full center and appointment
  /// details. The [appointment] map should contain center fields (centerName,
  /// registrationNumber, address, city, state, pinCode, contactPerson,
  /// centerPhone, contactEmail, latitude, longitude) as well as appointment
  /// fields (appointmentDate, appointmentTime, purpose, notes).
  Future<Uint8List> createAppointmentPdf(Map<String, dynamic> appointment) async {
    final pdf = pw.Document();

    // --- resolve date ---
    DateTime appointmentDate;
    final rawDate = appointment['appointmentDate'];
    if (rawDate is Timestamp) {
      appointmentDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      appointmentDate = rawDate;
    } else {
      appointmentDate = DateTime.now();
    }

    String fmtDate(DateTime d) {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
      return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
    }

    // --- helpers ---
    final headerStyle = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold);
    final sectionStyle = pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800);
    final labelStyle = pw.TextStyle(fontSize: 11, color: PdfColors.grey700);
    final valueStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    pw.Widget infoRow(String label, String value) {
      if (value.trim().isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 140,
              child: pw.Text(label, style: labelStyle),
            ),
            pw.Expanded(child: pw.Text(value, style: valueStyle)),
          ],
        ),
      );
    }

    pw.Widget sectionTitle(String title) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: sectionStyle),
            pw.Divider(thickness: 0.5),
          ],
        ),
      );
    }

    // --- build full address string ---
    final parts = [
      appointment['address'] ?? '',
      appointment['city'] ?? '',
      appointment['state'] ?? '',
      appointment['pinCode'] ?? '',
    ].where((s) => (s as String).trim().isNotEmpty).toList();
    final fullAddress = parts.join(', ');

    // --- latitude / longitude ---
    final lat = appointment['latitude'];
    final lng = appointment['longitude'];
    final locationStr = (lat != null && lng != null) ? '$lat, $lng' : '';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Center(
                child: pw.Text('Appointment Confirmation', style: headerStyle),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Booked on ${fmtDate(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),

              // ---- Center Details ----
              sectionTitle('Center Details'),
              infoRow('Center Name', appointment['centerName'] ?? ''),
              infoRow('Registration No.', appointment['registrationNumber'] ?? ''),
              infoRow('Contact Person', appointment['contactPerson'] ?? ''),
              infoRow('Phone', appointment['centerPhone'] ?? ''),
              infoRow('Email', appointment['contactEmail'] ?? ''),
              infoRow('Address', fullAddress),
              infoRow('Coordinates', locationStr),

              // ---- User Details ----
              sectionTitle('User Details'),
              infoRow('Name', appointment['userName'] ?? ''),
              infoRow('Email', appointment['userEmail'] ?? ''),
              infoRow('Phone', appointment['userPhone'] ?? ''),

              // ---- Appointment Details ----
              sectionTitle('Appointment Details'),
              infoRow('Date', fmtDate(appointmentDate)),
              infoRow('Time', appointment['appointmentTime'] ?? ''),
              infoRow('Purpose', appointment['purpose'] ?? ''),
              infoRow('Notes', appointment['notes'] ?? ''),

              pw.SizedBox(height: 30),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Thank you for booking with Akshaya Hub',
                  style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
