import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> userWithEmailandPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      log("FirebaseException: ${e.message}");
    } catch (e) {
      log("Unexpected error: $e");
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      log("FirebaseException: ${e.message}");
      rethrow; // Rethrow to let LogInPage display the error message
    } catch (e) {
      log("Unexpected error: $e");
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        log("Google sign-in was cancelled by the user.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Check if email already has an email/password account
      final List<String> signInMethods =
          await _auth.fetchSignInMethodsForEmail(googleUser.email);

      if (signInMethods.contains('password')) {
        // If email/password account exists, sign in with email and password
        // Here, add logic to retrieve and input the stored password if available
        final UserCredential emailUser = await _auth.signInWithEmailAndPassword(
          email: googleUser.email,
          password: '<USER_KNOWN_PASSWORD>',
        );

        // Link Google account to email/password account
        await emailUser.user!.linkWithCredential(googleCredential);
        log("Google account linked to existing email/password account.");
        return emailUser.user;
      } else {
        // No email/password account exists; sign in directly with Google credentials
        final UserCredential googleUserCredential =
            await _auth.signInWithCredential(googleCredential);
        log("Google sign-in successful.");
        return googleUserCredential.user;
      }
    } catch (e) {
      log("Unexpected error during Google sign-in: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      log("User signed out.");
    } on FirebaseAuthException catch (e) {
      log("FirebaseException: ${e.message}");
    } catch (e) {
      log("Unexpected error: $e");
    }
  }
}
