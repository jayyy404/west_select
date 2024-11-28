import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  String? displayName;
  final String? profilePictureUrl;
  final String? address;
  final String? phoneNumber;
  final List<String>? cart; // List of product IDs in the cart
  final List<Order>? orderHistory; // List of orders

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.profilePictureUrl,
    this.address,
    this.phoneNumber,
    this.cart,
    this.orderHistory,
  });

  // Factory method to create a User object from a Firestore document
  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      profilePictureUrl: data['profilePictureUrl'],
      address: data['address'],
      phoneNumber: data['phoneNumber'],
      cart: List<String>.from(data['cart'] ?? []),
      orderHistory: (data['orderHistory'] as List<dynamic>?)
          ?.map((order) => Order.fromFirestore(order))
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
      'address': address,
      'phoneNumber': phoneNumber,
      'cart': cart,
      'orderHistory':
          orderHistory?.map((order) => order.toFirestore()).toList(),
    };
  }
}

class Order {
  final String orderId;
  final List<String> productIds; // IDs of products in the order
  final double totalAmount;
  final DateTime orderDate;
  final String status; // Either "pending" or "completed"

  Order({
    required this.orderId,
    required this.productIds,
    required this.totalAmount,
    required this.orderDate,
    required this.status, // New field for order status
  });

  // Factory method to create an Order object from a Firestore document
  factory Order.fromFirestore(Map<String, dynamic> data) {
    return Order(
      orderId: data['orderId'] ?? '',
      productIds: List<String>.from(data['productIds'] ?? []),
      totalAmount: (data['totalAmount'] as num).toDouble(),
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
