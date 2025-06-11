import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart/cart_model.dart';
import '../favorite/favorite_model.dart';
import 'package:intl/intl.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId; // This is the post_id passed here
  final String imageUrl;
  final String productTitle;
  final String description;
  final double price;
  final String sellerName;
  final String userId; // Seller ID passed here

  const ProductDetailPage({
    Key? key,
    required this.productId,
    required this.imageUrl,
    required this.productTitle,
    required this.description,
    required this.price,
    required this.sellerName,
    required this.userId, // Seller ID passed here
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? currentUser = FirebaseAuth.instance.currentUser?.uid;
  int quantity = 1;
  bool isFavorite = false; // To track if the product is favorited

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context, listen: false);
    final favoriteModel = Provider.of<FavoriteModel>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar for the full-screen image with overlay buttons
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Full-screen image
                  Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                        ],
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
              // Favorite Icon Button
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  final product = {
                    "id": widget.productId,
                    "title": widget.productTitle,
                    "imageUrl": widget.imageUrl,
                    "price": widget.price.toString(),
                    "seller": widget.sellerName,
                  };
                  if (isFavorite) {
                    favoriteModel.removeFavorite(currentUser!, product);
                  } else {
                    favoriteModel.addFavorite(currentUser!, product);
                  }

                  setState(() {
                    isFavorite = !isFavorite;
                  });
                },
              ),
            ],
          ),

          // Product details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product title
                      Expanded(
                        child: Text(
                          widget.productTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Product price
                      Text(
                        'PHP ${NumberFormat('#,##0.00', 'en_US').format(widget.price)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Seller's Details
                  const Text(
                    'Seller’s Details',
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
                        child: const Icon(
                          Icons.person,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sellerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom nav bar
      bottomNavigationBar: Container(
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
            // Quantity Selector
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // - Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (quantity > 1) quantity--;
                      });
                    },
                    child: Container(
                      height: 20,
                      width: 20,
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
                    quantity.toString(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  // + Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        quantity++;
                      });
                    },
                    child: Container(
                      height: 20,
                      width: 20,
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
            const Spacer(),
            // Add to Cart Button
            ElevatedButton(
              onPressed: () {
                cart.addToCart(
                  widget.productId, // This is the post_id (productId)
                  widget.productTitle, // The product title
                  widget.price, // The price of the product
                  widget.imageUrl, // The image URL of the product
                  widget.userId, // The seller ID
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${widget.productTitle} added to cart')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
