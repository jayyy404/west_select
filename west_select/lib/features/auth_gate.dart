import 'package:cc206_west_select/features/log_in.dart';
import 'package:cc206_west_select/features/screens/main_page.dart';
import 'package:cc206_west_select/firebase/user_repo.dart';
import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Fetch user data and redirect to MainPage
      return FutureBuilder<AppUser?>(
        future: UserRepo().getUser(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return MainPage(appUser: snapshot.data!);
          } else {
            return const LogInPage();
          }
        },
      );
    } else {
      return const LogInPage();
    }
  }
}
