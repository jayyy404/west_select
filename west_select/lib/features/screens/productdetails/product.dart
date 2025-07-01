import 'package:cc206_west_select/features/screens/cart/shopping_cart.dart';
import 'package:cc206_west_select/features/screens/message/message_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cc206_west_select/features/screens/cart/cart_model.dart';
import '../favorite/favorite_model.dart';
import 'product_review.dart';
import 'seller_profile_view.dart';

class Product {
  final List<String> imageUrls;
  final String productTitle;
  final String description;
  final double price;
  final String sellerName;
  final String userId;

  Product({
    required this.imageUrls,
    required this.productTitle,
    required this.description,
    required this.price,
    required this.sellerName,
    required this.userId,
  });

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      imageUrls: List<String>.from(data['image_urls'] ?? []),
      productTitle: data['post_title'] ?? '',
      description: data['post_description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      userId: data['post_users'] ?? '',
      sellerName: data['sellerName'] ?? '',
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? currentUser = FirebaseAuth.instance.currentUser?.uid;
  Product? product;
  int quantity = 1;
  int _currentImageIndex = 0;
  bool isFavorite = false;
  bool isLoadingProduct = true;
  bool isLoadingFavorite = true;
  bool _isSubmittingReview = false;

  final PageController _pageController = PageController();
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  Future<void> fetchProduct() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.productId)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      final postUserId = data?['post_users'];
      final sellerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postUserId)
          .get();

      String displayName = sellerDoc.data()?['displayName'] ?? 'Unknown';

      setState(() {
        product = Product.fromMap({
          ...?data,
          'sellerName': displayName,
          'userId': postUserId,
        });
        isLoadingProduct = false;
      });

      checkIfFavorite();
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> checkIfFavorite() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(currentUser)
          .get();

      final items = doc.data()?['items'] ?? [];
      isFavorite = items.any((item) => item['id'] == widget.productId);
      setState(() => isLoadingFavorite = false);
    } catch (e) {
      setState(() => isLoadingFavorite = false);
    }
  }

  void _navigateToMessagePage() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send messages')),
      );
      return;
    }

    if (product == null) return;

    if (currentUser == product!.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(
          receiverId: product!.userId,
          userName: product!.sellerName,
          productName: product!.productTitle,
          productPrice: product!.price,
          productImage: product!.imageUrls.first,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context, listen: false);
    final favoriteModel = Provider.of<FavoriteModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          isLoadingFavorite
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2.0))
              : IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.black,
                  ),
                  onPressed: () {
                    final map = {
                      'id': widget.productId,
                      'title': product!.productTitle,
                      'imageUrls': product!.imageUrls.join(','),
                      'price': product!.price.toString(),
                      'seller': product!.sellerName,
                    };

                    if (isFavorite) {
                      favoriteModel.removeFavorite(currentUser!, map);
                    } else {
                      favoriteModel.addFavorite(currentUser!, map);
                    }

                    setState(() => isFavorite = !isFavorite);
                  },
                ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShoppingCartPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoadingProduct || product == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image carousel
                  Container(
                    height: 300,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: product!.imageUrls.length,
                          onPageChanged: (index) =>
                              setState(() => _currentImageIndex = index),
                          itemBuilder: (_, index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(product!.imageUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        if (product!.imageUrls.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                product!.imageUrls.length,
                                (index) => Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? Colors.blue
                                        : Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Product title and price
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product!.productTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PHP ${NumberFormat('#,##0', 'en_US').format(product!.price)}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Product Details Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Fetch and display product details
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('post')
                              .doc(widget.productId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            if (data == null) return const SizedBox.shrink();

                            return Column(
                              children: [
                                _buildDetailRow('Category', data['category']),
                                if (data['condition'] != null &&
                                    data['condition'].toString().isNotEmpty)
                                  _buildDetailRow(
                                      'Condition', data['condition']),
                                if (data['color'] != null &&
                                    data['color'].toString().isNotEmpty)
                                  _buildDetailRow('Color', data['color']),
                                if (data['size'] != null &&
                                    data['size'].toString().isNotEmpty)
                                  _buildDetailRow('Sizing', data['size']),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product!.description,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pickup Location
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('post')
                        .doc(widget.productId)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();

                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      final location = data?['location'];

                      if (location == null || location.toString().isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              location.toString(),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),

                  // Meet the Seller
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meet the Seller',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(product!.userId)
                                  .get(),
                              builder: (context, snapshot) {
                                String? profilePicUrl;
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final userData = snapshot.data!.data()
                                      as Map<String, dynamic>?;
                                  profilePicUrl =
                                      userData?['profilePictureUrl'];
                                }
                                return CircleAvatar(
                                  radius: 20,
                                  backgroundImage: profilePicUrl != null &&
                                          profilePicUrl.isNotEmpty
                                      ? NetworkImage(profilePicUrl)
                                      : null,
                                  backgroundColor: Colors.grey,
                                  child: (profilePicUrl == null ||
                                          profilePicUrl.isEmpty)
                                      ? const Icon(Icons.person,
                                          size: 20, color: Colors.white)
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SellerProfileView(
                                        sellerId: product!.userId,
                                        sellerName: product!.sellerName,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product!.sellerName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    // Add year or additional info if available
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(product!.userId)
                                          .get(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData ||
                                            !snapshot.data!.exists) {
                                          return const SizedBox.shrink();
                                        }

                                        final userData = snapshot.data!.data()
                                            as Map<String, dynamic>?;
                                        final year = userData?['year'];

                                        if (year == null)
                                          return const SizedBox.shrink();

                                        return Text(
                                          year.toString(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.message_outlined),
                              onPressed: _navigateToMessagePage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Reviews Section
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('post')
                        .doc(widget.productId)
                        .collection('reviews')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final reviewCount =
                          snapshot.hasData ? snapshot.data!.docs.length : 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reviews header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reviews ($reviewCount)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (reviewCount > 0)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(
                                              title: const Text('All Reviews'),
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              elevation: 1,
                                            ),
                                            body: ProductReviews(
                                                productId: widget.productId),
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('View All'),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Add Review Input (only for logged in users)
                          if (currentUser != null &&
                              currentUser != product!.userId)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildQuickReviewInput(),
                            ),

                          const SizedBox(height: 16),

                          // Reviews list or empty state
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No reviews yet. Be the first to review!',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            // Show only the most recent review as preview
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _buildReviewPreview(
                                    snapshot.data!.docs.first),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 50), // Space for bottom navigation
                ],
              ),
            ),
      bottomNavigationBar: product == null
          ? null
          : Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quantity row
                  Row(
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              iconSize: 15,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (quantity > 1) quantity--;
                                });
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                quantity.toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              iconSize: 15,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() => quantity++);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Add to Cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA42D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        elevation: 0,
                      ),
                      onPressed: () {
                        cart.addToCart(
                          widget.productId,
                          product!.productTitle,
                          product!.price,
                          [product!.imageUrls.first],
                          product!.userId,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('${product!.productTitle} added to cart'),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '(Subtotal: PHP ${NumberFormat("#,##0").format(product!.price * quantity)})',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
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

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPreview(DocumentSnapshot reviewDoc) {
    final data = reviewDoc.data() as Map<String, dynamic>?;
    if (data == null) return const SizedBox.shrink();

    final userName = data['userName'] ?? 'Anonymous';
    final comment = data['comment'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (timestamp != null)
                    Text(
                      DateFormat('MMM dd, yyyy').format(
                        timestamp.toDate().toLocal(),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          comment,
          style: const TextStyle(fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQuickReviewInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a Review',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience with this product...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _reviewController.clear();
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmittingReview ? null : _submitQuickReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmittingReview
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Post Review'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuickReview() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit a review')),
      );
      return;
    }

    final comment = _reviewController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a review')),
      );
      return;
    }

    setState(() => _isSubmittingReview = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final reviewData = {
        'userId': currentUser!,
        'userName': user?.displayName ?? 'Anonymous',
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.productId)
          .collection('reviews')
          .doc(currentUser!)
          .set(reviewData);

      _reviewController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post review: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmittingReview = false);
    }
  }
}
