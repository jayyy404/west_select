import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cc206_west_select/firebase/notification_service.dart';
import 'package:cc206_west_select/services/notification_service.dart'
    as local_notification;

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  final Map<String, bool> selectedItems = {};
  bool selectAll = false;
  final Map<String, String> _sellerNameCache = {};
  final Map<String, int> _productStockCache = {};

  Future<int> fetchProductStock(String productId) async {
    if (_productStockCache.containsKey(productId)) {
      return _productStockCache[productId]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('post')
          .doc(productId)
          .get();
      final stock = doc.data()?['stock'] ?? 0;
      _productStockCache[productId] = stock;
      return stock;
    } catch (e) {
      debugPrint('Error fetching product stock: $e');
      return 0;
    }
  }

  Future<void> _preloadProductStock(List<CartItem> items) async {
    final uncachedProductIds = items
        .map((e) => e.id)
        .toSet()
        .where((id) => !_productStockCache.containsKey(id))
        .toList();
    if (uncachedProductIds.isEmpty) return;

    try {
      final futures = uncachedProductIds.map((id) async {
        try {
          final doc =
              await FirebaseFirestore.instance.collection('post').doc(id).get();
          final stock = doc.data()?['stock'] ?? 0;
          _productStockCache[id] = stock;
        } catch (e) {
          _productStockCache[id] = 0;
        }
      });
      await Future.wait(futures);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error preloading product stock: $e');
    }
  }

  Future<String> fetchSellerName(String sellerId) async {
    if (_sellerNameCache.containsKey(sellerId)) {
      return _sellerNameCache[sellerId]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();
      final sellerName = doc.data()?['displayName'] ?? 'Unknown Seller';
      _sellerNameCache[sellerId] = sellerName;
      return sellerName;
    } catch (e) {
      debugPrint('Error fetching seller name: $e');
      _sellerNameCache[sellerId] = 'Unknown Seller';
      return 'Unknown Seller';
    }
  }

  Future<void> _preloadSellerNames(List<CartItem> items) async {
    final uncachedSellerIds = items
        .map((e) => e.sellerId)
        .toSet()
        .where((id) => !_sellerNameCache.containsKey(id))
        .toList();
    if (uncachedSellerIds.isEmpty) return;

    try {
      final futures = uncachedSellerIds.map((id) async {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(id)
              .get();
          final name = doc.data()?['displayName'] ?? 'Unknown Seller';
          _sellerNameCache[id] = name;
        } catch (e) {
          _sellerNameCache[id] = 'Unknown Seller';
        }
      });
      await Future.wait(futures);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error preloading seller names: $e');
    }
  }

  void toggleSelectAll(bool value, List<CartItem> items) {
    setState(() {
      selectAll = value;
      for (final item in items) {
        selectedItems[item.id] = value;
      }
    });
  }

  double calculateTotal(List<CartItem> items) {
    return items
        .where((item) => selectedItems[item.id] == true)
        .fold(0.0, (sum, item) => sum + item.price * item.quantity);
  }

  double calculateTotalForItems(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  }

  Future<void> _processOrderInBackground(
    Map<String, dynamic> orderData,
    List<CartItem> selectedForCheckout,
    User user,
  ) async {
    try {
      final orderRef =
          await FirebaseFirestore.instance.collection('orders').add(orderData);
      await orderRef.update({'orderId': orderRef.id});

      final localNotificationService = local_notification.NotificationService();
      final buyerName = user.displayName ?? 'Unknown Buyer';

      final itemsBySeller = <String, List<CartItem>>{};
      for (final item in selectedForCheckout) {
        itemsBySeller.putIfAbsent(item.sellerId, () => []).add(item);
      }

      final notificationFutures = itemsBySeller.entries.map((entry) async {
        final sellerId = entry.key;
        final items = entry.value;
        final productNames = items.map((i) => i.title).join(', ');
        final itemCount = items.length;

        await Future.wait([
          NotificationService.instance.sendPushNotification(
            recipientUserId: sellerId,
            title:
                'You\'ve got ${itemCount == 1 ? 'a new order' : '$itemCount new orders'}!',
            body: itemCount == 1
                ? '${items.first.title} was just purchased.'
                : '$productNames were just purchased.',
            data: {
              'type': 'order',
              'productId': items.first.id,
              'productName': productNames,
              'buyerName': buyerName,
            },
          ),
          localNotificationService.createOrderNotification(
            sellerId: sellerId,
            productName:
                itemCount == 1 ? items.first.title : '$itemCount items',
            buyerName: buyerName,
            productId: items.first.id,
          ),
        ]);
      });

      await Future.wait(notificationFutures);
    } catch (e) {
      debugPrint('Background order processing error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = Provider.of<CartModel>(context, listen: false);
      _preloadSellerNames(cart.items);
      _preloadProductStock(cart.items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

    // Initialize selectedItems map if not present
    for (final item in cart.items) {
      selectedItems.putIfAbsent(item.id, () => false);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Shopping Cart (${cart.items.length})"),
        centerTitle: true,
        elevation: 0,
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return FutureBuilder<List<dynamic>>(
                          future: Future.wait([
                            fetchSellerName(item.sellerId),
                            fetchProductStock(item.id),
                          ]),
                          builder: (context, snapshot) {
                            final sellerName =
                                snapshot.data?[0] ?? 'Loading seller...';
                            final stockQuantity = snapshot.data?[1] ?? 0;
                            final isOutOfStock = stockQuantity <= 0;

                            return Opacity(
                              opacity: isOutOfStock ? 0.5 : 1.0,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 4.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.0)),
                                  elevation: 4,
                                  child: SizedBox(
                                    height: 100,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: isOutOfStock
                                                ? null
                                                : () {
                                                    setState(() {
                                                      selectedItems[item.id] =
                                                          !(selectedItems[
                                                                  item.id] ??
                                                              false);
                                                      selectAll = selectedItems
                                                          .values
                                                          .every((isSelected) =>
                                                              isSelected);
                                                    });
                                                  },
                                            child: Container(
                                              height: 24,
                                              width: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isOutOfStock
                                                    ? Colors.grey[200]
                                                    : (selectedItems[item.id] ==
                                                            true
                                                        ? Colors.blue
                                                        : Colors.grey[300]),
                                                border: isOutOfStock
                                                    ? Border.all(
                                                        color: Colors
                                                            .grey.shade400)
                                                    : null,
                                              ),
                                              child: (selectedItems[item.id] ==
                                                          true &&
                                                      !isOutOfStock)
                                                  ? const Icon(Icons.check,
                                                      size: 16,
                                                      color: Colors.white)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Product Image with overlay if out of stock
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: Image.network(
                                                  item.imageUrls.isNotEmpty
                                                      ? item.imageUrls.first
                                                      : '',
                                                  height: 60,
                                                  width: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Container(
                                                    height: 60,
                                                    width: 60,
                                                    color: Colors.grey[300],
                                                    alignment: Alignment.center,
                                                    child: const Icon(Icons
                                                        .image_not_supported),
                                                  ),
                                                ),
                                              ),
                                              if (isOutOfStock)
                                                Container(
                                                  height: 60,
                                                  width: 60,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                  child: const Text(
                                                    'OUT OF\nSTOCK',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          // Product details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: isOutOfStock
                                                        ? Colors.grey
                                                        : Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Seller: $sellerName',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'PHP ${item.price.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isOutOfStock
                                                            ? Colors.grey
                                                            : Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 80,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: isOutOfStock
                                                          ? null
                                                          : () {
                                                              final newQuantity =
                                                                  item.quantity -
                                                                      1;
                                                              if (newQuantity >=
                                                                  1) {
                                                                cart.updateQuantity(
                                                                    item,
                                                                    newQuantity);
                                                              }
                                                            },
                                                      child: Container(
                                                        height: 18,
                                                        width: 18,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: isOutOfStock
                                                              ? Colors.grey[200]
                                                              : Colors
                                                                  .grey[300],
                                                        ),
                                                        alignment:
                                                            Alignment.center,
                                                        child: Icon(
                                                          Icons.remove,
                                                          size: 12,
                                                          color: isOutOfStock
                                                              ? Colors.grey
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 24,
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        item.quantity
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isOutOfStock
                                                              ? Colors.grey
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: isOutOfStock
                                                          ? null
                                                          : () {
                                                              final newQuantity =
                                                                  item.quantity +
                                                                      1;
                                                              cart.updateQuantity(
                                                                  item,
                                                                  newQuantity);
                                                            },
                                                      child: Container(
                                                        height: 18,
                                                        width: 18,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: isOutOfStock
                                                              ? Colors.grey[200]
                                                              : Colors
                                                                  .grey[300],
                                                        ),
                                                        alignment:
                                                            Alignment.center,
                                                        child: Icon(
                                                          Icons.add,
                                                          size: 12,
                                                          color: isOutOfStock
                                                              ? Colors.grey
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () =>
                                                      cart.removeItem(item),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => toggleSelectAll(!selectAll, cart.items),
                          child: Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.grey.shade600, width: 2),
                              color: selectAll
                                  ? const Color(0xFFFFA42D)
                                  : Colors.transparent,
                            ),
                            child: selectAll
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('All', style: TextStyle(fontSize: 15)),
                        const Spacer(),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 14)),
                            const SizedBox(height: 5),
                            Text(
                              '₱ ${NumberFormat('#,##0').format(calculateTotal(cart.items))}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE6003D),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 10),
                            backgroundColor: const Color(0xFFFFA42D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final selectedForCheckout = cart.items
                                .where((item) => selectedItems[item.id] == true)
                                .toList();

                            if (selectedForCheckout.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('No items selected!'),
                                    duration: Duration(seconds: 2)),
                              );
                              return;
                            }

                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('You need to log in first!'),
                                    duration: Duration(seconds: 2)),
                              );
                              return;
                            }

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                  child: CircularProgressIndicator()),
                            );

                            try {
                              final List<CartItem> itemsToCheckout = [];
                              final List<CartItem> itemsToKeep = [];

                              for (var item in selectedForCheckout) {
                                final productDoc = await FirebaseFirestore
                                    .instance
                                    .collection('post')
                                    .doc(item.id)
                                    .get();
                                if (!productDoc.exists) {
                                  cart.removeItem(item);
                                  continue;
                                }

                                final availableStock =
                                    productDoc.data()?['stock'] ?? 0;

                                if (availableStock <= 0) {
                                  itemsToKeep.add(item);
                                } else if (item.quantity <= availableStock) {
                                  itemsToCheckout.add(item);
                                } else {
                                  final checkoutItem = CartItem(
                                    id: item.id,
                                    title: item.title,
                                    price: item.price,
                                    imageUrls: item.imageUrls,
                                    sellerId: item.sellerId,
                                    quantity: availableStock,
                                    size: item.size,
                                  );

                                  item.quantity -= (availableStock as int);
                                  itemsToCheckout.add(checkoutItem);
                                  itemsToKeep.add(item);
                                }
                              }

                              if (itemsToCheckout.isEmpty) {
                                if (Navigator.canPop(context)) {
                                  Navigator.of(context).pop();
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'The items you selected are out of stock!'),
                                      duration: Duration(seconds: 3)),
                                );
                                return;
                              }

                              for (var item in itemsToCheckout) {
                                if (!itemsToKeep.any((keepItem) =>
                                    keepItem.id == item.id &&
                                    keepItem.size == item.size)) {
                                  cart.removeItem(item);
                                }
                              }

                              setState(() {
                                for (var item in selectedForCheckout) {
                                  selectedItems.remove(item.id);
                                }
                                selectAll = false;
                              });

                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }

                              if (itemsToKeep.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'You exceeded the stock for some items. They have been kept in your cart.'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Order placed successfully!'),
                                    duration: Duration(seconds: 2)),
                              );

                              final orderData = {
                                'buyerId': user.uid,
                                'buyerName': user.displayName ?? 'Anonymous',
                                'buyerEmail': user.email,
                                'total_price':
                                    calculateTotalForItems(itemsToCheckout),
                                'products': itemsToCheckout.map((item) {
                                  return {
                                    'productId': item.id,
                                    'title': item.title,
                                    'price': item.price,
                                    'quantity': item.quantity,
                                    'imageUrl': item.imageUrls,
                                    'sellerId': item.sellerId,
                                    'size': item.size,
                                  };
                                }).toList(),
                                'created_at': FieldValue.serverTimestamp(),
                                'status': 'pending',
                              };

                              await _processOrderInBackground(
                                  orderData, itemsToCheckout, user);
                            } catch (e) {
                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error placing order: $e')),
                              );
                            }
                          },
                          child: Text(
                            'Checkout\n(${cart.items.where((i) => selectedItems[i.id] == true).length} item${cart.items.where((i) => selectedItems[i.id] == true).length == 1 ? '' : 's'})',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
