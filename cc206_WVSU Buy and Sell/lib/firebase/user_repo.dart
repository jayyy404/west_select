import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cc206_west_select/firebase/app_user.dart';

class UserRepo {
  final _firestore = FirebaseFirestore.instance;

  // Check if user is logging in for the first time
  Future<bool> isFirstTimeUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return !doc.exists;
  }

  // Add new user
  Future<void> addUser(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  // Update user details
  Future<void> updateUser(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toFirestore());
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // Get user details
  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc.data()!);
    }
    return null;
  }
}
