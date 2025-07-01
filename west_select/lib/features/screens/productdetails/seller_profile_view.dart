import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SellerProfileView extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const SellerProfileView({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerProfileView> createState() => _SellerProfileViewState();
}

class _SellerProfileViewState extends State<SellerProfileView> {
  Map<String, dynamic>? sellerData;
  List<QueryDocumentSnapshot> sellerProducts = [];
  bool isLoadingProfile = true;
  bool isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
    _fetchSellerProducts();
  }

  Future<void> _fetchSellerData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.sellerId)
          .get();

      if (doc.exists) {
        setState(() {
          sellerData = doc.data();
          isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingProfile = false);
    }
  }

  Future<void> _fetchSellerProducts() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('post')
          .where('post_users', isEqualTo: widget.sellerId)
          .orderBy('post_date', descending: true)
          .get();

      setState(() {
        sellerProducts = querySnapshot.docs;
        isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => isLoadingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sellerName,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Profile Picture
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: sellerData?['profilePictureUrl'] !=
                                      null &&
                                  sellerData!['profilePictureUrl']
                                      .toString()
                                      .isNotEmpty
                              ? NetworkImage(sellerData!['profilePictureUrl'])
                              : null,
                          backgroundColor: Colors.grey.shade300,
                          child: (sellerData?['profilePictureUrl'] == null ||
                                  sellerData!['profilePictureUrl']
                                      .toString()
                                      .isEmpty)
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Seller Name
                        Text(
                          sellerData?['displayName'] ?? widget.sellerName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Email
                        if (sellerData?['email'] != null)
                          Text(
                            sellerData!['email'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 8),

                        // Year/Course if available
                        if (sellerData?['year'] != null)
                          Text(
                            '${sellerData!['year']} Year Student',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),

                        // Description
                        if (sellerData?['description'] != null &&
                            sellerData!['description']
                                .toString()
                                .trim()
                                .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'About',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sellerData!['description'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Products Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Products',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${sellerProducts.length}',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Products Grid
                        isLoadingProducts
                            ? const Center(child: CircularProgressIndicator())
                            : sellerProducts.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Text(
                                        'No products posted yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.8,
                                    ),
                                    itemCount: sellerProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = sellerProducts[index];
                                      final data = product.data()
                                          as Map<String, dynamic>;

                                      return _buildProductCard(
                                          product.id, data);
                                    },
                                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProductCard(String productId, Map<String, dynamic> data) {
    final imageUrls = List<String>.from(data['image_urls'] ?? []);
    final title = data['post_title'] ?? 'No Title';
    final price = (data['price'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Go back to previous page
        // Navigate to product detail
        Navigator.pushNamed(context, '/product-detail', arguments: productId);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey.shade100,
                ),
                child: imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported,
                                size: 40);
                          },
                        ),
                      )
                    : const Icon(Icons.image_not_supported, size: 40),
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'PHP ${NumberFormat('#,##0', 'en_US').format(price)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
