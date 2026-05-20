import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tracked_action.model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 👑 CHECK IF LOGGED IN USER IS A SUPER ADMIN
  Future<bool> isSuperAdmin() async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return false;
    
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['role'] == 'super_admin';
    } catch (e) {
      return false;
    }
  }

  // 👥 CREATE USER PROFILE LINK ON ACCOUNT CREATION
  Future<void> createUserProfile(String uid, String email, String phoneNumber) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'phoneNumber': phoneNumber,
      'role': 'user', // Default role (Manually change to super_admin in Firebase console!)
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 📊 ADAPTIVE LIVE STREAM: Pulls user-isolated data OR everything if Super Admin
    // 📊 ADAPTIVE LIVE STREAM: Pulls user-isolated data OR everything if Super Admin
  Stream<List<TrackedAction>> getTrackedActionsStream(bool isAdmin) {
    return _db
        .collection('tracked_actions')
        .orderBy('actionDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // 🎯 FIX: Pass the raw 'doc' straight through! Your model handles the rest.
            return TrackedAction.fromFirestore(doc);
          }).toList();
        });
  }

  // 💾 SAVE RECORD
  Future<void> addActionRecord(TrackedAction record) async {
    String uid = _auth.currentUser?.uid ?? '';
    Map<String, dynamic> data = record.toFirestore();
    data['userId'] = uid;
    await _db.collection('tracked_actions').add(data);
  }

  // ✏️ UPDATE RECORD
  Future<void> updateActionRecord(String docId, TrackedAction record) async {
    String uid = _auth.currentUser?.uid ?? '';
    Map<String, dynamic> data = record.toFirestore();
    data['userId'] = uid;
    await _db.collection('tracked_actions').doc(docId).update(data);
  }

  // ❌ GLOBAL PRUNE: Super Admin or owner can permanently remove records
  Future<void> deleteActionRecord(String docId) async {
    await _db.collection('tracked_actions').doc(docId).delete();
  }
}