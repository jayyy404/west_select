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

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
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
              final sellerName = AppUser.fromFirestore(
                      snap.data!.data() as Map<String, dynamic>)
                  .displayName;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailPage(productId: listing.productId)),
                  );
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                              image: DecorationImage(
                                image: NetworkImage(listing.imageUrls.isNotEmpty
                                    ? listing.imageUrls[0]
                                    : 'https://via.placeholder.com/150'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(listing.postTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      fontFamily: 'Open Sans'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: .5),
                              Text('Seller: ${sellerName ?? 'Unknown'}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      height: 2,
                                      fontFamily: 'Open Sans',
                                      color: Colors.black54),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  'PHP ${NumberFormat('#,##0.00', 'en_US').format(listing.price)}',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      height: 2,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            });
      },
    );
  }
}
