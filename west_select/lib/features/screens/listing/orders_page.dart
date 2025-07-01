import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cc206_west_select/features/screens/productdetails/product.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String> buyerNames = {};
  Map<String, int> tabCounts = {'pending': 0, 'completed': 0, 'reviews': 0};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTabCounts();
  }

  Future<void> _loadTabCounts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

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

    // Get reviews count (count of products with reviews)
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: currentUserId)
        .get();

    int reviewsCount = 0;
    for (var doc in productsSnapshot.docs) {
      final data = doc.data();
      final reviews = data['reviews'] as List<dynamic>? ?? [];
      if (reviews.isNotEmpty) {
        reviewsCount++;
      }
    }

    if (mounted) {
      setState(() {
        tabCounts = {
          'pending': pendingCount,
          'completed': completedCount,
          'reviews': reviewsCount,
        };
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchBuyerNames(List<QueryDocumentSnapshot> orders) async {
    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      String? buyerId = data['buyerId'];
      if (buyerId != null && !buyerNames.containsKey(buyerId)) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(buyerId)
            .get();
        buyerNames[buyerId] = userDoc.exists && userDoc.data() != null
            ? (userDoc.data()!['displayName'] ?? 'Unknown Buyer')
            : 'Unknown Buyer';
      }
    }
  }

  Future<void> markOrderAsCompleted(
      String orderId, List<dynamic> sellerProducts) async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      if (!orderDoc.exists) return;

      final orderData = orderDoc.data()! as Map<String, dynamic>;
      final List<dynamic> products = orderData['products'];

      for (var product in sellerProducts) {
        final productIndex = products
            .indexWhere((prod) => prod['productId'] == product['productId']);
        if (productIndex != -1) products[productIndex]['status'] = 'completed';
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'products': products});

      bool allProductsCompleted =
          products.every((product) => product['status'] == 'completed');

      if (allProductsCompleted) {
        await FirebaseFirestore.instance
            .collection('completed_orders')
            .doc(orderId)
            .set(orderData);
        await FirebaseFirestore.instance
            .collection('completed_orders')
            .doc(orderId)
            .update({'status': 'completed'});
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Order completed successfully!")));
          _loadTabCounts(); // Refresh tab counts
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error completing order: $e")));
      }
    }
  }

  Widget _buildPendingOrders() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("User not logged in."));
    }

    final currentUserId = currentUser.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No pending orders found."));
        }

        final orders = snapshot.data!.docs;
        final filteredOrders = orders.where((order) {
          final data = order.data()! as Map<String, dynamic>;
          final products = data['products'] as List<dynamic>;
          return products.any((product) =>
              product['sellerId'] == currentUserId &&
              product['status'] != 'completed');
        }).toList();

        return FutureBuilder<void>(
          future: fetchBuyerNames(orders),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (filteredOrders.isEmpty) {
              return const Center(child: Text("No pending orders."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                final data = order.data()! as Map<String, dynamic>;

                String buyerId = data['buyerId'] ?? '';
                String buyerName = buyerNames[buyerId] ?? 'Unknown Buyer';

                final orderId = order.id;
                final products = data['products'] as List<dynamic>;
                final sellerProducts = products
                    .where((product) =>
                        product['sellerId'] == currentUserId &&
                        product['status'] != 'completed')
                    .toList();

                if (sellerProducts.isEmpty) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Order ID: #${orderId.substring(0, 8)}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "Pending",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                buyerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (var product in sellerProducts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      const Icon(Icons.shopping_bag, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['title'] ?? 'Product',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "Quantity: ${product['quantity']}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "₱${product['price']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          "${sellerProducts.length} items",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Total Price: ₱${data['total_price']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // TODO: Implement send message functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Message feature coming soon!")),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Send a message",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => markOrderAsCompleted(
                                    orderId, sellerProducts),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade400,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Complete order",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedOrders() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("User not logged in."));
    }

    final currentUserId = currentUser.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('completed_orders')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No completed orders found."));
        }

        final orders = snapshot.data!.docs;
        final filteredOrders = orders.where((order) {
          final data = order.data()! as Map<String, dynamic>;
          final products = data['products'] as List<dynamic>;
          return products
              .any((product) => product['sellerId'] == currentUserId);
        }).toList();

        return FutureBuilder<void>(
          future: fetchBuyerNames(orders),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (filteredOrders.isEmpty) {
              return const Center(child: Text("No completed orders."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                final data = order.data()! as Map<String, dynamic>;

                String buyerId = data['buyerId'] ?? '';
                String buyerName = buyerNames[buyerId] ?? 'Unknown Buyer';

                final orderId = order.id;
                final products = data['products'] as List<dynamic>;
                final sellerProducts = products
                    .where((product) => product['sellerId'] == currentUserId)
                    .toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Order ID: #${orderId.substring(0, 8)}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "Completed",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                buyerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (var product in sellerProducts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      const Icon(Icons.shopping_bag, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['title'] ?? 'Product',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "Quantity: ${product['quantity']}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "₱${product['price']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          "${sellerProducts.length} items",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Total Price: ₱${data['total_price']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReviews() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("User not logged in."));
    }

    final currentUserId = currentUser.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No products found."));
        }

        final products = snapshot.data!.docs;
        final productsWithReviews = products.where((product) {
          final data = product.data() as Map<String, dynamic>;
          final reviews = data['reviews'] as List<dynamic>? ?? [];
          return reviews.isNotEmpty;
        }).toList();

        if (productsWithReviews.isEmpty) {
          return const Center(child: Text("No reviews yet."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: productsWithReviews.length,
          itemBuilder: (context, index) {
            final product = productsWithReviews[index];
            final data = product.data() as Map<String, dynamic>;
            final reviews = data['reviews'] as List<dynamic>;

            // Calculate average rating
            double totalRating = 0;
            for (var review in reviews) {
              totalRating += (review['rating'] as num).toDouble();
            }
            double averageRating = totalRating / reviews.length;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  // Navigate to product detail page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailPage(productId: product.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: data['imageUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      data['imageUrl'],
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.shopping_bag, size: 30),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? 'Product',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      averageRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "(${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'})",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Latest Review:",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reviews.last['comment'] ?? 'No comment',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "All orders",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          indicatorWeight: 2,
          tabs: [
            Tab(text: "Pending(${tabCounts['pending']})"),
            Tab(text: "Complete(${tabCounts['completed']})"),
            Tab(text: "Reviews(${tabCounts['reviews']})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingOrders(),
          _buildCompletedOrders(),
          _buildReviews(),
        ],
      ),
    );
  }
}
