import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cc206_west_select/features/screens/profile/profile_widgets/order_list.dart';
import 'package:cc206_west_select/features/screens/cart/cart_model.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key, required this.userId});

  final String userId;

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  Future<String> _fetchSellerName(String sellerId) async {
    if (sellerId == 'unknown') return 'Unknown Seller';
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();
      return (snap.data()?['displayName'] as String?) ?? 'Unknown Seller';
    } catch (e) {
      return 'Unknown Seller';
    }
  }

  Future<void> _writeReviewImpl(String productId, String sellerId,
      String productTitle, double productPrice, String productImage) async {
    final TextEditingController reviewController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    // Check if user has already reviewed this product
    final existingReview = await FirebaseFirestore.instance
        .collection('post')
        .doc(productId)
        .collection('reviews')
        .doc(user.uid)
        .get();

    if (existingReview.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reviewed this product')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product: $productTitle',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Share your experience with this product...',
                  border: OutlineInputBorder(),
                ),
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
                if (reviewController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write a review')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('post')
                      .doc(productId)
                      .collection('reviews')
                      .doc(user.uid)
                      .set({
                    'userId': user.uid,
                    'userName': user.displayName ?? 'Anonymous',
                    'comment': reviewController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Review submitted successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error submitting review: $e')),
                  );
                }
              },
              child: const Text('Submit Review'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToCartImpl(String productId, String sellerId,
      String productTitle, double productPrice, List<String> imageUrls) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if product is still available
      final productDoc = await FirebaseFirestore.instance
          .collection('post')
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product no longer available')),
        );
        return;
      }

      final productData = productDoc.data() as Map<String, dynamic>;
      final stock = productData['stock'] ?? 0;
      final status = productData['status'] ?? 'listed';

      if (stock <= 0 || status == 'soldout' || status == 'delisted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product is out of stock')),
        );
        return;
      }

      final cart = Provider.of<CartModel>(context, listen: false);

      cart.addToCart(
        productId,
        productTitle,
        productPrice,
        imageUrls,
        sellerId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    }
  }

  List<String> _getImageUrls(dynamic imageUrl) {
    if (imageUrl == null) return [];

    if (imageUrl is String && imageUrl.isNotEmpty) {
      return [imageUrl];
    } else if (imageUrl is List) {
      return imageUrl
          .map((url) => url.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return [];
  }

  String _getImageUrl(dynamic imageUrl) {
    final urls = _getImageUrls(imageUrl);
    return urls.isNotEmpty ? urls.first : '';
  }

  void _writeReview(Map<String, dynamic> product) {
    _writeReviewImpl(
      product['productId'] ?? '',
      product['sellerId'] ?? '',
      product['title'] ?? '',
      (product['price'] ?? 0.0).toDouble(),
      _getImageUrl(product['imageUrl']),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    _addToCartImpl(
      product['productId'] ?? '',
      product['sellerId'] ?? '',
      product['title'] ?? '',
      (product['price'] ?? 0.0).toDouble(),
      _getImageUrls(product['imageUrl']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(
            color: Color(0xFF201D1B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF201D1B)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: OrderList(
          appUserId: widget.userId,
          pending: false,
          fetchSellerName: _fetchSellerName,
          writeReview: _writeReview,
          addToCart: _addToCart,
        ),
      ),
    );
  }
}
