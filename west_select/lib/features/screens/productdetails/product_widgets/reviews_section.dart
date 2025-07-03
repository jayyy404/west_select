import 'package:cc206_west_select/features/screens/productdetails/product_review.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReviewsSection extends StatefulWidget {
  const ReviewsSection({
    super.key,
    required this.postId,
    required this.ownerId,
    required this.productTitle,
    required this.productPrice,
    required this.productImage,
  });

  final String postId;
  final String ownerId;
  final String productTitle;
  final double productPrice;
  final String productImage;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  Widget _preview(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 16, color: Colors.white)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['userName'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (d['timestamp'] != null)
                    Text(
                      DateFormat('MMM dd, yyyy').format(
                          (d['timestamp'] as Timestamp).toDate().toLocal()),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(d['comment'] ?? '',
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis)
      ],
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('post')
            .doc(widget.postId)
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (_, snap) {
          final count = snap.hasData ? snap.data!.docs.length : 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Reviews ($count)',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (count > 0)
                      TextButton(
                          onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => Scaffold(
                                          appBar: AppBar(
                                              title: const Text('All Reviews'),
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              elevation: 1),
                                          body: ProductReviews(
                                              productId: widget.postId),
                                        )),
                              ),
                          child: const Text('View All'))
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // content
              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(child: CircularProgressIndicator()))
              else if (count == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Center(
                        child: Text('No reviews yet. Be the first!',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 14))),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: _preview(snap.data!.docs.first)),
                ),
            ],
          );
        },
      );
}
