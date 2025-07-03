import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrdersList extends StatefulWidget {
  const OrdersList({super.key});

  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  Map<String, String> buyerNames = {};
  Map<String, String> buyerProfileUrls = {};
  Map<String, List<String>> productImageUrls = {};

  Future<void> fetchBuyerNames(List<QueryDocumentSnapshot> orders) async {
    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      String? buyerId = data['buyerId'];
      if (buyerId != null && !buyerNames.containsKey(buyerId)) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(buyerId)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          buyerNames[buyerId] = userData['displayName'] ?? 'Unknown Buyer';
          buyerProfileUrls[buyerId] = userData['profileImageUrl'] ?? '';
        } else {
          buyerNames[buyerId] = 'Unknown Buyer';
          buyerProfileUrls[buyerId] = '';
        }
      }
    }
  }

  Future<void> fetchProductImages(List<dynamic> products) async {
    for (var product in products) {
      String productId = product['productId'];
      if (!productImageUrls.containsKey(productId)) {
        try {
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();
          if (productDoc.exists && productDoc.data() != null) {
            final productData = productDoc.data()!;
            List<String> imageUrls = [];
            if (productData['imageUrls'] != null) {
              imageUrls = List<String>.from(productData['imageUrls']);
            }
            productImageUrls[productId] = imageUrls;
          } else {
            productImageUrls[productId] = [];
          }
        } catch (e) {
          productImageUrls[productId] = [];
        }
      }
    }
  }

  Future<void> markAllProductsAsCompleted(
      String orderId, List<dynamic> sellerProducts) async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      if (!orderDoc.exists) return;

      final orderData = orderDoc.data()! as Map<String, dynamic>;
      final List<dynamic> products = orderData['products'];

      // Update order status and reduce product stock
      for (var product in sellerProducts) {
        final productIndex = products
            .indexWhere((prod) => prod['productId'] == product['productId']);
        if (productIndex != -1) {
          products[productIndex]['status'] = 'completed';

          // Reduce stock in the products collection
          await _reduceProductStock(product['productId'], product['quantity']);
        }
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  "Order marked as complete and moved to completed orders.")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error marking product as completed: $e")));
      }
    }
  }

  Future<void> _reduceProductStock(String productId, int quantitySold) async {
    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('post')
          .doc(productId)
          .get();

      if (!productDoc.exists) return;

      final productData = productDoc.data()! as Map<String, dynamic>;
      final currentStock = productData['stock'] ?? 0;
      final currentSold = productData['sold'] ?? 0;

      final newStock =
          (currentStock - quantitySold).clamp(0, double.infinity).toInt();
      final newSold = currentSold + quantitySold;

      // Update the product with new stock and sold count
      final updateData = {
        'stock': newStock,
        'sold': newSold,
      };

      // If stock reaches 0, mark as sold out
      if (newStock == 0) {
        updateData['status'] = 'soldout';
      }

      await FirebaseFirestore.instance
          .collection('post')
          .doc(productId)
          .update(updateData);
    } catch (e) {
      print("Error reducing product stock: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
          return const Center(child: Text("No orders found."));
        }

        final orders = snapshot.data!.docs;
        final filteredOrders = orders.where((order) {
          final data = order.data()! as Map<String, dynamic>;
          final products = data['products'] as List<dynamic>;
          return products
              .any((product) => product['sellerId'] == currentUserId);
        }).toList();

        return FutureBuilder<void>(
          future: Future.wait([
            fetchBuyerNames(orders),
            fetchProductImages(filteredOrders.expand((order) {
              final data = order.data()! as Map<String, dynamic>;
              return data['products'] as List<dynamic>;
            }).toList())
          ]),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (filteredOrders.isEmpty) {
              return const Center(child: Text("No orders for your products."));
            }

            return ListView.builder(
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

                bool allCompleted = sellerProducts
                    .every((product) => product['status'] == 'completed');

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(buyerName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Price: PHP ${data['total_price']}"),
                        const SizedBox(height: 8),
                        const Text("Products:"),
                        for (var product in sellerProducts)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                                "- ${product['title']} (x${product['quantity']}): PHP ${product['price']}",
                                style: const TextStyle(fontSize: 14)),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                          allCompleted
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: allCompleted ? Colors.green : Colors.blue),
                      onPressed: allCompleted
                          ? null
                          : () => markAllProductsAsCompleted(
                              orderId, sellerProducts),
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
}
