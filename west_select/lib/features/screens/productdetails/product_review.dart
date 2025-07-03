import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class ProductReviews extends StatefulWidget {
  final String productId;

  const ProductReviews({super.key, required this.productId});

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Customer Reviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('post')
          .doc(widget.productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No reviews yet. Be the first to review!'),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((review) {
            return _ReviewTile(review: review);
          }).toList(),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final DocumentSnapshot review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final timestamp = review['timestamp'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(review['userName'] ?? 'Anonymous'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(review['comment']),
            if (timestamp != null) ...[
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM dd, yyyy - hh:mm a').format(
                  timestamp.toDate().toLocal(),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
