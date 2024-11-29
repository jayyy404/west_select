import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart/cart_model.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;
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
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(productTitle),
      ),
      body: Column(
        children: [
          Image.network(imageUrl),
          Text(productTitle),
          Text(description),
          Text('PHP $price'),
          Text('Seller: $sellerName'),
          ElevatedButton(
            onPressed: () {
              // Add the product to cart with sellerId and buyerId (if necessary)
              cart.addToCart(
                productId,  // The product ID
                productTitle,  // The product title
                price,  // The price of the product
                imageUrl,  // The image URL of the product
                userId,  // The seller ID
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$productTitle added to cart')),
              );
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}
