import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../productdetails/product.dart';
import 'favorite_model.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteModel = Provider.of<FavoriteModel>(context, listen: false);
    final String? currUser = FirebaseAuth.instance.currentUser?.uid;

    if (currUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view favorites.")),
      );
    }

    return FutureBuilder(
      future: favoriteModel.fetchFavorites(currUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          appBar: AppBar(title: const Text("Wishlist")),
          body: Consumer<FavoriteModel>(
            builder: (context, model, _) {
              final items = model.favoriteItems;

              if (items.isEmpty) {
                return const Center(child: Text("No favorites yet!"));
              }

              return GridView.builder(
                padding: EdgeInsets.all(screenWidth * 0.03),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75, // Adjusted for better proportions
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final product = items[index];
                  final imageUrls = product["imageUrls"]?.split(",") ?? [];
                  return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                                productId: product["id"] ?? ""),
                          ),
                        );
                      },
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image section with flexible height
                            Expanded(
                              flex: 3,
                              child: Container(
                                width: double.infinity,
                                child: imageUrls.isNotEmpty
                                    ? Image.network(
                                        imageUrls[0],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 40),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Icon(Icons.image_not_supported,
                                            size: 40),
                                      ),
                              ),
                            ),
                            // Content section with flexible height
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product["title"] ?? "",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: screenHeight * 0.02,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 40,
                                          height: 20,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.favorite,
                                                color: Colors.red, size: 20),
                                            onPressed: () {
                                              model.removeFavorite(
                                                  currUser, product);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        '${product["title"]} removed')),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "PHP ${product["price"] ?? ""}",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 1),
                                    Flexible(
                                      child: Text(
                                        product["seller"] ?? "",
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ));
                },
              );
            },
          ),
        );
      },
    );
  }
}
