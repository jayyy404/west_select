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
    } catch (e) {
      rethrow; // Rethrow the error to be caught in your LogInPage
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      await _auth.signOut(); // Sign out any previous sessions

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      log("Google Access Token: ${googleAuth.accessToken}");
      log("Google ID Token: ${googleAuth.idToken}");

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      log("Error signing in with Google: $e");
      return null;
    }
  }

  // Sign in with Facebook
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken? accessToken = result.accessToken;

        if (accessToken != null) {
          final AuthCredential credential =
              FacebookAuthProvider.credential(accessToken.tokenString);
          final UserCredential userCredential =
              await _auth.signInWithCredential(credential);
          return userCredential.user;
        }
      } else {
        log("Facebook login failed: ${result.message}");
      }
    } catch (e) {
      log("Error signing in with Facebook: $e");
      return null;
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut(); // Sign out from Google
      log("User signed out from Google.");
    } on FirebaseAuthException catch (e) {
      log("FirebaseException: ${e.message}");
    } catch (e) {
      log("Unexpected error: $e");
    }
  }
}
