import 'package:cc206_west_select/features/screens/productdetails/product.dart';
import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:cc206_west_select/features/screens/notifications/notifications_page.dart';
import 'package:cc206_west_select/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cc206_west_select/features/screens/cart/shopping_cart.dart';
import 'package:cc206_west_select/features/screens/listing/listing.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearchQuery = false;
  String? _selectedCategory;
  bool _isCategoryFiltering = false;
  String _userName = 'User';

  // Define categories
  final List<String> categories = [
    'Merch',
    'Food',
    'Clothing',
    'Footwear',
    'Gadgets',
    'School Supplies',
  ];
  final Map<String, String> categoryImages = {
    'Merch': 'assets/categories/merch.png',
    'Food': 'assets/categories/food.png',
    'Clothing': 'assets/categories/clothes.png',
    'Footwear': 'assets/categories/footwear.png',
    'Gadgets': 'assets/categories/gadgets.png',
    'School Supplies': 'assets/categories/school_supplies.png',
  };
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        _resetSearch();
      }
    });
    _fetchUserName(); // Fetch user name on init
    _createSampleNotifications(); // Add some sample notifications for testing
  }

  // Create sample notifications for testing (only do this once)
  Future<void> _createSampleNotifications() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if sample notifications already exist
    final existingNotifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    // Only create sample notifications if none exist
    if (existingNotifications.docs.isEmpty) {
      await _notificationService.createNotification(
        userId: currentUser.uid,
        title: 'Welcome to West Select!',
        body: 'Start exploring products and connect with sellers in your area.',
        type: 'general',
      );

      await _notificationService.createNotification(
        userId: currentUser.uid,
        title: 'New Product Available',
        body: 'Check out the latest gadgets added to the marketplace!',
        type: 'general',
      );
    }
  }

  // Fetch current user's name
  Future<void> _fetchUserName() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final appUser = AppUser.fromFirestore(userData);
          setState(() {
            _userName = appUser.displayName ?? 'User';
          });
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
      // Keep default name if error occurs
    }
  }

  void _resetSearch() {
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _hasSearchQuery = false;
      _selectedCategory = null;
      _isCategoryFiltering = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _resetSearch();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _isCategoryFiltering = true;
      _hasSearchQuery = false;
      _searchResults = [];
    });
    _searchController.clear();
  }

  void _clearCategoryFilter() {
    setState(() {
      _selectedCategory = null;
      _isCategoryFiltering = false;
    });
  }

  Future<void> _performSearch() async {
    final searchText = _searchController.text.trim();
    if (searchText.isEmpty) {
      _resetSearch();
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearchQuery = true;
    });

    try {
      final searchKey = searchText.toLowerCase();

      // query all posts
      final allPosts = await _firestore
          .collection('post')
          .orderBy('createdAt', descending: true)
          .get();
      List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredResults = [];

      for (var postDoc in allPosts.docs) {
        final postData = postDoc.data();
        final postTitle =
            postData['post_title']?.toString().toLowerCase() ?? '';
        final userId = postData['post_user_id'];

        bool matchesTitle = postTitle.contains(searchKey);
        bool matchesSeller = false;

        // Check seller name
        if (userId != null && !matchesTitle) {
          try {
            final userDoc =
                await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final sellerName =
                  AppUser.fromFirestore(userData).displayName?.toLowerCase() ??
                      '';
              matchesSeller = sellerName.contains(searchKey);
            }
          } catch (e) {
            print("Error fetching user data: $e");
          }
        }

        if (matchesTitle || matchesSeller) {
          filteredResults.add(postDoc);
        }
      }

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      print("Search error: $e");
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Build category chips
  Widget _buildCategories() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Explore all categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF201D1B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final name = categories[index];
                final imgPath =
                    categoryImages[name] ?? 'assets/icons/placeholder.png';
                final isSelected = _selectedCategory == name;

                return SizedBox(
                  width: 76,
                  child: GestureDetector(
                    onTap: () => _selectCategory(name),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.blue.shade100
                                : const Color(0xFFE0E0E0),
                            border: isSelected
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              imgPath,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.blue
                                : const Color(0xFF201D1B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Listing> listings) {
    if (listings.isEmpty) {
      return const Center(child: Text("No products found"));
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
      itemBuilder: (context, index) {
        final listing = listings[index];
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(listing.postUserId).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (userSnapshot.hasError) {
              return const Center(child: Text("Error fetching seller info"));
            } else if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Center(child: Text("Seller info not available"));
            } else {
              final sellerName = AppUser.fromFirestore(
                      userSnapshot.data!.data() as Map<String, dynamic>)
                  .displayName;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(
                        productId: listing.productId,
                      ),
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
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
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
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                listing.postTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  fontFamily: 'Open Sans',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 0.5),
                              Text(
                                'Seller: ${sellerName ?? 'Unknown Seller'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  height: 2,
                                  fontFamily: 'Open Sans',
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  'PHP ${NumberFormat('#,##0.00', 'en_US').format(listing.price)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    height: 2,
                                    fontWeight: FontWeight.bold,
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
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Search Results',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF201D1B),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearSearch,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildProductGrid(
              _searchResults
                  .map((doc) => Listing.fromFirestore(doc.data()))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$_selectedCategory Products',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF201D1B),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearCategoryFilter,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('post')
                  .where('category', isEqualTo: _selectedCategory)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text("Error fetching products"));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedCategory products found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final listings = snapshot.data!.docs
                      .map((doc) => Listing.fromFirestore(
                          doc.data() as Map<String, dynamic>))
                      .toList();
                  return _buildProductGrid(listings);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildCategories(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                const Text(
                  "This Week's Listing",
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF201D1B),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('post')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(
                            child: Text("Error fetching listings"));
                      } else if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("No listings available"));
                      } else {
                        final listings = snapshot.data!.docs
                            .map((doc) => Listing.fromFirestore(
                                doc.data() as Map<String, dynamic>))
                            .toList();
                        return _buildProductGrid(listings);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A90E2),
                  Color(0xFF357ABD),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hello, $_userName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            // Notification bell with unread count
                            StreamBuilder<int>(
                              stream: _notificationService.getUnreadCount(
                                  FirebaseAuth.instance.currentUser?.uid ?? ''),
                              builder: (context, snapshot) {
                                final unreadCount = snapshot.data ?? 0;
                                return Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.notifications,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const NotificationsPage(),
                                          ),
                                        );
                                      },
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          constraints: const BoxConstraints(
                                              minWidth: 16),
                                          height: 16,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              unreadCount > 99
                                                  ? '99+'
                                                  : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ShoppingCartPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          if (value.isEmpty) _resetSearch();
                        },
                        onSubmitted: (_) => _performSearch(),
                        decoration: InputDecoration(
                          hintText: 'What are you looking for?',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Content Section
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _hasSearchQuery
                    ? _buildSearchResults()
                    : _isCategoryFiltering
                        ? _buildCategoryResults()
                        : _buildMainContent(),
          ),
        ],
      ),
    );
  }
}
