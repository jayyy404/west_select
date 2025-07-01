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

  Future<String> fetchSellerName(String sellerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();
      return doc.data()?['displayName'] ?? 'Unknown Seller';
    } catch (e) {
      debugPrint('Error fetching seller name: $e');
      return 'Unknown Seller';
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

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

    // Initialize selectedItems for first-time usage
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
                  // Product List with Overflow Fix
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
                        top: BorderSide(
                            color: Color(0xFFE0E0E0)), // thin divider
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ─── “All” circular checkbox ────────────────────────
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

                        // ─── Total price (stacked, centered) ────────────────
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
                                color: Color(0xFFE6003D), // vivid pink‑red
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        const SizedBox(width: 20),

                        // ─── Checkout button (stacked) ───────────────────────
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
                            // existing checkout logic (unchanged) ────────────
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
                              final orderData = {
                                'buyerId': user.uid,
                                'buyerName': user.displayName ?? 'Anonymous',
                                'buyerEmail': user.email,
                                'total_price': calculateTotal(cart.items),
                                'products': selectedForCheckout.map((item) {
                                  return {
                                    'productId': item.id,
                                    'title': item.title,
                                    'price': item.price,
                                    'quantity': item.quantity,
                                    'imageUrl': item.imageUrls,
                                    'sellerId': item.sellerId,
                                  };
                                }).toList(),
                                'created_at': FieldValue.serverTimestamp(),
                                'status': 'pending',
                              };

                              final orderRef = await FirebaseFirestore.instance
                                  .collection('orders')
                                  .add(orderData);
                              await orderRef.update({'orderId': orderRef.id});

                              // Send notifications
                              final localNotificationService =
                                  local_notification.NotificationService();
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              final buyerName =
                                  currentUser?.displayName ?? 'Unknown Buyer';

                              for (var item in selectedForCheckout) {
                                // Send push notification
                                await NotificationService.instance
                                    .sendPushNotification(
                                  recipientUserId: item.sellerId,
                                  title: 'You\'ve got a new order!',
                                  body: '${item.title} was just purchased.',
                                  data: {
                                    'type': 'order',
                                    'productId': item.id,
                                    'productName': item.title,
                                    'buyerName': buyerName,
                                  },
                                );

                                // Send in-app notification
                                await localNotificationService
                                    .createOrderNotification(
                                  sellerId: item.sellerId,
                                  productName: item.title,
                                  buyerName: buyerName,
                                  productId: item.id,
                                );
                              }

                              // Remove all selected items at once for faster UI update
                              cart.removeMultipleItems(selectedForCheckout);

                              setState(() {
                                // Clear only the checked out items from selectedItems map
                                for (var item in selectedForCheckout) {
                                  selectedItems.remove(item.id);
                                }
                                selectAll = false;
                              });

                              // Close loading dialog
                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Order placed successfully!')),
                              );
                            } catch (e) {
                              // Close loading dialog on error
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
