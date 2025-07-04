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
  const ShoppingCartPage({Key? key}) : super(key: key);

  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  Map<String, bool> selectedItems = {};
  bool selectAll = false;
  Map<String, String> _sellerNameCache = {};

  Future<String> fetchSellerName(String sellerId) async {
    // Check if seller name is already cached
    if (_sellerNameCache.containsKey(sellerId)) {
      return _sellerNameCache[sellerId]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();
      final sellerName = doc.data()?['displayName'] ?? 'Unknown Seller';

      // Cache the fetched seller name
      _sellerNameCache[sellerId] = sellerName;

      return sellerName;
    } catch (e) {
      debugPrint('Error fetching seller name: $e');
      final fallbackName = 'Unknown Seller';
      _sellerNameCache[sellerId] = fallbackName;
      return fallbackName;
    }
  }

  Future<void> _preloadSellerNames(List<CartItem> items) async {
    final uniqueSellerIds = items.map((item) => item.sellerId).toSet();
    final uncachedSellerIds = uniqueSellerIds
        .where((id) => !_sellerNameCache.containsKey(id))
        .toList();

    if (uncachedSellerIds.isEmpty) return;

    try {
      // Fetch all seller names in parallel
      final futures = uncachedSellerIds.map((sellerId) async {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(sellerId)
              .get();
          final name = doc.data()?['displayName'] ?? 'Unknown Seller';
          _sellerNameCache[sellerId] = name;
        } catch (e) {
          _sellerNameCache[sellerId] = 'Unknown Seller';
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
      for (var item in items) {
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

  Future<void> _processOrderInBackground(Map<String, dynamic> orderData,
      List<CartItem> selectedForCheckout, User user) async {
    try {
      final orderRef =
          await FirebaseFirestore.instance.collection('orders').add(orderData);
      await orderRef.update({'orderId': orderRef.id});

      final localNotificationService = local_notification.NotificationService();
      final buyerName = user.displayName ?? 'Unknown Buyer';

      final Map<String, List<CartItem>> itemsBySeller = {};
      for (var item in selectedForCheckout) {
        itemsBySeller.putIfAbsent(item.sellerId, () => []).add(item);
      }

      final notificationFutures = itemsBySeller.entries.map((entry) async {
        final sellerId = entry.key;
        final items = entry.value;

        final productNames = items.map((item) => item.title).join(', ');
        final itemCount = items.length;

        return Future.wait([
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

    for (var item in cart.items) {
      selectedItems.putIfAbsent(item.id, () => false);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
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
                        return FutureBuilder<String>(
                          future: fetchSellerName(item.sellerId),
                          builder: (context, snapshot) {
                            final sellerName =
                                snapshot.data ?? 'Loading seller...';

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 4.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 4,
                                child: SizedBox(
                                  height: 100,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedItems[item.id] =
                                                  !(selectedItems[item.id] ??
                                                      false);
                                              selectAll = selectedItems.values
                                                  .every((isSelected) =>
                                                      isSelected);
                                            });
                                          },
                                          child: Container(
                                            height: 24,
                                            width: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  selectedItems[item.id] == true
                                                      ? Colors.blue
                                                      : Colors.grey[300],
                                            ),
                                            child:
                                                selectedItems[item.id] == true
                                                    ? const Icon(
                                                        Icons.check,
                                                        size: 16,
                                                        color: Colors.white,
                                                      )
                                                    : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Product Image
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
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Product Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Seller: $sellerName',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'PHP ${item.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Quantity Controls
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      cart.updateQuantity(item,
                                                          item.quantity - 1);
                                                    },
                                                    child: Container(
                                                      height: 20,
                                                      width: 20,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.grey[300],
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                        Icons.remove,
                                                        size: 14,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    item.quantity.toString(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () {
                                                      cart.updateQuantity(item,
                                                          item.quantity + 1);
                                                    },
                                                    child: Container(
                                                      height: 20,
                                                      width: 20,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.grey[300],
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                        Icons.add,
                                                        size: 14,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () {
                                                  cart.removeItem(item);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
                        const Spacer(),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 14)),
                            const SizedBox(height: 5),
                            Text(
                              'Php ${NumberFormat('#,##0').format(calculateTotal(cart.items))}',
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
                                horizontal: 50, vertical: 10),
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
                                    content: Text('No items selected!')),
                              );
                              return;
                            }

                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('You need to log in first!')),
                              );
                              return;
                            }

                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              cart.removeMultipleItems(selectedForCheckout);
                              setState(() {
                                for (var item in selectedForCheckout) {
                                  selectedItems.remove(item.id);
                                }
                                selectAll = false;
                              });

                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Order placed successfully!')),
                              );

                              final orderData = {
                                'buyerId': user.uid,
                                'buyerName': user.displayName ?? 'Anonymous',
                                'buyerEmail': user.email,
                                'total_price':
                                    calculateTotalForItems(selectedForCheckout),
                                'products': selectedForCheckout.map((item) {
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
                              _processOrderInBackground(
                                  orderData, selectedForCheckout, user);
                            } catch (e) {
                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Error placing order: ${e.toString()}')),
                              );
                            }
                          },
                          child: Text(
                            'Checkout\n(${cart.items.where((i) => selectedItems[i.id] == true).length} item)',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
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
