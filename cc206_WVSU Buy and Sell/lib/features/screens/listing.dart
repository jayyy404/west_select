import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  final String postTitle;
  final String postDescription;
  final int numComments;
  final String postUserId;
  final String imageUrl; // New field for image URL
  final double price; // New field for price

  Listing({
    required this.postTitle,
    required this.postDescription,
    required this.numComments,
    required this.postUserId,
    required this.imageUrl,
    required this.price,
  });

  // Convert Firestore document to Listing
  factory Listing.fromFirestore(Map<String, dynamic> doc) {
    return Listing(
      postTitle: doc['post_title'] ?? '',
      postDescription: doc['post_description'] ?? '',
      numComments: doc['num_comments'] ?? 0,
      postUserId: doc['post_users'] is DocumentReference
          ? (doc['post_users'] as DocumentReference).id
          : (doc['post_users'] ?? ''),
      imageUrl: doc['image_url'] ?? '',
      price: (doc['price'] ?? 0).toDouble(),
    );
  }

  // Convert Listing to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'post_title': postTitle,
      'post_description': postDescription,
      'num_comments': numComments,
      'post_users': postUserId,
      'image_url': imageUrl,
      'price': price,
    };
  }
}
