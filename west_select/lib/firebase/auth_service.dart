import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cc206_west_select/features/screens/favorite/favorite_model.dart'
    as fav;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if the email is associated with a Google account
  Future<bool> checkIfEmailIsGoogleAccount(String email) async {
    final userMethods = await _auth.fetchSignInMethodsForEmail(email);
    return userMethods.contains('google.com');
  }

  // Sign in with Google and link with email/password if needed
  Future<User?> signInWithGoogle(String? email, String password) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'google-signin-cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(googleCredential);
      User? user = userCredential.user;

      // If email/password login is also required, link the account
      if (email != null && password.isNotEmpty) {
        await linkEmailWithPassword(user!, email, password);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  // Link Google account with email/password credential
  Future<void> linkEmailWithPassword(
      User user, String email, String password) async {
    try {
      AuthCredential credential =
          EmailAuthProvider.credential(email: email, password: password);
      await user.linkWithCredential(credential);
      print("Successfully linked Google account with email/password login!");
    } catch (e) {
      print("Error linking Google account with email/password: $e");
    }
  }

  Future<void> removeFcmToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();

    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayRemove([token])
    });
  }

  // Sign out
  Future<void> signOut() async {
    fav.FavoriteModel().clearFavorites();
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await removeFcmToken(currentUser.uid);
    }
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> deleteUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Delete conversations where the user is a participant
      final conversations = await firestore
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .get();
      for (var doc in conversations.docs) {
        await doc.reference.delete();
      }

      // 2. Delete favorites document
      await firestore.collection('favorites').doc(uid).delete();

      // 3. Delete notifications where userId == uid
      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }

      // 4. Delete orders where buyerId == uid
      final orders = await firestore
          .collection('orders')
          .where('buyerId', isEqualTo: uid)
          .get();
      for (var doc in orders.docs) {
        await doc.reference.delete();
      }

      // 5. Delete posts where post_users contains uid
      final posts = await firestore
          .collection('post')
          .where('post_users', arrayContains: uid)
          .get();
      for (var doc in posts.docs) {
        await doc.reference.delete();
      }

      // 6. Delete the user document
      await firestore.collection('users').doc(uid).delete();

      // 7. Delete the Firebase Auth user
      await user.delete();

      debugPrint('User account and associated data deleted successfully.');
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Helper function to validate email format
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }
}
