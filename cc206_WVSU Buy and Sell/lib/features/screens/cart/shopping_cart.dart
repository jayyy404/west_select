import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingCartPage extends StatelessWidget {
  const ShoppingCartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

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
          ? const Center(child: Text("Your cart is empty."))
          : Column(
              children: [
                // Product List
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 2.0),
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
                                      // Implement select/deselect functionality here
                                    },
                                    child: Container(
                                      height: 24,
                                      width: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      item.imageUrl,
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
                                        const SizedBox(height: 2),
                                        Text(
                                          'Seller: ${item.sellerName}\n',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        Text(
                                          'PHP ${item.price}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors
                                                .green, // Set the price color to green
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantity Controls
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                cart.updateQuantity(
                                                    item, item.quantity - 1);
                                              },
                                              child: Container(
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
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
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () {
                                                cart.updateQuantity(
                                                    item, item.quantity + 1);
                                              },
                                              child: Container(
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 14,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bottom Bar
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 6,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Total Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "PHP ${cart.totalPrice.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Checkout Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () async {
                          if (cart.items.isNotEmpty) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("You need to log in first!"),
                                ),
                              );
                              return;
                            }

                            // Create the order and save it to Firestore (same logic as before)
                            final orderData = {
                              'buyerId': user.uid,
                              'buyerName': user.displayName ?? 'Anonymous',
                              'buyerEmail': user.email,
                              'total_price': cart.totalPrice,
                              'products': cart.items.map((item) {
                                return {
                                  'productId': item.id,
                                  'title': item.title,
                                  'price': item.price,
                                  'quantity': item.quantity,
                                  'imageUrl': item.imageUrl,
                                  'sellerId': item.sellerId,
                                };
                              }).toList(),
                              'created_at': FieldValue.serverTimestamp(),
                              'status': 'pending',
                            };

                            final orderRef = await FirebaseFirestore.instance
                                .collection('orders')
                                .add(orderData);

                            await orderRef.update({
                              'orderId': orderRef.id,
                            });

                            cart.clear();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Order placed successfully!"),
                              ),
                            );
                          }
                        },
                        child: Text("Checkout (${cart.items.length})"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
