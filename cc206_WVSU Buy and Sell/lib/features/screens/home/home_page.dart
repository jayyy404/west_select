import 'package:cc206_west_select/features/screens/cart/shopping_cart.dart';
import 'package:cc206_west_select/features/screens/productdetails/product.dart';
import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cc206_west_select/features/screens/listing.dart';

class HomePage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search an item...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ShoppingCartPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('post').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error fetching listings"));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No listings available"));
          } else {
            final listings = snapshot.data!.docs.map((doc) {
              return Listing.fromFirestore(doc.data() as Map<String, dynamic>);
            }).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "This Week's Listing",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];

                        return GestureDetector(
                          onTap: () {
                            // Fetch the seller name asynchronously
                            _firestore
                                .collection('users')
                                .doc(listing.postUserId)
                                .get()
                                .then((userSnapshot) {
                              if (userSnapshot.exists) {
                                final userData =
                                    userSnapshot.data() as Map<String, dynamic>;
                                final appUser = AppUser.fromFirestore(userData);
                                final sellerName =
                                    appUser.displayName ?? 'Unknown Seller';

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(
                                      imageUrl: listing.imageUrl,
                                      productTitle: listing.postTitle,
                                      description: listing.postDescription,
                                      price: listing.price,
                                      sellerName: sellerName,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(
                                      imageUrl: listing.imageUrl,
                                      productTitle: listing.postTitle,
                                      description: listing.postDescription,
                                      price: listing.price,
                                      sellerName: 'Unknown Seller',
                                    ),
                                  ),
                                );
                              }
                            });
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          listing.imageUrl.isNotEmpty
                                              ? listing.imageUrl
                                              : 'https://via.placeholder.com/150',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing.postTitle,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'PHP ${listing.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: Colors.green),
                                      ),
                                      const SizedBox(height: 4),
                                      FutureBuilder<DocumentSnapshot>(
                                        future: _firestore
                                            .collection('users')
                                            .doc(listing.postUserId)
                                            .get(),
                                        builder: (context, userSnapshot) {
                                          if (userSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text('Loading...');
                                          } else if (userSnapshot.hasError ||
                                              !userSnapshot.hasData ||
                                              !userSnapshot.data!.exists) {
                                            return const Text('Unknown Seller');
                                          }

                                          final userData = userSnapshot.data!
                                              .data() as Map<String, dynamic>;
                                          final appUser =
                                              AppUser.fromFirestore(userData);
                                          final sellerName =
                                              appUser.displayName ??
                                                  'Unknown Seller';

                                          return Text(
                                            sellerName,
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
