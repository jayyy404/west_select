import 'package:cc206_west_select/features/Homepage/home_page.dart';
import 'package:cc206_west_select/features/Homepage/profile_page.dart';
import 'package:cc206_west_select/firebase/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  _LogInPageState createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  void _validateAndSignIn() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email!';
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
      final user =
          await AuthService().loginUserWithEmailAndPassword(email, password);
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LogInPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() {
          _errorMessage = 'User not found. Please check your email or sign up.';
        });
      } else if (e.code == 'wrong-password') {
        setState(() {
          _errorMessage = 'Wrong password. Please try again.';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to sign in. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
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

            // Email TextField
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Password TextField
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Error message
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

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: "Raleway",
                  ),
                ),
              ),
            ),

            // Sign In Button (adjusted position)
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
            const SizedBox(height: 30),

            // Divider and Social Login Text
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
                  onPressed: () async {
                    try {
                      final user = await AuthService().signInWithGoogle();
                      if (user != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomePage()),
                        );
                      }
                    } catch (e) {
                      setState(() {
                        _errorMessage = 'Google sign-in failed. Try again.';
                      });
                    }
                  },
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
