import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductReviewCard extends StatelessWidget {
  const ProductReviewCard({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.reviews,
  });

  final String productId;
  final String productTitle;
  final String productImage;
  final List<Map<String, dynamic>> reviews;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8)),
                  child: productImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(productImage, fit: BoxFit.cover))
                      : const Icon(Icons.image_not_supported)),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(productTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                        '${reviews.length} review${reviews.length > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                  ]))
            ]),
            const SizedBox(height: 16),
            ...reviews.map((r) => _reviewItem(r['reviewData'])),
          ]),
        ),
      );

  Widget _reviewItem(Map<String, dynamic> d) {
    final ts = d['timestamp'] as Timestamp?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.person, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
              child: Text(d['userName'] ?? 'Anonymous',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14))),
          if (ts != null)
            Text(
              _formatDate(ts.toDate()),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
        ]),
        const SizedBox(height: 8),
        Text(d['comment'] ?? '',
            style: const TextStyle(fontSize: 14, height: 1.4))
      ]),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
