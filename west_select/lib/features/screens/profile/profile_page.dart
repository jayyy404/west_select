import 'package:cc206_west_select/features/landingpage/log_in.dart';
import 'package:cc206_west_select/features/screens/profile/profile_widgets/header.dart';
import 'package:cc206_west_select/features/screens/profile/profile_widgets/settings_sheet.dart';
import 'package:cc206_west_select/features/screens/profile/profile_widgets/shopping_sections.dart';
import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:cc206_west_select/firebase/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cc206_west_select/features/auth_gate.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.appUser, this.readonly});

  final AppUser appUser;
  final bool? readonly;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late bool isReadOnly;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  @override
  void initState() {
    super.initState();
    final me = FirebaseAuth.instance.currentUser?.uid;
    isReadOnly = widget.readonly ?? (me == null || me != widget.appUser.uid);
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.appUser.uid)
        .snapshots();
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LogInPage()),
        (route) => false,
      );
    }
  }

  void _confirmAndDeleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to permanently delete your account?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await _deleteUser(); // your existing logic
      } catch (e) {
        Navigator.of(context).pop(); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete account: $e")),
        );
      }
    }
  }

  Future<void> _deleteUser() async {
    await AuthService().deleteUser();
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  Future<int> _getPendingOrdersCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: widget.appUser.uid)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getReviewsCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('reviews')
          .where('userId', isEqualTo: widget.appUser.uid)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  void _editProfile(AppUser a) async {
    final TextEditingController nameController =
        TextEditingController(text: a.displayName ?? '');
    final TextEditingController descController =
        TextEditingController(text: a.description ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(16),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Write something about yourself...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final newDesc = descController.text.trim();

                if (newName.isEmpty || newDesc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Name and description cannot be empty')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(a.uid)
                      .update({
                    'displayName': newName,
                    'description': newDesc,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile updated successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating profile: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _writeReviewImpl(String productId, String sellerId,
      String productTitle, double productPrice, String productImage) async {
    final TextEditingController reviewController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    // Check if user has already reviewed this product
    final existingReview = await FirebaseFirestore.instance
        .collection('post')
        .doc(productId)
        .collection('reviews')
        .doc(user.uid)
        .get();

    if (existingReview.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reviewed this product')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product: $productTitle',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Share your experience with this product...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reviewController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write a review')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('post')
                      .doc(productId)
                      .collection('reviews')
                      .doc(user.uid)
                      .set({
                    'userId': user.uid,
                    'userName': user.displayName ?? 'Anonymous',
                    'comment': reviewController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Review submitted successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error submitting review: $e')),
                  );
                }
              },
              child: const Text('Submit Review'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToCartImpl(String productId, String sellerId,
      String productTitle, double productPrice, String productImage) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if product is still available
      final productDoc = await FirebaseFirestore.instance
          .collection('post')
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product no longer available')),
        );
        return;
      }

      final productData = productDoc.data() as Map<String, dynamic>;
      final stock = productData['stock'] ?? 0;
      final status = productData['status'] ?? 'listed';

      if (stock <= 0 || status == 'soldout' || status == 'delisted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product is out of stock')),
        );
        return;
      }

      // Add to cart
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(productId)
          .set({
        'productId': productId,
        'title': productTitle,
        'price': productPrice,
        'sellerId': sellerId,
        'imageUrl': productImage,
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    }
  }

  String _getImageUrl(dynamic imageUrl) {
    if (imageUrl == null) return '';

    if (imageUrl is String) {
      return imageUrl;
    } else if (imageUrl is List && imageUrl.isNotEmpty) {
      return imageUrl.first.toString();
    }

    return '';
  }

  void _writeReview(Map<String, dynamic> product) {
    _writeReviewImpl(
      product['productId'] ?? '',
      product['sellerId'] ?? '',
      product['title'] ?? '',
      (product['price'] ?? 0.0).toDouble(),
      _getImageUrl(product['imageUrl']),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    _addToCartImpl(
      product['productId'] ?? '',
      product['sellerId'] ?? '',
      product['title'] ?? '',
      (product['price'] ?? 0.0).toDouble(),
      _getImageUrl(product['imageUrl']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = snap.data!;
        if (!doc.exists || doc.data() == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LogInPage()),
              (route) => false,
            );
          });
          return const SizedBox(); // Prevent build error while navigating
        }
        final user = AppUser.fromFirestore(doc.data()!);
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            actions: isReadOnly
                ? null
                : [
                    IconButton(
                      icon:
                          const Icon(Icons.settings, color: Color(0xFF1976D2)),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => SettingsSheet(
                          appUser: user,
                          onEditProfile: () => _editProfile(user),
                          onDeleteAccount: () => _confirmAndDeleteUser(),
                          onLogout: _signOut,
                        ),
                      ),
                    )
                  ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeader(appUser: user, isReadOnly: isReadOnly),
                const SizedBox(height: 20),
                if (!isReadOnly)
                  FutureBuilder<List<int>>(
                    future: Future.wait([
                      _getPendingOrdersCount(),
                      _getReviewsCount(),
                    ]),
                    builder: (context, snapshot) {
                      final pendingCount = snapshot.data?[0] ?? 0;
                      final reviewsCount = snapshot.data?[1] ?? 0;

                      return ShoppingSections(
                        userId: user.uid,
                        pendingCount: pendingCount,
                        reviewsCount: reviewsCount,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
