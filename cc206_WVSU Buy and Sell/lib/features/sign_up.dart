import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'log_in.dart';
import 'package:cc206_west_select/features/Homepage/home_page.dart';
import 'package:cc206_west_select/features/Homepage/profile_page.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // Sign out from any existing Google session
      await GoogleSignIn().signOut();

      // Start the Google Sign-In process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      }
    } catch (e) {
      print('Error signing in with Google: $e');
    }
  }

  Future<void> signInWithFacebook(BuildContext context) async {
    try {
      // Trigger the Facebook Sign-in flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Get the Facebook access token
        final AccessToken? accessToken = result.accessToken;

        if (accessToken != null) {
          // Create a Facebook Auth credential using the access token string
          final AuthCredential credential =
              FacebookAuthProvider.credential(accessToken.tokenString);

          // Sign in to Firebase with the Facebook credentials
          UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);
          User? user = userCredential.user;

          if (user != null) {
            // Navigate to HomePage after successful sign-in
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      } else {
        print('Facebook login failed: ${result.message}');
      }
    } catch (e) {
      print('Error signing in with Facebook: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 251, 245, 1),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              color: Color.fromRGBO(66, 21, 181, 1),
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Create a new account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Raleway",
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => signInWithGoogle(context),
              icon: const Icon(Icons.account_circle, color: Colors.blue),
              label: const Text(
                'Sign up with Google',
                style: TextStyle(fontFamily: "Raleway", fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => signInWithFacebook(context),
              icon: const Icon(Icons.facebook, color: Colors.blueAccent),
              label: const Text(
                'Sign up with Facebook',
                style: TextStyle(fontFamily: "Raleway", fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LogInPage()),
                );
              },
              child: const Text(
                'Already have an account? Sign in here',
                style: TextStyle(
                  fontFamily: "Raleway",
                  fontSize: 16,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
