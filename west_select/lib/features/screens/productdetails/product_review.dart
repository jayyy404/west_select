import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class ProductReviews extends StatefulWidget {
  final String productId;

  const ProductReviews({super.key, required this.productId});

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  final TextEditingController _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  String? editingReviewId;
  bool _isSubmitting = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitReview() async {
    if (user == null) {
      _showError('You must be logged in to submit a review');
      return;
    }

    final comment = _controller.text.trim();
    if (comment.isEmpty) {
      _showError('Review cannot be empty');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reviewData = {
        'userId': user!.uid,
        'userName': user!.displayName ?? 'Anonymous',
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final reviewRef = FirebaseFirestore.instance
          .collection('post')
          .doc(widget.productId)
          .collection('reviews')
          .doc(user!.uid);

      await reviewRef.set(reviewData);

      _controller.clear();
      setState(() => editingReviewId = null);
    } catch (e) {
      _showError('Failed to submit review: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteReview() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.productId)
          .collection('reviews')
          .doc(user!.uid)
          .delete();

      _controller.clear();
      setState(() => editingReviewId = null);
    } catch (e) {
      _showError('Failed to delete review: ${e.toString()}');
    }
  }

  void _startEditing(String currentComment) {
    _controller.text = currentComment;
    setState(() => editingReviewId = user!.uid);
  }

  void _cancelEditing() {
    _controller.clear();
    setState(() => editingReviewId = null);
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
          if (user != null) _buildReviewInput(),
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
            return _ReviewTile(
              review: review,
              currentUserId: user?.uid,
              onEdit: _startEditing,
              onDelete: _deleteReview,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReviewInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editingReviewId == null ? 'Write a Review:' : 'Edit Your Review:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type your review here...',
                    border: const OutlineInputBorder(),
                    suffixIcon: editingReviewId != null
                        ? IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: _cancelEditing,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _submitReview,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final DocumentSnapshot review;
  final String? currentUserId;
  final Function(String) onEdit;
  final VoidCallback onDelete;

  const _ReviewTile({
    required this.review,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = review.id == currentUserId;
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
        trailing: isCurrentUser
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => onEdit(review['comment']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
