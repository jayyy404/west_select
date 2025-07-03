import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cc206_west_select/features/screens/profile/profile_widgets/order_list.dart';
import 'package:cc206_west_select/features/screens/message/message_page.dart';

class PendingOrdersPage extends StatefulWidget {
  const PendingOrdersPage({super.key, required this.userId});

  final String userId;

  @override
  State<PendingOrdersPage> createState() => _PendingOrdersPageState();
}

class _PendingOrdersPageState extends State<PendingOrdersPage> {
  Future<String> _fetchSellerName(String sellerId) async {
    if (sellerId == 'unknown') return 'Unknown Seller';
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();
      return (snap.data()?['displayName'] as String?) ?? 'Unknown Seller';
    } catch (e) {
      return 'Unknown Seller';
    }
  }

  void _sendMessage(String sellerId, String sellerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(
          receiverId: sellerId,
          userName: sellerName,
          fromPendingOrders: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pending Orders',
          style: TextStyle(
            color: Color(0xFF201D1B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF201D1B)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: OrderList(
          appUserId: widget.userId,
          pending: true,
          fetchSellerName: _fetchSellerName,
          writeReview: (_) {},
          addToCart: (_) {},
          sendMessage: _sendMessage,
        ),
      ),
    );
  }
}
