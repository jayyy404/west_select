import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  final String productId; // New field for product ID
  final String postTitle;
  final String postDescription;
  final int numComments;
  final String postUserId;
  final String imageUrl; // Field for image URL
  final double price; // Field for price
  final String sellerName; // Add sellerName field

  Listing({
    required this.productId, // Initialize productId
    required this.postTitle,
    required this.postDescription,
    required this.numComments,
    required this.postUserId,
    required this.imageUrl,
    required this.price,
    required this.sellerName, // Initialize sellerName
  });

  // Convert Firestore document to Listing
  factory Listing.fromFirestore(Map<String, dynamic> doc) {
    return Listing(
      productId: doc['post_id'] ?? '', // Map the productId from Firestore
      postTitle: doc['post_title'] ?? '',
      postDescription: doc['post_description'] ?? '',
      numComments: doc['num_comments'] ?? 0,
      postUserId: doc['post_users'] is DocumentReference
          ? (doc['post_users'] as DocumentReference).id
          : (doc['post_users'] ?? ''),
      imageUrl: doc['image_url'] ?? '',
      price: (doc['price'] ?? 0).toDouble(),
      sellerName: doc['sellerName'] ?? 'Unknown', // Map sellerName
    );
  }

  // Convert Listing to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'post_id': productId, // Include productId in Firestore document
      'post_title': postTitle,
      'post_description': postDescription,
      'num_comments': numComments,
      'post_users': postUserId,
      'image_url': imageUrl,
      'price': price,
      'sellerName': sellerName, // Include sellerName
    };
  }
}