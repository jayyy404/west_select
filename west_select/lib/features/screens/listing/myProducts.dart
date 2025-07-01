import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MyProductsList extends StatelessWidget {
  const MyProductsList({super.key});

  Future<void> _deleteListing(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance.collection('post').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted successfully')),
      );
    } catch (e) {
      if (kDebugMode) print('Delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete listing')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Future.delayed(const Duration(milliseconds: 500)),
      builder: (context, delaySnapshot) {
        if (delaySnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('post')
              .where('post_users',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final listings = snapshot.data!.docs;
            if (listings.isEmpty) {
              return const Center(child: Text("You have no products listed."));
            }

            return ListView.builder(
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                final data = listing.data()! as Map<String, dynamic>;

                String image = '';
                if (data['image_urls'] != null &&
                    (data['image_urls'] as List).isNotEmpty) {
                  image = data['image_urls'].first;
                } else if (data['image_url'] != null) {
                  image = data['image_url'];
                }

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(data['post_title'] ?? ''),
                    subtitle: Text("PHP ${data['price'] ?? ''}"),
                    leading: image.isNotEmpty
                        ? Image.network(image,
                            width: 50, height: 50, fit: BoxFit.cover)
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteListing(context, listing.id),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
