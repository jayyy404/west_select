import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      rethrow;
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

      final List<String> signInMethods =
          await _auth.fetchSignInMethodsForEmail(googleUser.email);

      if (signInMethods.contains('password')) {
        final UserCredential emailUser = await _auth.signInWithEmailAndPassword(
          email: googleUser.email,
          password: '<USER_KNOWN_PASSWORD>',
        );

        await emailUser.user!.linkWithCredential(googleCredential);
        log("Linked Google account to existing email/password account.");
        return emailUser.user;
      } else {
        final UserCredential googleUserCredential =
            await _auth.signInWithCredential(googleCredential);
        final user = googleUserCredential.user;
        await _promptUserToSetPassword(user);
        log("Google sign-in successful and password setup prompted.");
        return user;
      }
    } catch (e) {
      log("Unexpected error during Google sign-in: $e");
      return null;
    }
  }

  Future<void> _promptUserToSetPassword(User? user) async {
    if (user != null) {
      await user.updatePassword('<NEW_PASSWORD>');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      log("User signed out.");
    } on FirebaseAuthException catch (e) {
      log("FirebaseException: ${e.message}");
    } catch (e) {
      log("Unexpected error: $e");
    }
  }
}
