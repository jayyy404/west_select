import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? description;
  final String? profilePictureUrl;
  final List<UserOrder> orderHistory; // List of orders
  final List<UserListing> userListings; // List of listings

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.description,
    this.profilePictureUrl,
    required this.orderHistory,
    required this.userListings,
  });

  // Factory method to create an AppUser instance from Firestore data
  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    var orderHistory = (data['orderHistory'] as List<dynamic>?)
            ?.map((orderData) => UserOrder.fromMap(orderData))
            .toList() ??
        [];

    var userListings = (data['userListings'] as List<dynamic>?)
            ?.map((listingData) => UserListing.fromMap(listingData))
            .toList() ??
        [];

    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      description: data['description'],
      profilePictureUrl: data['profilePictureUrl'],
      orderHistory: orderHistory,
      userListings: userListings,
    );
  }

  // Convert AppUser to Firestore-friendly map
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'profilePictureUrl': profilePictureUrl,
      'orderHistory': orderHistory.map((order) => order.toMap()).toList(),
      'userListings': userListings.map((listing) => listing.toMap()).toList(),
    };
  }
}

class UserOrder {
  final String orderId;
  final double totalAmount;
  final String status; // "pending", "completed"
  final DateTime orderDate;

  UserOrder({
    required this.orderId,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
  });

  // Factory method to create a UserOrder instance from a map
  factory UserOrder.fromMap(Map<String, dynamic> data) {
    return UserOrder(
      orderId: data['orderId'],
      totalAmount: data['totalAmount'],
      status: data['status'],
      orderDate: (data['orderDate'] as Timestamp).toDate(),
    );
  }

  // Convert UserOrder to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': Timestamp.fromDate(orderDate),
    };
  }
}

class UserListing {
  final String listingId;
  final String title;
  final double price;
  final String imageUrl;
  final String description;

  UserListing({
    required this.listingId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  // Factory method to create a UserListing instance from a map
  factory UserListing.fromMap(Map<String, dynamic> data) {
    return UserListing(
      listingId: data['listingId'],
      title: data['title'],
      price: data['price'],
      imageUrl: data['imageUrl'],
      description: data['description'],
    );
  }

  // Convert UserListing to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'title': title,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}
