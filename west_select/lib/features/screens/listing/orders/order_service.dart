import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

class OrderService {
  static Future<Map<String, int>> loadTabCounts(String uid) async {
    final pending = await FirebaseFirestore.instance.collection('orders').get();
    final completed =
        await FirebaseFirestore.instance.collection('completed_orders').get();
    final products = await FirebaseFirestore.instance
        .collection('post')
        .where('post_users', isEqualTo: uid)
        .get();

    int pendingCnt = 0;
    int completedCnt = 0;
    int reviewsCnt = 0;

    for (final d in pending.docs) {
      if ((d['products'] as List)
          .any((p) => p['sellerId'] == uid && p['status'] != 'completed')) {
        pendingCnt++;
      }
    }
    for (final d in completed.docs) {
      if ((d['products'] as List).any((p) => p['sellerId'] == uid)) {
        completedCnt++;
      }
    }
    for (final p in products.docs) {
      final rev = await p.reference.collection('reviews').get();
      reviewsCnt += rev.docs.length;
    }
    return {
      'pending': pendingCnt,
      'completed': completedCnt,
      'reviews': reviewsCnt
    };
  }

  static Future<Map<String, String>> fetchBuyer(String uid) async {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return {
      'name': snap.data()?['displayName'] ?? 'Unknown Buyer',
      'avatar': snap.data()?['profileImageUrl'] ?? ''
    };
  }

  static Future<List<String>> fetchProductImgs(String pid) async {
    final doc =
        await FirebaseFirestore.instance.collection('products').doc(pid).get();
    if (!doc.exists) return [];
    return List<String>.from(doc['imageUrls'] ?? const []);
  }

  static Future<void> completeOrder(
      String orderId, List<dynamic> sellerProducts, BuildContext ctx) async {
    try {
      final orderRef =
          FirebaseFirestore.instance.collection('orders').doc(orderId);
      final orderDoc = await orderRef.get();
      if (!orderDoc.exists) return;

      final data = orderDoc.data()!;
      final products = List<dynamic>.from(data['products']);

      for (final sp in sellerProducts) {
        final idx =
            products.indexWhere((p) => p['productId'] == sp['productId']);
        if (idx != -1) {
          products[idx]['status'] = 'completed';
          await _reduceStock(sp['productId'], sp['quantity']);
        }
      }

      await orderRef.update({'products': products});

      if (products.every((p) => p['status'] == 'completed')) {
        await FirebaseFirestore.instance
            .collection('completed_orders')
            .doc(orderId)
            .set({...data, 'status': 'completed'});
        await orderRef.delete();

        ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Order completed successfully!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  static Future<void> _reduceStock(String pid, int qty) async {
    final prodRef = FirebaseFirestore.instance.collection('post').doc(pid);
    final doc = await prodRef.get();
    if (!doc.exists) return;

    final stock = (doc['stock'] ?? 0) - qty;
    final sold = (doc['sold'] ?? 0) + qty;

    final update = {'stock': stock.clamp(0, 999999), 'sold': sold};
    if (stock <= 0) update['status'] = 'soldout';
    await prodRef.update(update);
  }

  static Future<List<Map<String, dynamic>>> fetchProductReviews(
      List<QueryDocumentSnapshot> products) async {
    final List<Map<String, dynamic>> res = [];
    for (final p in products) {
      final prodData = p.data() as Map<String, dynamic>;
      final title = prodData['post_title'] ?? 'Unknown';
      final imgs =
          (prodData['image_url'] is List && prodData['image_url'].isNotEmpty)
              ? prodData['image_url'][0]
              : (prodData['image_url'] ?? '');

      final reviews = await p.reference
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      for (final r in reviews.docs) {
        res.add({
          'productId': p.id,
          'productTitle': title,
          'productImage': imgs,
          'reviewData': r.data(),
        });
      }
    }
    return res;
  }
}
