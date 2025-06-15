import 'package:cc206_west_select/features/screens/profile/profile_page.dart';
import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart/cart_model.dart';
import '../favorite/favorite_model.dart';
import 'package:intl/intl.dart';

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

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? currentUser = FirebaseAuth.instance.currentUser?.uid;
  int quantity = 1;
  int _currentImageIndex = 0;
  bool isFavorite = false;
  bool isLoadingProduct = true;
  bool isLoadingFavorite = true;
  final PageController _pageController = PageController();
  Product? product;

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  Future<void> checkIfFavorite() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['items'] != null) {
        final items = doc.data()!['items'] as List<dynamic>;
        final found = items.any((item) => item['id'] == widget.productId);

        setState(() {
          isFavorite = found;
          isLoadingFavorite = false;
        });
      } else {
        setState(() => isLoadingFavorite = false);
      }
    } catch (e) {
      print('Error checking favorite: $e');
      setState(() => isLoadingFavorite = false);
    }
  }

  Future<void> fetchProduct() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.productId)
          .get();

      if (!doc.exists) {
        setState(() => isLoadingProduct = false);
        return;
      }

      final data = doc.data();
      if (data == null) {
        setState(() => isLoadingProduct = false);
        return;
      }

      final postUserId = data['post_users'];
      if (postUserId == null || postUserId.isEmpty) {
        print("No post_users found");
        setState(() => isLoadingProduct = false);
        return;
      }

      final sellerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postUserId)
          .get();

      String displayName = "Unknown";
      if (sellerDoc.exists && sellerDoc.data()?['displayName'] != null) {
        displayName = sellerDoc.data()!['displayName'];
      }

      final productData = {
        ...data,
        'sellerName': displayName,
        'userId': postUserId,
      };

      setState(() {
        product = Product.fromMap(productData);
        isLoadingProduct = false;
      });

      checkIfFavorite();
    } catch (e) {
      print("Error loading product: $e");
      setState(() => isLoadingProduct = false);
    }
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
                  expandedHeight: 350,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: product?.imageUrls.length ?? 0,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final imageUrl = product?.imageUrls[index];
                            if (imageUrl == null) {
                              return const SizedBox.shrink();
                            }

                            return Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child:
                                          Icon(Icons.error, color: Colors.red)),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        if (product?.imageUrls != null)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                product!.imageUrls.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white38,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (product?.imageUrls != null)
                          Positioned(
                            bottom: 40.0,
                            right: 16.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${product!.imageUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    isLoadingFavorite
                        ? Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.white,
                            ),
                            onPressed: () async {
                              String finalDisplayName =
                                  product?.sellerName ?? 'Unknown';

                              // Fetch updated displayName from Firestore
                              if (product?.userId != null &&
                                  product!.userId.isNotEmpty) {
                                final sellerDoc = await FirebaseFirestore
                                    .instance
                                    .collection('users')
                                    .doc(product!.userId)
                                    .get();

                                if (sellerDoc.exists &&
                                    sellerDoc.data()?['displayName'] != null) {
                                  finalDisplayName = sellerDoc['displayName'];
                                }
                              }

                              final productMap = {
                                "id": widget.productId,
                                "title": product?.productTitle ?? '',
                                "imageUrls": product?.imageUrls.join(',') ?? '',
                                "price": product?.price.toString() ?? '',
                                "seller": finalDisplayName,
                              };

                              if (isFavorite) {
                                favoriteModel.removeFavorite(
                                    currentUser!, productMap);
                              } else {
                                favoriteModel.addFavorite(
                                    currentUser!, productMap);
                              }

                              setState(() {
                                isFavorite = !isFavorite;
                              });
                            },
                          ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product!.productTitle,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'PHP ${NumberFormat('#,##0.00', 'en_US').format(product!.price)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product!.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Seller Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[300],
                              child: const Icon(Icons.person, size: 24),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () async {
                                final sellerDoc = await FirebaseFirestore
                                    .instance
                                    .collection('users')
                                    .doc(product!.userId)
                                    .get();

                                if (sellerDoc.exists) {
                                  final sellerData = sellerDoc.data();
                                  if (sellerData != null) {
                                    final seller = AppUser(
                                      uid: product!.userId,
                                      email: sellerData['email'] ?? '',
                                      userListings:
                                          sellerData['userListings'] ?? [],
                                      orderHistory:
                                          sellerData['orderHistory'] ?? [],
                                      displayName:
                                          sellerData['displayName'] ?? '',
                                    );

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProfilePage(appUser: seller),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Seller profile not found.")),
                                  );
                                }
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
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isLoadingProduct || product == null
          ? const SizedBox()
          : Container(
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
                  const Text(
                    'Quantity:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (quantity > 1) quantity--;
                            });
                          },
                          child: const Icon(Icons.remove, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              quantity++;
                            });
                          },
                          child: const Icon(Icons.add, size: 14),
                        ),
                      ],
                    ),
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
                              Text('${product!.productTitle} added to cart'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
