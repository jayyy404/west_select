import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final String collection; // Add collection as a parameter

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Use the provided collection for the query
        future: FirebaseFirestore.instance
            .collection(collection)
            .doc(orderId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID: ${orderData['orderId']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Status: ${orderData['status']}'),
                const SizedBox(height: 10),
                Text('Total: PHP ${orderData['total_price']}'),
                const SizedBox(height: 10),
                Text('Ordered at: ${orderData['created_at'].toDate()}'),
                const SizedBox(height: 20),
                const Text('Products:'),
                Expanded(
                  child: _buildProductsList(orderData),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList(Map<String, dynamic> orderData) {
    final products = orderData['products'] as List<dynamic>?;

    if (products == null || products.isEmpty) {
      return const Center(child: Text('No products found.'));
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index] as Map<String, dynamic>;
        final productName = product['title'] ?? 'Unknown Product';
        final productId = product['productId'] ?? 'Unknown ID';
        final productQuantity = product['quantity'] ?? 0;
        final productStatus = product['status'] ?? 'pending';
        final sellerId = product['sellerId'];

        return FutureBuilder<DocumentSnapshot>(
          future: sellerId != null
              ? FirebaseFirestore.instance.collection('users').doc(sellerId).get()
              : null,
          builder: (context, sellerSnapshot) {
            if (sellerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final sellerData = sellerSnapshot.data?.data() as Map<String, dynamic>?;
            final sellerName = sellerData?['displayName'] ?? 'Unknown Seller';

            return ListTile(
              title: Text(productName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product ID: $productId'),
                  Text('Quantity: $productQuantity'),
                  Text('Status: $productStatus'),
                  Text('Seller: $sellerName'),
                  Text('Seller ID: ${sellerId ?? 'Unknown'}'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
