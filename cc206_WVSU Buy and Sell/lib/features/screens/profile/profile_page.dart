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
      backgroundColor: Colors.white, // Background color #F7F7F7
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: null, // Remove title
        actions: [
          // Edit name icon (Blue), close to the name
          IconButton(
            icon: const Icon(Icons.edit,
                color: Color(0xFF1976D2)), // Blue icon #1976D2
            onPressed: _editDisplayName,
          ),
          // Sign out icon (Red), aligned to the right
          IconButton(
            icon: const Icon(Icons.logout,
                color: Color(0xFFD32F2F)), // Red icon #D32F2F
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile info section
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
                          color: Color(0xFF1976D2), // Blue color #1976D2
                        ),
                      ),
                      Text(
                        widget.appUser.email ?? "No Email",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
                height: 15), // Space between profile and next section

            // Column for "Check your purchases" text and the tab navigation
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Check your purchases',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF201D1B), // Text color #201D1B
                      fontFamily: 'Open Sans',
                      height: 1.2, // Line height 120%
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Space between text and tabs

                // Add Container without border
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabButton("Pending", 0),
                    _buildTabButton("History", 1),
                    _buildTabButton("Review", 2),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20), // Space between tabs and content

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
          ],
        ),
      ),
    );
  }

  // Function to switch between tabs
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

  // Now returns empty data, replace with actual data fetching logic
  List<Map<String, String>> getCurrentTabData() {
    switch (selectedTabIndex) {
      case 0: // Pending tab data
        return [];
      case 1: // History tab data
        return [];
      case 2: // Review tab data
        return [];
      default:
        return [];
    }
  }
}
