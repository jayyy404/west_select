import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';

class UserReviewsPage extends StatefulWidget {
  const UserReviewsPage({super.key, required this.userId});

  final String userId;

  @override
  State<UserReviewsPage> createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends State<UserReviewsPage> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Reviews',
          style: TextStyle(
            color: Color(0xFF201D1B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF201D1B)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('post').snapshots(),
        builder: (context, postsSnapshot) {
          if (postsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (postsSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${postsSnapshot.error}'),
                  ElevatedButton(
                    onPressed: () => _fetchAllUserReviews(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!postsSnapshot.hasData || postsSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No posts found'),
            );
          }

          // get reviews for all posts
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchReviewsFromPosts(postsSnapshot.data!.docs),
            builder: (context, reviewsSnapshot) {
              if (reviewsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!reviewsSnapshot.hasData || reviewsSnapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your reviews will appear here after you write them',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviewsSnapshot.data!.length,
                itemBuilder: (context, index) {
                  final reviewItem = reviewsSnapshot.data![index];
                  return _buildReviewCard(
                    reviewItem['reviewData'],
                    reviewItem['productTitle'],
                    reviewItem['productImage'],
                    productId: reviewItem['productId'],
                    reviewId: reviewItem['reviewId'],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(
    Map<String, dynamic> reviewData,
    String productTitle,
    String productImage, {
    String? productId,
    String? reviewId,
  }) {
    final timestamp = reviewData['timestamp'] as Timestamp?;
    final comment = reviewData['comment'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: productImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            productImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF201D1B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timestamp != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(
                            timestamp.toDate().toLocal(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit' &&
                        productId != null &&
                        reviewId != null) {
                      _editReview(productId, reviewId, comment, productTitle);
                    } else if (value == 'delete' &&
                        productId != null &&
                        reviewId != null) {
                      _deleteReview(productId, reviewId, productTitle);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Review comment
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                comment,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF201D1B),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fallback method to manually search for reviews
  Widget _buildFallbackReviewsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllUserReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No reviews found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your reviews will appear here after you write them',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final reviewItem = snapshot.data![index];
            return _buildReviewCard(
              reviewItem['reviewData'],
              reviewItem['productTitle'],
              reviewItem['productImage'],
              productId: reviewItem['productId'],
              reviewId: reviewItem['reviewId'],
            );
          },
        );
      },
    );
  }

  // Manually fetch all reviews by searching through all posts
  Future<List<Map<String, dynamic>>> _fetchAllUserReviews() async {
    print('Fetching reviews manually for user: ${widget.userId}');

    try {
      final postsSnapshot =
          await FirebaseFirestore.instance.collection('post').get();

      List<Map<String, dynamic>> allReviews = [];

      // Search through each post's reviews subcollection
      for (final postDoc in postsSnapshot.docs) {
        final reviewsSnapshot = await postDoc.reference
            .collection('reviews')
            .where('userId', isEqualTo: widget.userId)
            .get();

        for (final reviewDoc in reviewsSnapshot.docs) {
          final reviewData = reviewDoc.data();
          final postData = postDoc.data();

          String productTitle = postData['post_title'] ?? 'Unknown Product';
          String productImage = '';

          final imageUrls = postData['image_url'];
          if (imageUrls is List && imageUrls.isNotEmpty) {
            productImage = imageUrls.first.toString();
          } else if (imageUrls is String) {
            productImage = imageUrls;
          }

          allReviews.add({
            'reviewData': reviewData,
            'productTitle': productTitle,
            'productImage': productImage,
            'productId': postDoc.id,
            'reviewId': reviewDoc.id,
          });
        }
      }

      // Sort by timestamp
      allReviews.sort((a, b) {
        final aTime = a['reviewData']['timestamp'] as Timestamp?;
        final bTime = b['reviewData']['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return allReviews;
    } catch (e) {
      return [];
    }
  }

  // Fetch reviews from a list of post documents
  Future<List<Map<String, dynamic>>> _fetchReviewsFromPosts(
      List<QueryDocumentSnapshot> posts) async {
    List<Map<String, dynamic>> allReviews = [];

    for (final postDoc in posts) {
      try {
        final reviewsSnapshot = await postDoc.reference
            .collection('reviews')
            .where('userId', isEqualTo: widget.userId)
            .get();

        for (final reviewDoc in reviewsSnapshot.docs) {
          final reviewData = reviewDoc.data();
          final postData = postDoc.data() as Map<String, dynamic>;

          String productTitle = postData['post_title'] ?? 'Unknown Product';
          String productImage = '';

          final imageUrls = postData['image_url'];
          if (imageUrls is List && imageUrls.isNotEmpty) {
            productImage = imageUrls.first.toString();
          } else if (imageUrls is String) {
            productImage = imageUrls;
          }

          allReviews.add({
            'reviewData': reviewData,
            'productTitle': productTitle,
            'productImage': productImage,
            'productId': postDoc.id,
            'reviewId': reviewDoc.id,
          });
        }
      } catch (e) {}
    }

    // Sort by timestamp
    allReviews.sort((a, b) {
      final aTime = a['reviewData']['timestamp'] as Timestamp?;
      final bTime = b['reviewData']['timestamp'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    print('Total reviews found: ${allReviews.length}');
    return allReviews;
  }

  // Edit review method
  Future<void> _editReview(String productId, String reviewId,
      String currentComment, String productTitle) async {
    final TextEditingController reviewController =
        TextEditingController(text: currentComment);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product: $productTitle',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newComment = reviewController.text.trim();
                if (newComment.isEmpty) {
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
                      .doc(reviewId)
                      .update({
                    'comment': newComment,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating review: $e')),
                  );
                }
              },
              child: const Text('Update Review'),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review updated successfully!')),
      );
    }
  }

  // Delete review method
  Future<void> _deleteReview(
      String productId, String reviewId, String productTitle) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete your review for:'),
              const SizedBox(height: 8),
              Text(
                productTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('post')
                      .doc(productId)
                      .collection('reviews')
                      .doc(reviewId)
                      .delete();

                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting review: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully!')),
      );
    }
  }
}
