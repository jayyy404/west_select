import 'package:cc206_west_select/features/screens/listing/orders_page.dart';
import 'package:cc206_west_select/features/screens/listing/my_products_page.dart';
import 'package:cc206_west_select/features/screens/listing/create_listing_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  Future<Map<String, int>> _getCounts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return {'pending': 0, 'completed': 0, 'reviews': 0};
    }

    final currentUserId = currentUser.uid;

    // Get pending orders count
    final pendingOrdersSnapshot =
        await FirebaseFirestore.instance.collection('orders').get();

    int pendingCount = 0;
    for (var doc in pendingOrdersSnapshot.docs) {
      final data = doc.data();
      final products = data['products'] as List<dynamic>;
      if (products.any((product) =>
          product['sellerId'] == currentUserId &&
          product['status'] != 'completed')) {
        pendingCount++;
      }
    }

    // Get completed orders count
    final completedOrdersSnapshot =
        await FirebaseFirestore.instance.collection('completed_orders').get();

    int completedCount = 0;
    for (var doc in completedOrdersSnapshot.docs) {
      final data = doc.data();
      final products = data['products'] as List<dynamic>;
      if (products.any((product) => product['sellerId'] == currentUserId)) {
        completedCount++;
      }
    }

    // Get reviews count
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: currentUserId)
        .get();

    int reviewsCount = 0;
    for (var doc in productsSnapshot.docs) {
      final data = doc.data();
      final reviews = data['reviews'] as List<dynamic>? ?? [];
      reviewsCount += reviews.length;
    }

    return {
      'pending': pendingCount,
      'completed': completedCount,
      'reviews': reviewsCount,
    };
  }

  Widget _buildStatusTile(String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        constraints: const BoxConstraints(
          minHeight: 100,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF201D1B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF201D1B)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF201D1B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF201D1B)),
        onTap: () {
          if (title == "All orders") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrdersPage()),
            );
          } else if (title == "My Products") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyProductsPage()),
            );
          } else if (title == "Create Listing") {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CreateListingPage()),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top yellow header section
          Container(
            padding:
                const EdgeInsets.only(top: 40, bottom: 20, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFCF68),
            ),
            child: Stack(
              children: [
                // X button in top left corner
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    color: const Color(0xFF201D1B),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        "My shop",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF201D1B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Shop Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF201D1B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, int>>(
                      future: _getCounts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Row(
                            children: [
                              _buildStatusTile("...", "Pending Orders"),
                              const SizedBox(width: 8),
                              _buildStatusTile("...", "Completed Orders"),
                              const SizedBox(width: 8),
                              _buildStatusTile("...", "Reviews Received"),
                            ],
                          );
                        }
                        final counts = snapshot.data ??
                            {'pending': 0, 'completed': 0, 'reviews': 0};
                        return Row(
                          children: [
                            _buildStatusTile(
                                "${counts['pending']}", "Pending Orders"),
                            const SizedBox(width: 8),
                            _buildStatusTile(
                                "${counts['completed']}", "Completed Orders"),
                            const SizedBox(width: 8),
                            _buildStatusTile(
                                "${counts['reviews']}", "Reviews Received"),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main content section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, bottom: 16),
                  child: Text(
                    "What you can do",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF201D1B),
                    ),
                  ),
                ),
                _buildActionTile(
                  "All orders",
                  "See updates about your products",
                  Icons.list_alt,
                ),
                _buildActionTile(
                  "My Products",
                  "Check your inventory",
                  Icons.shopping_bag,
                ),
                _buildActionTile(
                  "Create Listing",
                  "List your products",
                  Icons.add,
                ),
                const Spacer(),
                // Content display area
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      "Select an option to manage your shop",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
