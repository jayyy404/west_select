import 'package:cc206_west_select/features/screens/listing/myShop.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cc206_west_select/firebase/auth_service.dart';
import 'package:cc206_west_select/features/landingpage/log_in.dart';
import 'package:cc206_west_select/firebase/app_user.dart';

class ProfilePage extends StatefulWidget {
  final AppUser appUser;
  final bool? readonly;

  const ProfilePage({super.key, required this.appUser, this.readonly});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
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
                    const SnackBar(
                        content: Text('Display name cannot be empty')),
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

  Future<String> _fetchSellerName(String sellerId) async {
    if (sellerId == 'unknown') return 'Unknown Seller';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final displayName = userDoc.data()!['displayName'] as String?;
        return displayName ?? 'Unknown Seller';
      } else {
        return 'Unknown Seller';
      }
    } catch (e) {
      print('Error fetching seller name: $e');
      return 'Unknown Seller';
    }
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
                      onPressed: () =>
                          _editDisplayNameAndDescription(updatedAppUser),
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
              radius: 30,
              backgroundImage: appUser.profilePictureUrl != null
                  ? NetworkImage(appUser.profilePictureUrl!)
                  : null,
              backgroundColor: Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appUser.displayName ?? "User's Name",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2)),
                  ),
                  Text(appUser.email,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(appUser.description ?? 'No description',
            style: const TextStyle(fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 8),
        if (!isReadOnly)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFC67B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE6A954), width: 1),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InventoryPage()),
                );
              },
              icon: Image.asset(
                'assets/shop_icon.png',
                width: 20,
                height: 20,
              ),
              label: const Text(
                'View my Shop',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTabButton("Pending Orders", 0),
        _buildTabButton("Completed Orders", 1),
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
    // pick the proper collection based on the tab
    final _stream = (selectedTabIndex == 0
            ? FirebaseFirestore.instance.collection('orders')
            : FirebaseFirestore.instance.collection('completed_orders'))
        .where('buyerId', isEqualTo: appUser.uid)
        .orderBy('created_at', descending: true)
        .snapshots();

    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.docs.isEmpty) {
            return Center(
                child: Text(selectedTabIndex == 0
                    ? "No pending orders"
                    : "No completed orders"));
          }

          // Aggregate identical products
          final Map<String, Map<String, dynamic>> merged = {};

          for (final doc in snap.data!.docs) {
            final orderData = doc.data() as Map<String, dynamic>;
            final products = orderData['products'] as List<dynamic>? ?? [];

            for (final p in products) {
              final sellerId = p['sellerId'] ?? 'unknown';
              final productId = p['productId'] ?? 'unknown';
              final title = p['title'] ?? 'Unknown Product';
              final price = (p['price'] ?? 0).toDouble();
              final qty = (p['quantity'] ?? 1) as int;
              final imgUrl =
                  (p['imageUrl'] is List && (p['imageUrl'] as List).isNotEmpty)
                      ? (p['imageUrl'] as List).first.toString()
                      : '';

              final k = productId;
              if (merged.containsKey(k)) {
                merged[k]!['quantity'] += qty;
              } else {
                merged[k] = {
                  'sellerId': sellerId,
                  'productId': productId,
                  'title': title,
                  'price': price,
                  'quantity': qty,
                  'imageUrl': imgUrl,
                };
              }
            }
          }

          final Map<String, List<Map<String, dynamic>>> sellerMap = {};
          merged.values.forEach((prod) {
            final id = prod['sellerId'];
            (sellerMap[id] ??= []).add(prod);
          });

          return ListView(
            children: sellerMap.entries.map((entry) {
              final sellerId = entry.key;
              final products = entry.value;

              final totalItems = products.fold<int>(
                  0, (sum, p) => sum + (p['quantity'] as int));
              final totalPrice = products.fold<double>(
                  0,
                  (sum, p) =>
                      sum + (p['price'] as double) * (p['quantity'] as int));

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //seller name + status pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FutureBuilder<String>(
                              future: _fetchSellerName(sellerId),
                              builder: (_, s) => Text(
                                s.data ?? 'Loading seller…',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: selectedTabIndex == 0
                                  ? Colors.orange[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              selectedTabIndex == 0 ? 'Pending' : 'Completed',
                              style: TextStyle(
                                color: selectedTabIndex == 0
                                    ? Colors.orange[800]
                                    : Colors.green[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...products.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: (p['imageUrl'] as String).isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            p['imageUrl'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey),
                                          ),
                                        )
                                      : const Icon(Icons.image_not_supported,
                                          color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p['title'],
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Text(
                                        '× ${p['quantity']} pcs',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                    'Php: ${(p['price'] as double).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: Colors.grey[300]),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$totalItems items',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600])),
                          Text('Total Price:  ${totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      /* message button */
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: send message
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Send a message',
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
