import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if the email is associated with a Google account
  Future<bool> checkIfEmailIsGoogleAccount(String email) async {
    final userMethods = await _auth.fetchSignInMethodsForEmail(email);
    return userMethods.contains('google.com');
  }

  // Sign in with Email and Password and register if new
  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      if (!_isValidEmail(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email-format',
          message: 'Please enter a valid email address.',
        );
      }

      final userMethods = await _auth.fetchSignInMethodsForEmail(email);

      if (userMethods.contains('google.com')) {
        throw FirebaseAuthException(
            code: 'google-account-detected',
            message:
                'This email is associated with a Google account. Please sign in with Google.');
      }

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Register a new user if not found
        return await createUserWithEmailAndPassword(email, password);
      } else if (e.code == 'wrong-password') {
        throw FirebaseAuthException(
            code: 'wrong-password', message: 'Wrong password.');
      }
      throw e;
    }
  }

  // Create new user with email and password
  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
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

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
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
