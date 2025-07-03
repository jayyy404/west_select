import 'package:cc206_west_select/features/screens/listing/orders/order_card.dart';
import 'package:cc206_west_select/features/screens/listing/orders/order_service.dart';
import 'package:cc206_west_select/features/screens/listing/orders/product_review_Card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  final Map<String, String> _buyerNames = {};
  final Map<String, String> _buyerProfileUrls = {};
  final Map<String, List<String>> _productImgs = {};

  Map<String, int> _counts = {'pending': 0, 'completed': 0, 'reviews': 0};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    _counts = await OrderService.loadTabCounts(me);
    if (mounted) setState(() {});
  }

  Future<void> _ensureBuyerName(String buyerId) async {
    if (_buyerNames.containsKey(buyerId)) return;
    final user = await OrderService.fetchBuyer(buyerId);
    _buyerNames[buyerId] = user['name']!;
    _buyerProfileUrls[buyerId] = user['avatar']!;
  }

  Future<void> _ensureProductImg(String productId) async {
    if (_productImgs.containsKey(productId)) return;
    _productImgs[productId] = await OrderService.fetchProductImgs(productId);
  }

  Widget _pendingTab() => _ordersTab(
        collection: 'orders',
        statusLabel: 'Pending',
        statusColor: Colors.orange,
        showCompleteBtn: true,
      );

  Widget _completedTab() => _ordersTab(
        collection: 'completed_orders',
        statusLabel: 'Completed',
        statusColor: Colors.green,
        showCompleteBtn: false,
      );

  Widget _ordersTab({
    required String collection,
    required String statusLabel,
    required Color statusColor,
    required bool showCompleteBtn,
  }) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return const Center(child: Text('User not logged in'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data!.docs.where((d) {
          final prods = (d['products'] as List<dynamic>);
          return prods.any((p) => p['sellerId'] == me);
        }).toList();
        if (orders.isEmpty) {
          return Center(child: Text('No $statusLabel orders.'));
        }

        return FutureBuilder(
          future: Future.wait([
            ...orders.map((o) => _ensureBuyerName(o['buyerId'])),
            ...orders.expand((o) => (o['products'] as List<dynamic>)).map(
                  (p) => _ensureProductImg(p['productId']),
                ),
          ]),
          builder: (_, f) {
            if (f.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final o = orders[i];
                final id = o.id;
                final buyerId = o['buyerId'];
                final prods = (o['products'] as List<dynamic>)
                    .where((p) => p['sellerId'] == me)
                    .toList();

                return OrderCard(
                  orderId: id,
                  buyerId: buyerId,
                  buyerName: _buyerNames[buyerId] ?? 'Unknown Buyer',
                  buyerAvatar: _buyerProfileUrls[buyerId] ?? '',
                  products: prods,
                  imgs: _productImgs,
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                  onComplete: showCompleteBtn
                      ? () async {
                          await OrderService.completeOrder(id, prods, context);
                          _loadCounts();
                        }
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _reviewsTab() {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return const Center(child: Text('User not logged in'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('post')
          .where('post_users', isEqualTo: me)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snap.data!.docs;
        if (products.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        return FutureBuilder(
          future: OrderService.fetchProductReviews(products),
          builder: (_, r) {
            if (!r.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = r.data!;
            if (all.isEmpty) {
              return const Center(child: Text('No reviews yet'));
            }

            // group reviews by product
            final Map<String, List<Map<String, dynamic>>> grouped = {};
            for (final rev in all) {
              (grouped[rev['productId']] ??= []).add(rev);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (_, i) {
                final pid = grouped.keys.elementAt(i);
                final list = grouped[pid]!;
                final first = list.first;

                return ProductReviewCard(
                  productId: pid,
                  productTitle: first['productTitle'],
                  productImage: first['productImage'],
                  reviews: list,
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context)),
          title: const Text('All orders',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabs,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: 'Pending(${_counts['pending']})'),
              Tab(text: 'Complete(${_counts['completed']})'),
              Tab(text: 'Reviews(${_counts['reviews']})'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _pendingTab(),
            _completedTab(),
            _reviewsTab(),
          ],
        ),
      );
}
