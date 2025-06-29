import 'package:cc206_west_select/features/screens/productdetails/product.dart';
import 'package:cc206_west_select/firebase/app_user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cc206_west_select/features/screens/cart/shopping_cart.dart';
import 'package:cc206_west_select/features/screens/listing/listing.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearchQuery = false;

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
  }

  void _resetSearch() {
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _hasSearchQuery = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _resetSearch();
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
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final name = categories[index];
          final imgPath =
              categoryImages[name] ?? 'assets/icons/placeholder.png';

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                // circular image
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE0E0E0),
                  child: ClipOval(
                    child: Image.asset(
                      imgPath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // category label
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF201D1B),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Listing> listings) {
    if (listings.isEmpty) {
      return const Center(child: Text("No products found"));
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.postTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: 'Open Sans',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Seller: ${sellerName ?? 'Unknown Seller'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Open Sans',
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PHP ${NumberFormat('#,##0.00', 'en_US').format(listing.price)}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF201D1B)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                if (value.isEmpty) _resetSearch();
                              },
                              onSubmitted: (_) => _performSearch(),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search an item...',
                                hintStyle: const TextStyle(
                                  fontFamily: "Open Sans",
                                  fontSize: 13,
                                  height: 2.2,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF201D1B),
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: _clearSearch,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search,
                                color: Color(0xFF201D1B)),
                            onPressed: _performSearch,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.notifications,
                        color: Color(0xFF201D1B)),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart,
                        color: Color(0xFF201D1B)),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _hasSearchQuery
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Search Results',
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF201D1B),
                          height: 1.2,
                        ),
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
                )
              : Column(
                  children: [
                    _buildCategories(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              "This Week's Listing",
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF201D1B),
                                height: 1.2,
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
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
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
                ),
    );
  }
}
