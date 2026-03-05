import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class UploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
  CollectionReference get _uploadsCollection => _firestore.collection('uploads');

  /// Upload a file to Firebase Storage and save metadata to Firestore.
  /// [onProgress] callback provides upload progress (0.0 to 1.0).
  /// Returns the download URL on success.
  Future<String> uploadDocument({
    required PlatformFile selectedFile,
    required String title,
    required DateTime validityDate,
    void Function(double progress)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final file = File(selectedFile.path!);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${selectedFile.name}';
    final storageRef =
        _storage.ref().child('uploads/${user.uid}/$fileName');

    // Upload file to Firebase Storage
    final uploadTask = storageRef.putFile(file);

    // Listen to progress events
    uploadTask.snapshotEvents.listen((event) {
      final progress =
          event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
      onProgress?.call(progress);
    });

    // Wait for upload to complete
    await uploadTask;
    final downloadUrl = await storageRef.getDownloadURL();

    // Save metadata to Firestore
    await _uploadsCollection.add({
      'title': title,
      'fileName': selectedFile.name,
      'fileUrl': downloadUrl,
      'fileSize': selectedFile.size,
      'validityDateEndsOn': validityDate,
      'uploadedBy': user.uid,
      'uploadedByEmail': user.email,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    return downloadUrl;
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

  /// Get all uploads (for admins or shared view).
  Stream<List<Map<String, dynamic>>> getAllUploadsStream() {
    return _uploadsCollection
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

  /// Delete an upload (both file from Storage and metadata from Firestore).
  Future<void> deleteUpload(String uploadId) async {
    final doc = await _uploadsCollection.doc(uploadId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      // Delete file from Storage
      try {
        final fileUrl = data['fileUrl'] as String?;
        if (fileUrl != null) {
          await _storage.refFromURL(fileUrl).delete();
        }
      } catch (_) {
        // File may already be deleted from storage
      }
      // Delete metadata from Firestore
      await _uploadsCollection.doc(uploadId).delete();
    }
  }
}
