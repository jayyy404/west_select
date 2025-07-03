import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  final String productId;
  final String postTitle;
  final String postDescription;
  final int numComments;
  final String postUserId;
  final List<String> imageUrls;
  final double price;
  final String sellerName;
  final String? category;

  Listing({
    required this.productId,
    required this.postTitle,
    required this.postDescription,
    required this.numComments,
    required this.postUserId,
    required this.imageUrls,
    required this.price,
    required this.sellerName,
    this.category,
  });

  factory Listing.fromFirestore(Map<String, dynamic> doc) {
    return Listing(
      productId: doc['post_id'] ?? '',
      postTitle: doc['post_title'] ?? '',
      postDescription: doc['post_description'] ?? '',
      numComments: doc['num_comments'] ?? 0,
      postUserId: doc['post_users'] is DocumentReference
          ? (doc['post_users'] as DocumentReference).id
          : (doc['post_users'] ?? ''),
      imageUrls: List<String>.from(doc['image_urls'] ?? []),
      price: (doc['price'] ?? 0).toDouble(),
      sellerName: doc['sellerName'] ?? '',
      category: doc['category'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'post_id': productId,
      'post_title': postTitle,
      'post_description': postDescription,
      'num_comments': numComments,
      'post_users': postUserId,
      'image_urls': imageUrls,
      'price': price,
      'sellerName': sellerName,
      'category': category,
    };
  }
}
