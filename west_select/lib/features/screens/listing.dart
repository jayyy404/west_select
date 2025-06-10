import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  final String productId; // product ID
  final String postTitle;
  final String postDescription;
  final int numComments;
  final String postUserId; // user id of the poster (seller)
  final String imageUrl;
  final double price;
  // sellerName is dynamic because it's not stored in the post document but fetched separately from users collection
  final String sellerName;

  Listing({
    required this.productId,
    required this.postTitle,
    required this.postDescription,
    required this.numComments,
    required this.postUserId,
    required this.imageUrl,
    required this.price,
    required this.sellerName,
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
      imageUrl: doc['image_url'] ?? '',
      price: (doc['price'] ?? 0).toDouble(),
      sellerName: doc['sellerName'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'post_id': productId,
      'post_title': postTitle,
      'post_description': postDescription,
      'num_comments': numComments,
      'post_users': postUserId,
      'image_url': imageUrl,
      'price': price,
      'sellerName': sellerName,
    };
  }
}
