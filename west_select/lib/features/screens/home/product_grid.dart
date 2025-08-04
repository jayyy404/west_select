import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:cc206_west_select/features/screens/listing/listing.dart';
import 'package:cc206_west_select/features/screens/productdetails/product.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.listings,
    required this.firestore,
  });

  final List<Listing> listings;
  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const Center(child: Text('No products found'));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    int crossAxisCount = 2;
    double aspectRatio = 0.8; // phone default (taller cards)

    if (screenWidth >= 900) {
      crossAxisCount = 4;
      aspectRatio = 0.85; // give tall enough cards on very wide screens
    } else if (screenWidth >= 600) {
      crossAxisCount = 3;
      aspectRatio = 0.8; // tablet / small‑desktop
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: listings.length,
      itemBuilder: (_, i) {
        final listing = listings[i];

        return FutureBuilder<DocumentSnapshot>(
          future: firestore.collection('users').doc(listing.postUserId).get(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sellerName =
                AppUser.fromFirestore(snap.data!.data() as Map<String, dynamic>)
                    .displayName;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailPage(productId: listing.productId),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          image: DecorationImage(
                            image: NetworkImage(
                              listing.imageUrls.isNotEmpty
                                  ? listing.imageUrls[0]
                                  : 'https://via.placeholder.com/150',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.postTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenHeight * 0.016,
                                    fontFamily: 'Open Sans',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: screenHeight * 0.002),
                                Text(
                                  'Seller: ${sellerName ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.012,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Open Sans',
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Text(
                                  'PHP ${NumberFormat('#,##0.00', 'en_US').format(listing.price)}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: screenHeight * 0.015,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
