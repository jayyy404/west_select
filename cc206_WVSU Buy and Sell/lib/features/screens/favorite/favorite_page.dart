import 'package:flutter/material.dart';
import 'package:cc206_west_select/features/screens/listing.dart';

class FavoritePage extends StatelessWidget {
  FavoritePage({super.key});

  // Mock data for favorite items
  final List<Map<String, String>> favoriteItems = [
    {
      "title": "Onitsuka Tiger",
      "price": "PHP 1,990",
      "imageUrl": "https://via.placeholder.com/150",
      "seller": "Prince Alexander",
    },
    {
      "title": "Donut 20PCS",
      "price": "PHP 50",
      "imageUrl": "https://via.placeholder.com/150",
      "seller": "Prince Alexander",
    },
    {
      "title": "Adidas Ultraboost",
      "price": "PHP 6,000",
      "imageUrl": "https://via.placeholder.com/150",
      "seller": "Jane Smith",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // Background color
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120), // Fixed height for AppBar
        child: Container(
          width: double.infinity,
          height: 125, // AppBar height
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white, // AppBar background color
          ),
          child: SafeArea(
            child: Center(
              child: Text(
                "Wishlist",
                style: TextStyle(
                  color: const Color(0xFF201D1B), // Text color
                  fontFamily: "Raleway",
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.2, // Line height
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      body: favoriteItems.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: favoriteItems.length,
                itemBuilder: (context, index) {
                  final product = favoriteItems[index];
                },
              ),
            )
          : const Center(
              child: Text(
                "No favorites yet!",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ),
    );
  }
}
