import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class UploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection reference
  CollectionReference get _uploadsCollection => _firestore.collection('uploads');

  /// Save document metadata to Firestore (no file upload to Storage).
  /// Also creates a validity expiry notification for the user.
  Future<void> saveDocument({
    required String title,
    required String fileName,
    required int fileSize,
    required DateTime validityDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Save metadata to Firestore
    await _uploadsCollection.add({
      'title': title,
      'fileName': fileName,
      'fileSize': fileSize,
      'validityDateEndsOn': Timestamp.fromDate(validityDate),
      'uploadedBy': user.uid,
      'uploadedByEmail': user.email,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all uploads for the current user as a stream.
  Stream<List<Map<String, dynamic>>> getUserUploadsStream() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _uploadsCollection
        .where('uploadedBy', isEqualTo: user.uid)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Get a single upload by ID.
  Future<Map<String, dynamic>?> getUploadById(String uploadId) async {
    final doc = await _uploadsCollection.doc(uploadId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }
    return null;
  }

  /// Delete an upload metadata from Firestore.
  Future<void> deleteUpload(String uploadId) async {
    await _uploadsCollection.doc(uploadId).delete();
  }

  /// Check all user documents for approaching/expired validity and
  /// create notifications if not already sent.
  Future<void> checkValidityExpiry() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final uploads = await _uploadsCollection
          .where('uploadedBy', isEqualTo: user.uid)
          .get();

      for (var doc in uploads.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final validityTimestamp = data['validityDateEndsOn'] as Timestamp?;
        if (validityTimestamp == null) continue;

        final validityDate = validityTimestamp.toDate();
        final daysUntilExpiry = validityDate.difference(now).inDays;

        // If validity has expired or expires within 2 days,
        // and notification hasn't been sent yet
        if (daysUntilExpiry <= 2 && data['expiryNotified'] != true) {
          await _notificationService.createValidityExpiryNotification(
            userId: user.uid,
            documentTitle: data['title'] ?? 'Untitled Document',
            documentId: doc.id,
            validityDate: validityDate,
          );

          // Mark as notified so we don't send duplicate notifications
          await _uploadsCollection.doc(doc.id).update({
            'expiryNotified': true,
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to check validity expiry: $e');
    }
  }
}
