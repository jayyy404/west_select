import 'package:cc206_west_select/features/screens/cart/cart_model.dart';
import 'package:cc206_west_select/features/screens/favorite/favorite_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailPage extends StatefulWidget {
  final String imageUrl;
  final String productTitle;
  final String description;
  final double price;
  final String sellerName;
  final String userId;
  final String sellerProfileUrl;

  const ProductDetailPage({
    Key? key,
    required this.imageUrl,
    required this.productTitle,
    required this.description,
    required this.price,
    required this.sellerName,
    required this.userId,
    this.sellerProfileUrl = '',
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context, listen: false);
    final favoriteModel = Provider.of<FavoriteModel>(context, listen: false);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar for the full-screen image with overlay buttons
          SliverAppBar(
            expandedHeight: 350,  
            pinned: true, // Keeps the app bar visible as you scroll
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
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  final product = {
                    "title": widget.productTitle,
                    "price": widget.price.toStringAsFixed(2),
                    "imageUrl": widget.imageUrl,
                    "seller": widget.sellerName,
                  };

                  final isFavorite = favoriteModel.favoriteItems
                      .any((item) => item["title"] == widget.productTitle);

                  if (isFavorite) {
                    favoriteModel.removeFavorite(widget.userId, product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${widget.productTitle} removed from favorites.'),
                      ),
                    );
                  } else {
                    favoriteModel.addFavorite(widget.userId, product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${widget.productTitle} added to favorites.'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),

          //  product details
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
                          overflow: TextOverflow.ellipsis, // ellipsis if too long
                        ),
                      ),
                      // Product price
                      Text(
                        'PHP ${widget.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
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
                        backgroundImage: widget.sellerProfileUrl.isNotEmpty
                            ? CachedNetworkImageProvider(
                                widget.sellerProfileUrl)
                            : null,
                        child: widget.sellerProfileUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 24, color: Colors.white)
                            : null,
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
                          const Text(
                            '3rd Year CS Student',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
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
            const Spacer(),
            // Add to Cart Button
            ElevatedButton(
              onPressed: () {
                cart.addItem(
                  CartItem(
                    imageUrl: widget.imageUrl,
                    title: widget.productTitle,
                    subtitle: widget.sellerName,
                    price: widget.price,
                    quantity: quantity,
                  ),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added $quantity of ${widget.productTitle} to cart.',
                    ),
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
