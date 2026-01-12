import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CentreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Register a new centre
  Future<void> registerCentre({
    required String centreName,
    required String registrationNumber,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    required String contactPerson,
    required String contactPhone,
    required String contactEmail,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Save centre data to Firestore
      await _firestore.collection('centers').add({
        'centreName': centreName,
        'registrationNumber': registrationNumber,
        'address': address,
        'city': city,
        'state': state,
        'pinCode': pinCode,
        'contactPerson': contactPerson,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'latitude': latitude,
        'longitude': longitude,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, rejected
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to register centre: ${e.message}');
    } catch (e) {
      throw Exception('Failed to register centre: $e');
    }
  }

  // Get all centres for the current user
  Future<List<Map<String, dynamic>>> getUserCentres() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('centers')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to get centres: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get centres: $e');
    }
  }

  // Get a specific centre by ID
  Future<Map<String, dynamic>?> getCentreById(String centreId) async {
    try {
      final doc = await _firestore.collection('centers').doc(centreId).get();
      
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } on FirebaseException catch (e) {
      throw Exception('Failed to get centre: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get centre: $e');
    }
  }

  // Update centre information
  Future<void> updateCentre({
    required String centreId,
    required String centreName,
    required String registrationNumber,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    required String contactPerson,
    required String contactPhone,
    required String contactEmail,
  }) async {
    try {
      await _firestore.collection('centers').doc(centreId).update({
        'centreName': centreName,
        'registrationNumber': registrationNumber,
        'address': address,
        'city': city,
        'state': state,
        'pinCode': pinCode,
        'contactPerson': contactPerson,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to update centre: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update centre: $e');
    }
  }

  // Delete a centre
  Future<void> deleteCentre(String centreId) async {
    try {
      await _firestore.collection('centers').doc(centreId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete centre: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete centre: $e');
    }
  }

  // Stream of user's centres (for real-time updates)
  Stream<List<Map<String, dynamic>>> getUserCentresStream() {
    final user = currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('centers')
        .where('userId', isEqualTo: user.uid)
        // Removed orderBy temporarily - add back after creating Firebase index
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Get centres by status
  Future<List<Map<String, dynamic>>> getCentresByStatus(String status) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('centers')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to get centres by status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get centres by status: $e');
    }
  }

  // Get all centres stream (for map display)
  Stream<List<Map<String, dynamic>>> getAllCentersStream() {
    return _firestore
        .collection('centers')
        .where('status', isEqualTo: 'approved') // Only show approved centers on map
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }
}
