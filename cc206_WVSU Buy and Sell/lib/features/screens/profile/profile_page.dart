import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cc206_west_select/firebase/auth_service.dart';
import 'package:cc206_west_select/features/log_in.dart';
import 'package:cc206_west_select/firebase/app_user.dart';

class ProfilePage extends StatefulWidget {
  final AppUser appUser;

  const ProfilePage({super.key, required this.appUser});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int selectedTabIndex = 0;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users') // Firestore collection for users
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
                if (newName.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users') // Firestore collection for users
                      .doc(widget.appUser.uid)
                      .update({'displayName': newName});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name updated successfully')),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Display name cannot be empty')),
                  );
                }
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
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF1976D2)),
                onPressed: _editDisplayName,
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
                _buildTabSelection(),
                const SizedBox(height: 20),
                Expanded(child: _buildOrderList(updatedAppUser)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(AppUser appUser) {
    return Row(
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('user_id', isEqualTo: appUser.uid)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return const Center(child: Text("No orders to display"));
        }

        final filteredOrders = selectedTabIndex == 0
            ? orders.where((order) => order['status'] == 'pending').toList()
            : orders.where((order) => order['status'] == 'completed').toList();

        return ListView.builder(
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            final data = order.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                title: Text("Order ID: ${data['order_id']}"),
                subtitle: Text(
                  "Total: PHP ${data['total_price']} - Date: ${data['created_at'].toDate()}",
                ),
              ),
            );
          },
        );
      },
    );
  }
}
