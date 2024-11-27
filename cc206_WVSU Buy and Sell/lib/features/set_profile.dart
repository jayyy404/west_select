import 'package:cc206_west_select/features/screens/main_page.dart';
import 'package:flutter/material.dart';
import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:cc206_west_select/firebase/user_repo.dart';

class SetupProfilePage extends StatelessWidget {
  final AppUser user;

  SetupProfilePage({super.key, required this.user});

  final _displayNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final updatedUser = AppUser(
                  uid: user.uid,
                  email: user.email,
                  displayName: _displayNameController.text,
                  profilePictureUrl: user.profilePictureUrl,
                );
                await UserRepo().addUser(updatedUser);
                // Get this from FirebaseAuth.currentUser.uid
                final appUser = await UserRepo().getUser(user.uid);

                // Pass the fetched user to MainPage
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainPage(appUser: appUser),
                  ),
                );
              },
              child: const Text('Save and Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
