import 'package:flutter/material.dart';
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
                  setState(() {
                    widget.appUser.displayName = newName;
                  });

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
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildTabSelection(),
            const SizedBox(height: 20),
            Expanded(child: _buildOrderList()),
            _buildSignOutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: widget.appUser.profilePictureUrl != null
              ? NetworkImage(widget.appUser.profilePictureUrl!)
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

  Widget _buildOrderList() {
    final orders =
        selectedTabIndex == 0 ? _getPendingOrders() : _getCompletedOrders();

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

  List<Order> _getPendingOrders() {
    return widget.appUser.orderHistory
            ?.where((order) => order.status == 'pending')
            .toList() ??
        [];
  }

  List<Order> _getCompletedOrders() {
    return widget.appUser.orderHistory
            ?.where((order) => order.status == 'completed')
            .toList() ??
        [];
  }
}
