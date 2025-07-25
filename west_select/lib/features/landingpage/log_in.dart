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

  void _openTermsPage(String fileName, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TermsPage(fileName: fileName, title: title),
      ),
    );
  }

  Future<bool> _showTermsAndPrivacyDialog() async {
    bool agreedTerms = false;
    bool agreedPrivacy = false;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool canAgree = agreedTerms && agreedPrivacy;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Terms & Privacy Policy',
                style: TextStyle(
                  fontFamily: "Raleway",
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Please read and agree to continue:',
                    style: TextStyle(
                      fontFamily: "Raleway",
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Terms & Conditions
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: agreedTerms,
                    onChanged: (value) async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TermsPage(
                            fileName: 'tandc.html',
                            title: 'Terms & Conditions',
                          ),
                        ),
                      );
                      setState(() {
                        agreedTerms = true;
                      });
                    },
                    title: const Text(
                      'I have read the Terms & Conditions',
                      style: TextStyle(
                        fontFamily: "Raleway",
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // Privacy Policy
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: agreedPrivacy,
                    onChanged: (value) async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TermsPage(
                            fileName: 'privacypolicy.html',
                            title: 'Privacy Policy',
                          ),
                        ),
                      );
                      setState(() {
                        agreedPrivacy = true;
                      });
                    },
                    title: const Text(
                      'I have read the Privacy Policy',
                      style: TextStyle(
                        fontFamily: "Raleway",
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontFamily: "Raleway"),
                  ),
                ),
                ElevatedButton(
                  onPressed: canAgree
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'I Agree',
                    style: TextStyle(fontFamily: "Raleway"),
                  ),
                ),
              ],
            );
          },
        );
      },
    ) ?? false;
  }

  // Sign in using Google
  void _signInWithGoogle() async {
    try {
      final user = await AuthService().signInWithGoogle('', '');

      if (user != null) {
        final isFirstTime = await UserRepo().isFirstTimeUser(user.uid);
        if (isFirstTime) {
          final agreed = await _showTermsAndPrivacyDialog();
          if (agreed) {
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
            await AuthService().signOut();
            setState(() {
              _errorMessage = 'You must accept the Terms & Privacy Policy to continue.';
            });
          }
        }
        else {
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
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: "Raleway",
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        children: [
                          const TextSpan(text: 'By continuing, you agree to our\n'),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: const TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _openTermsPage('tandc.html', 'Terms & Conditions');
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
                                _openTermsPage('privacypolicy.html', 'Privacy Policy');
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                  // Error message display
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
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
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
