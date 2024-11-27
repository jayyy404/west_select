import 'package:cc206_west_select/features/screens/main_page.dart';
import 'package:cc206_west_select/features/screens/profile/profile_page.dart';
import 'package:cc206_west_select/features/set_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../firebase/auth_service.dart';
import '../firebase/user_repo.dart';
import 'sign_up.dart';
import 'package:cc206_west_select/firebase/app_user.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  _LogInPageState createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isPasswordVisible = false;

  // Email format validation
  bool isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Clear error message when user starts typing
  void _onEmailChanged(String value) {
    setState(() {
      _errorMessage = null;
    });
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _errorMessage = null;
    });
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  // Validate email and password, then sign in
  void _validateAndSignIn() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email!';
      });
      return;
    }

    if (!isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address!';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password!';
      });
      return;
    }

    try {
      // Attempt to login with email and password
      final user =
          await AuthService().loginUserWithEmailAndPassword(email, password);

      if (user != null) {
        final isFirstTime = await UserRepo().isFirstTimeUser(user.uid);
        if (isFirstTime) {
          final customUser = AppUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            profilePictureUrl: user.photoURL ?? '',
          );
        } else {
          // Get this from FirebaseAuth.currentUser.uid
          final appUser = await UserRepo().getUser(user.uid);

          if (appUser != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(appUser: appUser),
              ),
            );
          } else {
            setState(() {
              _errorMessage = 'User data is missing. Please try again.';
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to sign in. Please check your credentials.';
        });
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth exceptions
      if (e.code == 'user-not-found') {
        // Check if the email is associated with a Google account
        try {
          final result = await AuthService().checkIfEmailIsGoogleAccount(email);
          if (result) {
            setState(() {
              _errorMessage =
                  'This email is associated with a Google account. Please sign in with Google.';
            });
          } else {
            setState(() {
              _errorMessage =
                  'User not found. Please check your email or sign up.';
            });
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'Error checking account type. Please try again.';
          });
        }
      } else if (e.code == 'wrong-password') {
        setState(() {
          _errorMessage = 'Wrong password. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to sign in. Please check your email and password.';
      });
    }
  }

  // Sign in using Google and link with email/password if needed
  void _signInWithGoogle() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final user = await AuthService().signInWithGoogle(email, password);

      if (user != null) {
        final isFirstTime = await UserRepo().isFirstTimeUser(user.uid);
        if (isFirstTime) {
          final customUser = AppUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            profilePictureUrl: user.photoURL ?? '',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => SetupProfilePage(user: customUser)),
          );
        } else {
          // Get this from FirebaseAuth.currentUser.uid
          final appUser = await UserRepo().getUser(user.uid);

          if (appUser != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainPage(appUser: appUser),
              ),
            );
          } else {
            setState(() {
              _errorMessage = 'User data is missing. Please try again.';
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Google sign-in failed. Try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed. Try again.';
      });
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
              'West Select',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Raleway",
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Shop at Taga West – Only the Best!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Raleway",
                fontSize: 16,
                color: Color.fromARGB(255, 43, 42, 1),
              ),
            ),
            const SizedBox(height: 100),
            TextField(
              controller: _emailController,
              onChanged: _onEmailChanged,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              onChanged: _onPasswordChanged,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: "Raleway",
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {}, // Forgot password functionality
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: "Raleway",
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(66, 21, 181, 1),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(
                    fontFamily: "Raleway",
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account yet?",
                  style: TextStyle(fontFamily: "Raleway"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      color: Colors.blue,
                      fontFamily: "Raleway",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Login With',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Raleway",
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  icon: Image.asset('assets/google.png'),
                  iconSize: 24,
                  onPressed: _signInWithGoogle,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
