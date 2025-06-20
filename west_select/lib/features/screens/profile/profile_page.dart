import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cc206_west_select/firebase/auth_service.dart';
import 'package:cc206_west_select/features/log_in.dart';
import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:cc206_west_select/features/screens/profile/order_details_page.dart';

class ProfilePage extends StatefulWidget {
  final AppUser appUser;
  final bool? readonly;

  const ProfilePage({super.key, required this.appUser, this.readonly});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int selectedTabIndex = 0;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  late bool isReadOnly;

  @override
  void initState() {
    super.initState();

    // Get current user from FirebaseAuth
    final currentUser = FirebaseAuth.instance.currentUser;
    // Compare current user's UID with profile's UID
    if (currentUser != null && currentUser.uid == widget.appUser.uid) {
      isReadOnly = false;
    } else {
      isReadOnly = true;
    }

    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.appUser.uid)
        .snapshots();
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LogInPage()),
    );
  }

  Future<void> _editDisplayNameAndDescription(AppUser appUser) async {
    final TextEditingController editNameController =
    TextEditingController(text: appUser.displayName ?? '');
    final TextEditingController editDescriptionController =
    TextEditingController(text: appUser.description ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editNameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: editDescriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = editNameController.text.trim();
                final newDescription = editDescriptionController.text.trim();

                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Display name cannot be empty')),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.appUser.uid)
                    .update({
                  'displayName': newName,
                  'description': newDescription,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
                Navigator.pop(context);
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
    print('ProfilePage build: isReadOnly = $isReadOnly');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Error loading user data"));
        }

        final userData = snapshot.data!.data()!;
        final updatedAppUser = AppUser.fromFirestore(userData);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            actions: isReadOnly
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF1976D2)),
                      onPressed: () => _editDisplayNameAndDescription(updatedAppUser),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
                      onPressed: _signOut,
                    ),
                  ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(updatedAppUser),
                const SizedBox(height: 20),
                if (!isReadOnly) ...[
                  _buildTabSelection(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildOrderList(updatedAppUser)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(AppUser appUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: appUser.profilePictureUrl != null
                  ? NetworkImage(appUser.profilePictureUrl!)
                  : null,
              backgroundColor: Colors.grey,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appUser.displayName ?? "User's Name",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  Text(
                    appUser.email,
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
        const SizedBox(height: 12),
          Text(
            appUser.description ?? 'No description',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
      ],
    );
  }


  Widget _buildTabSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTabButton("Pending", 0),
        _buildTabButton("Completed", 1),
      ],
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

  Widget _buildOrderList(AppUser appUser) {
    return Column(
      children: [
        if (selectedTabIndex == 0)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('buyerId', isEqualTo: appUser.uid)
                  .where('status', isEqualTo: 'pending')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return const Center(child: Text("No pending orders"));
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final data = order.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text("Order ID: ${data['orderId']}"),
                        subtitle: Text(
                          "Total: PHP ${data['total_price']} - Date: ${data['created_at'].toDate()}",
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailScreen(
                                orderId: data['orderId'],
                                collection: 'orders',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          )
        else if (selectedTabIndex == 1)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('completed_orders')
                  .where('buyerId', isEqualTo: appUser.uid)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return const Center(child: Text("No completed orders"));
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final data = order.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text("Order ID: ${data['orderId']}"),
                        subtitle: Text(
                          "Total: PHP ${data['total_price']} - Date: ${data['created_at'].toDate()}",
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailScreen(
                                orderId: data['orderId'],
                                collection: 'completed_orders',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
