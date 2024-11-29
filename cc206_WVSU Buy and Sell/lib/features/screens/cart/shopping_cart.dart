import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({Key? key}) : super(key: key);

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  List<bool> selectedItems = [];  
  bool selectAll = false;  

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartModel>(context, listen: false);
    selectedItems = List<bool>.filled(cart.items.length, false); // Initialize all as unselected
  }

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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
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
                                        selectedItems[index] = !selectedItems[index];
                                        selectAll = selectedItems.every((isSelected) => isSelected);
                                      });
                                    },
                                    child: Container(
                                      height: 24,
                                      width: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selectedItems[index] ? Colors.blue : Colors.grey,
                                          width: 2,
                                        ),
                                        color: selectedItems[index] ? Colors.blue : Colors.transparent,
                                      ),
                                      child: selectedItems[index]
                                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12), // space between checkbox n image
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
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Flexible(
                                        child: Text(
                                          item.subtitle,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Flexible(
                                        child: Text(
                                          'Php ${item.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1, 
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                 // Quantity Controls
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,  
                                    children: [
                                      const SizedBox(height: 40),  
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],  
                                          borderRadius: BorderRadius.circular(20), // Capsule shape
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),  
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,  
                                          children: [
                                            // - button
                                            GestureDetector(
                                              onTap: () {
                                                cart.updateQuantity(item, item.quantity - 1);
                                              },
                                              child: Container(
                                                height: 20,  
                                                width: 20,   
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent, // bg color for button
                                                  shape: BoxShape.circle,  
                                                ),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.remove,
                                                  size: 14, // Icon size
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
                                            // + button
                                            GestureDetector(
                                              onTap: () {
                                                cart.updateQuantity(item, item.quantity + 1);
                                              },
                                              child: Container(
                                                height: 20, 
                                                width: 20,   
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent, // bg color for button
                                                  shape: BoxShape.circle,  
                                                ),
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 14, // Icon size
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
                      // Select All Circular Checkbox
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectAll = !selectAll;
                            selectedItems = List<bool>.filled(cart.items.length, selectAll);
                          });
                        },
                        child: Container(
                          height: 24,
                          width: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectAll ? Colors.blue : Colors.grey,
                              width: 2,
                            ),
                            color: selectAll ? Colors.blue : Colors.transparent,
                          ),
                          child: selectAll
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("All"),
                      const Spacer(),
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
                          "Php ${cart.totalPrice.toStringAsFixed(2)}",
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

                            // Filter selected items
                            final selectedCartItems = cart.items
                                .asMap()
                                .entries
                                .where((entry) => selectedItems[entry.key])
                                .map((entry) => entry.value)
                                .toList();

                            if (selectedCartItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("No items selected for checkout."),
                                ),
                              );
                              return;
                            }

                            // Fetch user data from Firestore
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users') // ensure this correct collection name
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

                            final appUser = AppUser.fromFirestore(userDoc.data()!);
                            final displayName = appUser.displayName ?? 'Anonymous';

                            final orderData = {
                              'user_name': displayName,
                              'user_email': user.email,
                              'total_price': selectedCartItems.fold<double>(
                                  0.0, (total, item) => total + (item.price * item.quantity)),
                              'products': selectedCartItems.map((item) {
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

                            // Remove only selected items from the cart
                            for (var item in selectedCartItems) {
                              cart.removeItem(item);
                            }

                            setState(() {
                              // update selectedItems list after removing items
                              selectedItems = List<bool>.filled(cart.items.length, false);
                            });

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
