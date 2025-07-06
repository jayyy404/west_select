import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cc206_west_select/features/screens/home/product_grid.dart';
import 'package:cc206_west_select/features/screens/home/categories_section.dart';
import 'package:cc206_west_select/features/screens/home/header.dart';

import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:cc206_west_select/services/notification_service.dart';
import 'package:cc206_west_select/features/screens/listing/listing.dart';
import 'package:cc206_west_select/features/screens/cart/shopping_cart.dart';
import 'package:cc206_west_select/features/screens/notifications/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _search = TextEditingController();
  final NotificationService _notificationService = NotificationService();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _searchResults = [];

  bool _isSearching = false;
  bool _hasSearchQuery = false;

  String? _selectedCategory;
  bool _isCategoryFiltering = false;

  String _userName = 'User';

  static const List<String> _categories = [
    'Merch',
    'Food',
    'Clothing',
    'Footwear',
    'Gadgets',
    'School Supplies'
  ];

  static const Map<String, String> _catImages = {
    'Merch': 'assets/categories/merch.png',
    'Food': 'assets/categories/food.png',
    'Clothing': 'assets/categories/clothes.png',
    'Footwear': 'assets/categories/footwear.png',
    'Gadgets': 'assets/categories/gadgets.png',
    'School Supplies': 'assets/categories/school_supplies.png',
  };

  // Method to clear all filters - can be called from outside
  void clearAllFilters() {
    _clearAllFilters();
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      if (_search.text.isEmpty) {
        // Only reset search when search field is empty, don't touch category filtering
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _hasSearchQuery = false;
        });
      }
    });
    _fetchUserName();
    _createSampleNotifications();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _resetSearch() {
    debugPrint('Resetting search');
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _hasSearchQuery = false;
      // Don't reset category filtering here - keep it separate
    });
    debugPrint('Search reset complete');
  }

  void _clearSearch() {
    debugPrint('Clearing search');
    _search.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _hasSearchQuery = false;
      // Keep category filtering intact
    });
    debugPrint('Search cleared');
  }

  void _selectCategory(String category) {
    debugPrint('Selecting category: $category');
    setState(() {
      _selectedCategory = category;
      _isCategoryFiltering = true;
      _hasSearchQuery = false;
      _searchResults = [];
      _isSearching = false;
    });
    _search.clear();
    debugPrint(
        'Category filter set to: $_selectedCategory, isCategoryFiltering: $_isCategoryFiltering');
  }

  void _clearCategoryFilter() {
    debugPrint('Clearing category filter');
    setState(() {
      _isCategoryFiltering = false;
      _selectedCategory = null;
    });
    debugPrint('Category filter cleared');
  }

  void _clearAllFilters() {
    debugPrint('Clearing all filters');
    _search.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _hasSearchQuery = false;
      _selectedCategory = null;
      _isCategoryFiltering = false;
    });
    debugPrint('All filters cleared');
  }

  Future<void> _performSearch() async {
    final query = _search.text.trim();
    if (query.isEmpty) return _resetSearch();

    setState(() {
      _isSearching = true;
      _hasSearchQuery = true;
    });

    try {
      final lower = query.toLowerCase();
      final rawDocs = await _firestore
          .collection('post')
          .orderBy('createdAt', descending: true)
          .get();

      final matches = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final post in rawDocs.docs) {
        final data = post.data();
        final title = (data['post_title'] ?? '').toString().toLowerCase();
        final sellerId = data['post_user_id'];

        var ok = title.contains(lower);
        if (!ok && sellerId != null) {
          final user = await _firestore.collection('users').doc(sellerId).get();
          final sellerName =
              AppUser.fromFirestore(user.data() as Map<String, dynamic>)
                  .displayName
                  ?.toLowerCase();
          ok = sellerName?.contains(lower) ?? false;
        }
        if (ok) matches.add(post);
      }

      setState(() {
        _searchResults = matches;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await _firestore.collection('users').doc(user.uid).get();
    if (!snap.exists) return;
    final appUser = AppUser.fromFirestore(snap.data()!);
    setState(() => _userName = appUser.displayName ?? 'User');
  }

  Future<void> _createSampleNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final exists = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (exists.docs.isNotEmpty) return;

    await _notificationService.createNotification(
      userId: user.uid,
      title: 'Welcome to West Select!',
      body: 'Start exploring products and connect with sellers in your area.',
      type: 'general',
    );
    await _notificationService.createNotification(
      userId: user.uid,
      title: 'New Product Available',
      body: 'Check out the latest gadgets added to the marketplace!',
      type: 'general',
    );
  }

  Widget _buildSearchResults() {
    final listings = _searchResults
        .where((doc) {
          final d = doc.data();
          final s = d['status'] ?? 'listed';
          final stk = d['stock'] ?? 0;
          return stk > 0 && s != 'soldout' && s != 'delisted';
        })
        .map((doc) => Listing.fromFirestore(doc.data()))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Search Results',
                  style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF201D1B))),
              const Spacer(),
              TextButton(onPressed: _clearSearch, child: const Text('Clear')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
              child: ProductGrid(listings: listings, firestore: _firestore))
        ],
      ),
    );
  }

  Widget _buildCategoryResults() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Icon(Icons.filter_list,
                        color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory == 'School Supplies'
                          ? 'Showing: $_selectedCategory'
                          : 'Showing: $_selectedCategory Products',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _clearCategoryFilter,
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('post')
                      .where('category', isEqualTo: _selectedCategory)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      debugPrint(
                          'Error fetching category products: ${snap.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error loading products: ${snap.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _clearCategoryFilter,
                              child: const Text('Go Back'),
                            ),
                          ],
                        ),
                      );
                    }

                    final allDocs = snap.data!.docs;
                    debugPrint(
                        'Found ${allDocs.length} documents for category: $_selectedCategory');

                    final listings = allDocs
                        .where((d) {
                          final m = d.data() as Map<String, dynamic>;
                          final st = m['status'] ?? 'listed';
                          final stock = m['stock'] ?? 0;
                          final category = m['category'] ?? '';

                          debugPrint(
                              'Document: ${d.id}, category: $category, status: $st, stock: $stock');

                          return stock > 0 &&
                              st != 'soldout' &&
                              st != 'delisted';
                        })
                        .map((d) => Listing.fromFirestore(
                            d.data() as Map<String, dynamic>))
                        .toList();

                    // Sort by createdAt manually after fetching
                    listings.sort((a, b) {
                      // Find the corresponding documents
                      QueryDocumentSnapshot? aDoc;
                      QueryDocumentSnapshot? bDoc;

                      try {
                        aDoc = allDocs.firstWhere(
                          (doc) => doc.id == a.productId,
                          orElse: () => throw StateError('Not found'),
                        );
                      } catch (e) {
                        debugPrint(
                            'Could not find document for productId: ${a.productId}');
                        aDoc = null;
                      }

                      try {
                        bDoc = allDocs.firstWhere(
                          (doc) => doc.id == b.productId,
                          orElse: () => throw StateError('Not found'),
                        );
                      } catch (e) {
                        debugPrint(
                            'Could not find document for productId: ${b.productId}');
                        bDoc = null;
                      }

                      if (aDoc == null || bDoc == null) return 0;

                      final aData = aDoc.data() as Map<String, dynamic>?;
                      final bData = bDoc.data() as Map<String, dynamic>?;
                      final aTime = aData?['createdAt'] as Timestamp?;
                      final bTime = bData?['createdAt'] as Timestamp?;

                      if (aTime == null || bTime == null) return 0;
                      return bTime.compareTo(aTime);
                    });

                    debugPrint('Filtered to ${listings.length} listings');

                    if (listings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'There are no available products in the $_selectedCategory category.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _clearCategoryFilter,
                              child: const Text('Browse All Products'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ProductGrid(
                        listings: listings, firestore: _firestore);
                  }),
            )
          ],
        ),
      );

  Widget _buildMainContent() => Column(
        children: [
          CategoriesSection(
            categories: _categories,
            categoryImages: _catImages,
            selected: _selectedCategory,
            onSelect: _selectCategory,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  const Text("This Week's Listing",
                      style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF201D1B))),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('post')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final listings = snap.data!.docs
                              .where((d) {
                                final m = d.data() as Map<String, dynamic>;
                                final st = m['status'] ?? 'listed';
                                return (m['stock'] ?? 0) > 0 &&
                                    st != 'soldout' &&
                                    st != 'delisted';
                              })
                              .map((d) => Listing.fromFirestore(
                                  d.data() as Map<String, dynamic>))
                              .toList();
                          return ProductGrid(
                              listings: listings, firestore: _firestore);
                        }),
                  )
                ],
              ),
            ),
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          HomeHeader(
            userName: _userName,
            notificationService: _notificationService,
            onBellTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsPage())),
            onCartTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ShoppingCartPage())),
            searchController: _search,
            onSearchClear: _clearSearch,
            onSearchSubmit: _performSearch,
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _hasSearchQuery
                    ? _buildSearchResults()
                    : _isCategoryFiltering
                        ? (() {
                            debugPrint(
                                'Building category results for: $_selectedCategory');
                            return _buildCategoryResults();
                          }())
                        : _buildMainContent(),
          )
        ],
      ),
    );
  }
}
