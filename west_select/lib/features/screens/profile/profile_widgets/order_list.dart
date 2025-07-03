import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef SellerNameGetter = Future<String> Function(String sellerId);
typedef WriteReview = void Function(Map<String, dynamic> firstProduct);
typedef AddToCart = void Function(Map<String, dynamic> firstProduct);
typedef SendMessage = void Function(String sellerId, String sellerName);

class OrderList extends StatelessWidget {
  const OrderList({
    super.key,
    required this.appUserId,
    required this.pending,
    required this.fetchSellerName,
    required this.writeReview,
    required this.addToCart,
    this.sendMessage,
  });

  final String appUserId;
  final bool pending;
  final SellerNameGetter fetchSellerName;
  final WriteReview writeReview;
  final AddToCart addToCart;
  final SendMessage? sendMessage;

  Stream<QuerySnapshot> get _stream => (pending
          ? FirebaseFirestore.instance.collection('orders')
          : FirebaseFirestore.instance.collection('completed_orders'))
      .where('buyerId', isEqualTo: appUserId)
      .orderBy('created_at', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.docs.isEmpty) {
            return Center(
                child: Text(
                    pending ? 'No pending orders' : 'No completed orders'));
          }

          // merge identical items
          final merged = <String, Map<String, dynamic>>{};
          for (final doc in snap.data!.docs) {
            final docData = doc.data() as Map<String, dynamic>?;
            final products = docData?['products'] as List<dynamic>? ?? [];

            for (final p in products) {
              if (p is! Map<String, dynamic>) continue;

              final productId = p['productId']?.toString() ?? '';
              if (productId.isEmpty) continue;

              final key = productId;
              if (merged.containsKey(key)) {
                merged[key]!['quantity'] =
                    (merged[key]!['quantity'] ?? 0) + (p['quantity'] ?? 1);
              } else {
                merged[key] = {
                  'productId': productId,
                  'sellerId': p['sellerId']?.toString() ?? '',
                  'title': p['title']?.toString() ?? 'Unknown Product',
                  'price': (p['price'] is num)
                      ? (p['price'] as num).toDouble()
                      : 0.0,
                  'quantity': p['quantity'] ?? 1,
                  'imageUrl': p['imageUrl'],
                };
              }
            }
          }

          // group by seller
          final Map<String, List<Map<String, dynamic>>> sellerMap = {};
          for (final p in merged.values) {
            final sellerId = p['sellerId']?.toString() ?? 'unknown';
            (sellerMap[sellerId] ??= []).add(p);
          }

          return ListView(
              children: sellerMap.entries
                  .map((e) => _card(context, e.key, e.value))
                  .toList());
        },
      );

  Widget _card(
      BuildContext ctx, String sellerId, List<Map<String, dynamic>> prods) {
    final totalItems = prods.fold<int>(
        0, (s, p) => s + ((p['quantity'] is int) ? p['quantity'] as int : 0));
    final totalPrice = prods.fold<double>(0, (s, p) {
      final price = (p['price'] is num) ? (p['price'] as num).toDouble() : 0.0;
      final quantity = (p['quantity'] is int) ? p['quantity'] as int : 0;
      return s + (price * quantity);
    });

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: FutureBuilder<String>(
                      future: fetchSellerName(sellerId),
                      builder: (_, s) => Text(s.data ?? 'Loading seller…',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: pending ? Colors.orange[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12)),
                child: Text(pending ? 'Pending' : 'Completed',
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            pending ? Colors.orange[800] : Colors.green[800])),
              )
            ]),
            const SizedBox(height: 12),
            ...prods.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8)),
                      child: (p['imageUrl'] != null &&
                              _getImageUrl(p['imageUrl']).isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(_getImageUrl(p['imageUrl']),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image_not_supported)))
                          : const Icon(Icons.image_not_supported)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(p['title']?.toString() ?? 'Unknown Product',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('× ${p['quantity'] ?? 0} pcs',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]))
                      ])),
                  Text(
                      'Php: ${((p['price'] is num) ? (p['price'] as num).toDouble() : 0.0).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold))
                ]))),
            const SizedBox(height: 8),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$totalItems items',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              Text('Total Price: ${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 12),
            pending
                ? SizedBox(
                    width: double.infinity,
                    child: FutureBuilder<String>(
                        future: fetchSellerName(sellerId),
                        builder: (_, sellerSnap) => OutlinedButton(
                            onPressed: sendMessage != null
                                ? () => sendMessage!(sellerId,
                                    sellerSnap.data ?? 'Unknown Seller')
                                : null,
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blue)),
                            child: const Text('Send a message',
                                style: TextStyle(color: Colors.blue)))))
                : Row(children: [
                    Expanded(
                        child: OutlinedButton.icon(
                            onPressed: () => writeReview(prods.first),
                            icon: const Icon(Icons.rate_review,
                                color: Colors.blue),
                            label: const Text('Review',
                                style: TextStyle(color: Colors.blue)),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blue)))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: ElevatedButton.icon(
                            onPressed: () => addToCart(prods.first),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC67B),
                                foregroundColor: Colors.black),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Add to cart')))
                  ])
          ])),
    );
  }

  String _getImageUrl(dynamic imageUrl) {
    if (imageUrl == null) return '';

    if (imageUrl is String) {
      return imageUrl;
    } else if (imageUrl is List && imageUrl.isNotEmpty) {
      return imageUrl.first.toString();
    }

    return '';
  }
}
