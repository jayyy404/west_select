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
    // Set up a Firestore stream to listen for changes to the user's data.
    _userStream = FirebaseFirestore.instance
        .collection('users') // Replace with your Firestore collection name
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

  void _editDisplayName() {
    final TextEditingController editNameController =
    TextEditingController(text: widget.appUser.displayName ?? '');

    showDialog(
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
                      .collection('users') // Replace with your Firestore collection name
                      .doc(widget.appUser.uid)
                      .update({'displayName': newName});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name updated successfully')),
                  );
                  Navigator.pop(context);
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

        // Parse updated user data
        final userData = snapshot.data!.data()!;
        final updatedAppUser = AppUser.fromFirestore(userData);

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
                _buildProfileHeader(updatedAppUser),
                const SizedBox(height: 20),
                _buildTabSelection(),
                const SizedBox(height: 20),
                Expanded(child: _buildOrderList(updatedAppUser)),
                _buildSignOutButton(),
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
    final orders = selectedTabIndex == 0
        ? _getPendingOrders(appUser)
        : _getCompletedOrders(appUser);

    if (orders.isEmpty) {
      return const Center(child: Text("No orders to display"));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          child: ListTile(
            title: Text("Order ID: ${order.orderId}"),
            subtitle: Text(
              "Total: \$${order.totalAmount.toStringAsFixed(2)}\nDate: ${order.orderDate.toLocal()}",
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignOutButton() {
    return ElevatedButton(
      onPressed: _signOut,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }

  List<UserOrder> _getPendingOrders(AppUser appUser) {
    return appUser.orderHistory
        ?.where((order) => order.status == 'pending')
        .toList() ??
        [];
  }

  List<UserOrder> _getCompletedOrders(AppUser appUser) {
    return appUser.orderHistory
        ?.where((order) => order.status == 'completed')
        .toList() ??
        [];
  }
}
