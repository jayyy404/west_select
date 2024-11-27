import 'package:flutter/material.dart';
import 'package:cc206_west_select/firebase/auth_service.dart';
import 'package:cc206_west_select/features/log_in.dart';
import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:cc206_west_select/firebase/user_repo.dart';

class ProfilePage extends StatefulWidget {
  final AppUser appUser;

  const ProfilePage({super.key, required this.appUser});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int selectedTabIndex = 0;

  Future<void> _signOut() async {
    await AuthService().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LogInPage()),
    );
  }

  Future<void> _editDisplayName() async {
    final TextEditingController editNameController =
        TextEditingController(text: widget.appUser.displayName ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Display Name'),
          content: TextField(
            controller: editNameController,
            decoration: const InputDecoration(labelText: 'Display Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = editNameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Display name cannot be empty'),
                    ),
                  );
                  return;
                }

                final updatedUser = AppUser(
                  uid: widget.appUser.uid,
                  email: widget.appUser.email,
                  displayName: newName,
                  profilePictureUrl: widget.appUser.profilePictureUrl,
                );

                await UserRepo().addUser(updatedUser);

                setState(() {
                  widget.appUser.displayName = newName;
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name updated successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.appUser.profilePictureUrl != null
                      ? NetworkImage(widget.appUser.profilePictureUrl!)
                          as ImageProvider
                      : null,
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appUser.displayName ?? "User's Name",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _editDisplayName,
                        child: const Text('Edit Name'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton("Listing", 0),
                _buildTabButton("Pending", 1),
                _buildTabButton("Completed", 2),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                itemCount: getCurrentTabData().length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final item = getCurrentTabData()[index];
                  return Card(
                    child: Column(
                      children: [
                        Image.network(item['imageUrl']!, fit: BoxFit.cover),
                        const SizedBox(height: 5),
                        Text(item['title']!),
                        Text(item['price']!),
                        Text('Seller: ${item['seller']}'),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Sign Out
            ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTabIndex = index;
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selectedTabIndex == index ? Colors.blue : Colors.grey,
            ),
          ),
          if (selectedTabIndex == index)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 20,
              color: Colors.blue,
            ),
        ],
      ),
    );
  }

  List<Map<String, String>> getCurrentTabData() {
    switch (selectedTabIndex) {
      case 0:
        return [];
      case 1:
        return [];
      case 2:
        return [];
      default:
        return [];
    }
  }
}
