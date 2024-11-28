import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  String? displayName;
  final String? profilePictureUrl;
  final List<String>? cart; // List of product IDs in the cart
  final List<UserOrder>? orderHistory; // List of orders

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.profilePictureUrl,
    this.cart,
    this.orderHistory,
  });

  // Factory method to create a User object from a Firestore document
  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] as String?,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      cart: (data['cart'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList(),
      orderHistory: (data['orderHistory'] as List<dynamic>?)
          ?.map((order) => UserOrder.fromFirestore(order as Map<String, dynamic>))
          .toList(),
    );
  }

  // Method to convert User object to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'profilePictureUrl': profilePictureUrl,
      'cart': cart,
      'orderHistory': orderHistory?.map((order) => order.toFirestore()).toList(),
    };
  }
}

class UserOrder {
  final String orderId;
  final List<String> productIds;
  final double totalAmount;
  final DateTime orderDate;
  final String status;

  UserOrder({
    required this.orderId,
    required this.productIds,
    required this.totalAmount,
    required this.orderDate,
    required this.status, // New field for order status
  });

  // Factory method to create an Order object from a Firestore document
  factory UserOrder.fromFirestore(Map<String, dynamic> data) {
    return UserOrder(
      orderId: data['orderId'] ?? '',
      productIds: (data['productIds'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending', // Default to "pending"
    );
  }

  // Method to convert Order object to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'productIds': productIds,
      'totalAmount': totalAmount,
      'orderDate': orderDate,
      'status': status,
    };
  }
}
