import 'package:cc206_west_select/features/screens/productdetails/product_review.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_uid == null || _ctrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.postId)
          .collection('reviews')
          .doc(_uid)
          .set({
        'userId': _uid,
        'userName':
            FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
        'comment': _ctrl.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _ctrl.clear();
    } finally {
      setState(() => _busy = false);
    }
  }

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

              // quick review box
              if (_uid != null && _uid != widget.ownerId)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Write a Review',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _ctrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  'Share your experience with this product...',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            )),
                        const SizedBox(height: 12),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                  onPressed: () => _ctrl.clear(),
                                  child: const Text('Cancel')),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                  onPressed: _busy ? null : _send,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white),
                                  child: _busy
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Text('Post Review'))
                            ])
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

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
