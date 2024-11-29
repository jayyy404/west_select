import 'package:cc206_west_select/firebase/app_user.dart';
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
          icon: const Icon(Icons.chevron_left, size: 30,),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4,
                          child: SizedBox(
                            height: 100, // Fixed height for all items
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1, // Restrict to one line
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Flexible(
                                          child: Text(
                                            item.subtitle,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1, // Restrict to one line
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Php ${item.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantity Controls
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          cart.updateQuantity(item, item.quantity - 1);
                                        },
                                      ),
                                      Text(
                                        item.quantity.toString(),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          cart.updateQuantity(item, item.quantity + 1);
                                        },
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
                      Text(
                        "Total: Php ${cart.totalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

                            // Fetch user data from Firestore
                            final userDoc = await FirebaseFirestore.instance
                                .collection(
                                  'users')  // Make sure this is the correct collection name
                                .doc(user.uid)
                                .get();

                            if (!userDoc.exists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("User data not found!"),
                                ),
                              );
                              return;
                            }

                            final appUser =
                                AppUser.fromFirestore(userDoc.data()!);
                            final displayName =
                                appUser.displayName ?? 'Anonymous';

                            final orderData = {
                              'user_name': displayName,
                              'user_email': user.email,
                              'total_price': cart.totalPrice,
                              'products': cart.items.map((item) {
                                return {
                                  'title': item.title,
                                  'subtitle': item.subtitle,
                                  'price': item.price,
                                  'quantity': item.quantity,
                                  'imageUrl': item.imageUrl,
                                };
                              }).toList(),
                              'created_at': FieldValue.serverTimestamp(),
                            };

                            // Add the order data to Firestore
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .add(orderData);

                            cart.clear(); // Clear the cart after checkout
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
