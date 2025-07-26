import 'package:cc206_west_select/features/navigation/nav_bar.dart';
import 'package:cc206_west_select/features/set_profile.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import '../../../firebase/auth_service.dart';
import '../../../firebase/user_repo.dart';
import 'terms_page.dart';
import 'package:cc206_west_select/firebase/app_user.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  LogInPageState createState() => LogInPageState();
}

class LogInPageState extends State<LogInPage> {
  String? _errorMessage;
  bool _isTermsAccepted = false;
  bool _isReturningUser = false;
  bool _isCheckingUserStatus = false;

  @override
  void initState() {
    super.initState();
    _checkIfReturningUser();
  }

  Future<void> _checkIfReturningUser() async {
    setState(() {
      _isCheckingUserStatus = true;
    });
    try {
      final currentUser = AuthService().getCurrentUser();
      bool isReturningUser = false;

      if (currentUser != null) {
        final isFirstTime = await UserRepo().isFirstTimeUser(currentUser.uid);
        isReturningUser = !isFirstTime;
      } else {
        isReturningUser = await AuthService().hasAcceptedTermsBefore();
      }
      setState(() {
        _isReturningUser = isReturningUser;
        _isTermsAccepted = isReturningUser;
      });
    } catch (e) {
      // If there's an error, treat as new user
      setState(() {
        _isReturningUser = false;
        _isTermsAccepted = false;
      });
    } finally {
      setState(() {
        _isCheckingUserStatus = false;
      });
    }
  }

  void _openTermsPage(String fileName, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TermsPage(fileName: fileName, title: title),
      ),
    );
  }

  // Sign in using Google
  void _signInWithGoogle() async {
    if (!_isReturningUser && !_isTermsAccepted) {
      setState(() {
        _errorMessage = 'Please accept the Terms & Privacy Policy to continue.';
      });
      return;
    }
    try {
      final user = await AuthService().signInWithGoogle('', '');
      if (user != null) {
        // Mark that this device has accepted terms
        await AuthService().markTermsAccepted();
        final isFirstTime = await UserRepo().isFirstTimeUser(user.uid);
        if (isFirstTime) {
          final customUser = AppUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            profilePictureUrl: user.photoURL ?? '',
            orderHistory: [],
            userListings: [],
            fcmTokens: [],
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
      body: Stack(
        children: [
          // Background image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/landing_page.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Mask overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/mask_landing.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content container
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  const SizedBox(height: 1),
                  const Spacer(flex: 1),
                  const Text(
                    'WestSelect',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Raleway",
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'SHOP TAGA WEST\nONLY THE BEST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Raleway",
                      fontSize: 35,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 250),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Transform.scale(
                              scale: 0.9,
                              child: Checkbox(
                                value: _isTermsAccepted,
                                onChanged: _isReturningUser
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _isTermsAccepted = value ?? false;
                                          if (_errorMessage != null) {
                                            _errorMessage = null;
                                          }
                                        });
                                      },
                                fillColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                    if (_isReturningUser) {
                                      return Colors.green;
                                    }
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.white;
                                    }
                                    return Colors.transparent;
                                  },
                                ),
                                checkColor: _isReturningUser
                                    ? Colors.white
                                    : Colors.black,
                                side: const BorderSide(
                                    color: Colors.white, width: 2),
                              ),
                            ),
                            // Terms text
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: "Raleway",
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                  children: [
                                    const TextSpan(
                                        text:
                                            'By continuing, you agree to our\n'),
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: const TextStyle(
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w500),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _openTermsPage('tandc.html',
                                              'Terms & Conditions');
                                        },
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w500),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _openTermsPage('privacypolicy.html',
                                              'Privacy Policy');
                                        },
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: "Raleway",
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Continue with Google Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _isCheckingUserStatus ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isCheckingUserStatus
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black87),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/google.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontFamily: "Raleway",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
