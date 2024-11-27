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
      appBar: AppBar(
        title: Text("Shopping Cart (${cart.items.length})"),
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text("Your cart is empty."))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        child: ListTile(
                          leading: Image.network(item.imageUrl),
                          title: Text(item.title),
                          subtitle: Text('${item.subtitle}\nPHP ${item.price}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  cart.updateQuantity(item, item.quantity - 1);
                                },
                              ),
                              Text(item.quantity.toString()),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  cart.updateQuantity(item, item.quantity + 1);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  cart.removeItem(item);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total: PHP ${cart.totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 18)),
                      ElevatedButton(
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
                                    'users') // Make sure this is the correct collection name
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
