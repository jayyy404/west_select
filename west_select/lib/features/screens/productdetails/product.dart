import 'package:cc206_west_select/features/screens/message/message_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cc206_west_select/features/screens/cart/cart_model.dart';
import 'package:cc206_west_select/features/screens/profile/profile_page.dart';
import 'package:cc206_west_select/firebase/app_user.dart';
import '../favorite/favorite_model.dart';

class Product {
  final List<String> imageUrls;
  final String productTitle;
  final String description;
  final double price;
  final String sellerName;
  final String userId;

  Product({
    required this.imageUrls,
    required this.productTitle,
    required this.description,
    required this.price,
    required this.sellerName,
    required this.userId,
  });

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      imageUrls: List<String>.from(data['image_urls'] ?? []),
      productTitle: data['post_title'] ?? '',
      description: data['post_description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      userId: data['post_users'] ?? '',
      sellerName: data['sellerName'] ?? '',
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? currentUser = FirebaseAuth.instance.currentUser?.uid;
  Product? product;
  int quantity = 1;
  int _currentImageIndex = 0;
  bool isFavorite = false;
  bool isLoadingProduct = true;
  bool isLoadingFavorite = true;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  Future<void> fetchProduct() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.productId)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      final postUserId = data?['post_users'];
      final sellerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postUserId)
          .get();

      String displayName = sellerDoc.data()?['displayName'] ?? 'Unknown';

      setState(() {
        product = Product.fromMap({
          ...?data,
          'sellerName': displayName,
          'userId': postUserId,
        });
        isLoadingProduct = false;
      });

      checkIfFavorite();
    } catch (e) {
      print("Error: $e");
    }
  }

/*************  ✨ Windsurf Command ⭐  *************/
  /// Checks if the current product is marked as a favorite by the current user.
  ///
  /// It queries the 'favorites' collection in Firestore using the
  /// current user's ID to retrieve the list of favorite items.
  /// The method sets the `isFavorite` flag to true if the product
  /// with the given `productId` is found in the user's favorites.
  /// The `isLoadingFavorite` flag is set to false after the check
  /// is completed, regardless of success or failure.

/*******  119597dc-1e1d-426c-ac4e-03298c18ef23  *******/ Future<void>
      checkIfFavorite() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(currentUser)
          .get();

      final items = doc.data()?['items'] ?? [];
      isFavorite = items.any((item) => item['id'] == widget.productId);
      setState(() => isLoadingFavorite = false);
    } catch (e) {
      setState(() => isLoadingFavorite = false);
    }
  }

  void _navigateToMessagePage() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send messages')),
      );
      return;
    }

    if (product == null) return;

    if (currentUser == product!.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(
          receiverId: product!.userId,
          userName: product!.sellerName,
          productName: product!.productTitle,
          productPrice: product!.price,
          productImage: product!.imageUrls.first,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context, listen: false);
    final favoriteModel = Provider.of<FavoriteModel>(context);

    return Scaffold(
      body: isLoadingProduct || product == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: product!.imageUrls.length,
                          onPageChanged: (index) =>
                              setState(() => _currentImageIndex = index),
                          itemBuilder: (_, index) => Image.network(
                            product!.imageUrls[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product!.imageUrls.length,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  leading: BackButton(color: Colors.white),
                  actions: [
                    isLoadingFavorite
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2.0))
                        : IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.white,
                            ),
                            onPressed: () {
                              final map = {
                                'id': widget.productId,
                                'title': product!.productTitle,
                                'imageUrls': product!.imageUrls.join(','),
                                'price': product!.price.toString(),
                                'seller': product!.sellerName,
                              };

                              if (isFavorite) {
                                favoriteModel.removeFavorite(currentUser!, map);
                              } else {
                                favoriteModel.addFavorite(currentUser!, map);
                              }

                              setState(() => isFavorite = !isFavorite);
                            },
                          ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product!.productTitle,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          'PHP ${NumberFormat('#,##0.00', 'en_US').format(product!.price)}',
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text('Description',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(product!.description,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 24),
                        const Text('Seller Details',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              child: Icon(Icons.person),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfilePage(
                                        appUser: AppUser(
                                          uid: product!.userId,
                                          displayName: product!.sellerName,
                                          email: '',
                                          userListings: [],
                                          orderHistory: [],
                                          fcmTokens: [],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  product!.sellerName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.message,
                                color: Colors.blue,
                              ),
                              onPressed: _navigateToMessagePage,
                              tooltip: 'Message Seller',
                            ),
                          ],
                        ),

                        // ------------------- REVIEWS SECTION -------------------
                        const SizedBox(height: 24),
                        const Divider(),
                        const Text('Reviews',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('post')
                              .doc(widget.productId)
                              .collection('reviews')
                              .doc(currentUser)
                              .get(),
                          builder: (context, snapshot) {
                            String existingComment = '';
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data()
                                  as Map<String, dynamic>?;
                              existingComment = data?['comment'] ?? '';
                            }

                            final TextEditingController reviewController =
                                TextEditingController(text: existingComment);

                            final hasReview =
                                snapshot.hasData && snapshot.data!.exists;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasReview) ...[
                                  Text(
                                    existingComment,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      TextButton(
                                        child: const Text("Edit"),
                                        onPressed: () async {
                                          final newComment =
                                              await showDialog<String>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text("Edit Review"),
                                              content: TextField(
                                                controller: reviewController,
                                                maxLines: 3,
                                                decoration:
                                                    const InputDecoration(
                                                        hintText:
                                                            "Your review"),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, null),
                                                  child: const Text("Cancel"),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context,
                                                          reviewController
                                                              .text),
                                                  child: const Text("Save"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (newComment != null &&
                                              newComment.trim().isNotEmpty) {
                                            await FirebaseFirestore.instance
                                                .collection('post')
                                                .doc(widget.productId)
                                                .collection('reviews')
                                                .doc(currentUser)
                                                .set({
                                              'comment': newComment.trim(),
                                              'createdAt':
                                                  FieldValue.serverTimestamp(),
                                              'userId': currentUser,
                                            });
                                            setState(() {});
                                          }
                                        },
                                      ),
                                      TextButton(
                                        child: const Text("Delete"),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('post')
                                              .doc(widget.productId)
                                              .collection('reviews')
                                              .doc(currentUser)
                                              .delete();
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  TextField(
                                    controller: reviewController,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: "Write a review",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final comment =
                                          reviewController.text.trim();
                                      if (comment.isNotEmpty) {
                                        await FirebaseFirestore.instance
                                            .collection('post')
                                            .doc(widget.productId)
                                            .collection('reviews')
                                            .doc(currentUser)
                                            .set({
                                          'comment': comment,
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                          'userId': currentUser,
                                        });
                                        setState(() {});
                                      }
                                    },
                                    child: const Text("Post Review"),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                        const Text('All Reviews',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('post')
                              .doc(widget.productId)
                              .collection('reviews')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text("No reviews yet.");
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final reviewDoc = snapshot.data!.docs[index];

                                if (!reviewDoc.exists) {
                                  return const ListTile(
                                    title: Text("Review not found"),
                                    subtitle: Text(
                                        "This review may have been deleted."),
                                  );
                                }

                                final data =
                                    reviewDoc.data() as Map<String, dynamic>?;

                                if (data == null ||
                                    !data.containsKey('comment') ||
                                    !data.containsKey('userId')) {
                                  return const ListTile(
                                    title: Text("Incomplete review"),
                                    subtitle: Text(
                                        "Missing comment or user information."),
                                  );
                                }

                                final comment = data['comment'];
                                final userId = data['userId'];

                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .get(),
                                  builder: (context, userSnap) {
                                    String username = 'Anonymous';
                                    if (userSnap.hasData &&
                                        userSnap.data != null &&
                                        userSnap.data!.exists) {
                                      final userData = userSnap.data!.data()
                                          as Map<String, dynamic>?;
                                      username = userData?['displayName'] ??
                                          'Anonymous';
                                    }

                                    return ListTile(
                                      leading: const CircleAvatar(
                                          child: Icon(Icons.person)),
                                      title: Text(username),
                                      subtitle: Text(comment),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: product == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Text("Quantity:"),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (quantity > 1) quantity--;
                      });
                    },
                  ),
                  Text(quantity.toString()),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        quantity++;
                      });
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      cart.addToCart(
                        widget.productId,
                        product!.productTitle,
                        product!.price,
                        [product!.imageUrls.first],
                        product!.userId,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('${product!.productTitle} added to cart')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFA42D),
                    ),
                    child: const Text("Add to Cart"),
                  )
                ],
              ),
            ),
    );
  }
}
