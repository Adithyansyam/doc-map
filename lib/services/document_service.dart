import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _documentsCollection => _firestore.collection('documents');

  // Add a new document
  Future<void> addDocument({
    required String title,
    required String description,
    String? processingTime,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _documentsCollection.add({
      'title': title,
      'description': description,
      'processingTime': processingTime,
      'createdBy': user.uid,
      'createdByEmail': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all documents stream (for all users)
  Stream<List<Map<String, dynamic>>> getAllDocumentsStream() {
    return _documentsCollection
        .orderBy('createdAt', descending: true)
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

  // Get a single document by ID
  Future<Map<String, dynamic>?> getDocumentById(String documentId) async {
    final doc = await _documentsCollection.doc(documentId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }
    return null;
  }

  // Update a document
  Future<void> updateDocument({
    required String documentId,
    required String title,
    required String description,
  }) async {
    await _documentsCollection.doc(documentId).update({
      'title': title,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a document
  Future<void> deleteDocument(String documentId) async {
    await _documentsCollection.doc(documentId).delete();
  }
}
