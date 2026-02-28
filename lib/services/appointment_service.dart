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

      // Generate sequential appointment number using a Firestore counter
      final int appointmentNumber = await _getNextAppointmentNumber();

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
        'appointmentNumber': appointmentNumber,
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

  /// Atomically increments and returns the next sequential appointment number.
  Future<int> _getNextAppointmentNumber() async {
    final counterRef = _firestore.collection('counters').doc('appointments');
    return _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterRef);
      int nextNumber;
      if (!snapshot.exists) {
        nextNumber = 1;
        transaction.set(counterRef, {'current': 1});
      } else {
        final current = (snapshot.data()?['current'] ?? 0) as int;
        nextNumber = current + 1;
        transaction.update(counterRef, {'current': nextNumber});
      }
      return nextNumber;
    });
  }

  /// Returns the sequential appointment number for an existing appointment.
  Future<int?> getAppointmentNumber(String appointmentId) async {
    try {
      final doc = await _appointmentsCollection.doc(appointmentId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['appointmentNumber'] as int?;
      }
      return null;
    } catch (_) {
      return null;
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

  /// Generates a modern, professionally styled PDF with appointment number
  /// and full center / user / appointment details.
  Future<Uint8List> createAppointmentPdf(Map<String, dynamic> appointment) async {
    final pdf = pw.Document();

    // ── resolve date ────────────────────────────────────────────────────
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

    String fmtShortDate(DateTime d) {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    // ── colours ─────────────────────────────────────────────────────────
    const accent      = PdfColors.amber;
    const accentDark  = PdfColors.amber800;
    const darkBg      = PdfColor.fromInt(0xFF1E293B); // slate-800
    const lightBg     = PdfColor.fromInt(0xFFF8FAFC); // slate-50
    const cardBorder  = PdfColor.fromInt(0xFFE2E8F0); // slate-200
    const textPrimary = PdfColor.fromInt(0xFF0F172A); // slate-900
    const textSecondary = PdfColor.fromInt(0xFF64748B); // slate-500

    // ── text styles ─────────────────────────────────────────────────────
    final titleStyle = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
    final subtitleStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey300);
    final sectionStyle = pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: accentDark, letterSpacing: 0.5);
    final labelStyle = pw.TextStyle(fontSize: 9.5, color: textSecondary);
    final valueStyle = pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: textPrimary);

    // ── appointment number ──────────────────────────────────────────────
    final rawNumber = appointment['appointmentNumber'];
    final int seqNumber = (rawNumber is int) ? rawNumber : 0;
    final appointmentNumber = seqNumber > 0 ? '#$seqNumber' : '#--';

    // ── address ─────────────────────────────────────────────────────────
    final addrParts = [
      appointment['address'] ?? '',
      appointment['city'] ?? '',
      appointment['state'] ?? '',
      appointment['pinCode'] ?? '',
    ].where((s) => (s as String).trim().isNotEmpty).toList();
    final fullAddress = addrParts.join(', ');

    final lat = appointment['latitude'];
    final lng = appointment['longitude'];
    final locationStr = (lat != null && lng != null) ? '$lat, $lng' : '';

    // ── helpers ─────────────────────────────────────────────────────────
    pw.Widget infoRow(String label, String value) {
      if (value.trim().isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 120, child: pw.Text(label, style: labelStyle)),
            pw.Expanded(child: pw.Text(value, style: valueStyle)),
          ],
        ),
      );
    }

    pw.Widget card({required String title, required List<pw.Widget> children}) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: cardBorder, width: 0.8),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(children: [
              pw.Container(width: 4, height: 14, color: accent),
              pw.SizedBox(width: 8),
              pw.Text(title, style: sectionStyle),
            ]),
            pw.SizedBox(height: 10),
            ...children,
          ],
        ),
      );
    }

    pw.Widget statBox(String label, String value) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: lightBg,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: cardBorder, width: 0.5),
          ),
          child: pw.Column(
            children: [
              pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: textPrimary)),
              pw.SizedBox(height: 4),
              pw.Text(label, style: pw.TextStyle(fontSize: 8.5, color: textSecondary)),
            ],
          ),
        ),
      );
    }

    // ── build page ──────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context ctx) {
          return pw.Column(
            children: [
              // ══════════ HEADER ══════════
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
                color: darkBg,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('AKSHAYA HUB', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: accent, letterSpacing: 2)),
                            pw.SizedBox(height: 4),
                            pw.Text('Appointment Confirmation', style: titleStyle),
                          ],
                        ),
                        // Appointment number badge
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: pw.BoxDecoration(
                            color: accent,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Text('APPOINTMENT NO.', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black, letterSpacing: 1)),
                              pw.SizedBox(height: 2),
                              pw.Text(appointmentNumber, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Booked on ${fmtDate(DateTime.now())}', style: subtitleStyle),
                  ],
                ),
              ),

              // ══════════ QUICK STATS BAR ══════════
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                color: lightBg,
                child: pw.Row(
                  children: [
                    statBox('DATE', fmtShortDate(appointmentDate)),
                    pw.SizedBox(width: 10),
                    statBox('TIME', appointment['appointmentTime'] ?? ''),
                    pw.SizedBox(width: 10),
                    statBox('STATUS', 'CONFIRMED'),
                  ],
                ),
              ),

              // ══════════ BODY ══════════
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                  child: pw.Column(
                    children: [
                      // Center Details card
                      card(title: 'CENTER DETAILS', children: [
                        infoRow('Center Name', appointment['centerName'] ?? ''),
                        infoRow('Reg. Number', appointment['registrationNumber'] ?? ''),
                        infoRow('Contact Person', appointment['contactPerson'] ?? ''),
                        infoRow('Phone', appointment['centerPhone'] ?? ''),
                        infoRow('Email', appointment['contactEmail'] ?? ''),
                        infoRow('Address', fullAddress),
                        infoRow('Coordinates', locationStr),
                      ]),

                      // Two-column row: User + Appointment
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: card(title: 'USER DETAILS', children: [
                              infoRow('Name', appointment['userName'] ?? ''),
                              infoRow('Email', appointment['userEmail'] ?? ''),
                              infoRow('Phone', appointment['userPhone'] ?? ''),
                            ]),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                            child: card(title: 'VISIT DETAILS', children: [
                              infoRow('Purpose', appointment['purpose'] ?? ''),
                              infoRow('Notes', appointment['notes'] ?? ''),
                            ]),
                          ),
                        ],
                      ),

                      pw.Spacer(),

                      // ══════════ FOOTER ══════════
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(vertical: 14),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: cardBorder, width: 0.5)),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'Thank you for booking with Akshaya Hub',
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: accentDark),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Please arrive 10 minutes before your scheduled time  |  Appointment No: $appointmentNumber',
                              style: pw.TextStyle(fontSize: 8, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
