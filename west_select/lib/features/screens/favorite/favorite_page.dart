import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'favorite_model.dart';

class FavoritePage extends StatelessWidget {


  const FavoritePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favoriteModel = Provider.of<FavoriteModel>(context, listen: false);
    final String? currUser = FirebaseAuth.instance.currentUser?.uid;
    return FutureBuilder(
      future: favoriteModel.fetchFavorites(currUser!), // <- correct user
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Wishlist")),
          body: Consumer<FavoriteModel>(
            builder: (context, model, _) {
              final items = model.favoriteItems;

              if (items.isEmpty) {
                return const Center(child: Text("No favorites yet!"));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final product = items[index];
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          product["imageUrl"]!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product["title"] ?? "",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.red),
                                    onPressed: () {
                                      model.removeFavorite(currUser, product);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${product["title"]} removed')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                product["price"] ?? "",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      product["seller"] ?? "",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

