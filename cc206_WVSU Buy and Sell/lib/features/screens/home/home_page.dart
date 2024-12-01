import 'package:cc206_west_select/features/screens/productdetails/product.dart';
import 'package:cc206_west_select/firebase/search_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cc206_west_select/features/screens/cart/shopping_cart.dart';
import 'package:cc206_west_select/features/screens/listing.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService(FirebaseFirestore.instance);
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _searchResults = [];
  bool _isSearching = false;

  void _performSearch() async {
    final searchText = _searchController.text.trim();
    if (searchText.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _searchService.searchProducts(searchText);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
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
        preferredSize: const Size.fromHeight(125),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
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
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search an item...',
                                hintStyle: TextStyle(
                                  fontFamily: "Open Sans",
                                  fontSize: 13,
                                  height: 2.2,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF201D1B),
                                ),
                              ),
                              onSubmitted: (_) => _performSearch(),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('post').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error fetching listings"));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No listings available"));
          } else {
            final listings = snapshot.data!.docs.map((doc) {
              return Listing.fromFirestore(doc.data() as Map<String, dynamic>);
            }).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "This Week's Listing",
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF201D1B),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to ProductDetailPage and pass productId
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(
                                  productId: listing.productId,  // Pass productId
                                  imageUrl: listing.imageUrl,
                                  productTitle: listing.postTitle,
                                  description: listing.postDescription,
                                  price: listing.price,
                                  sellerName: listing.sellerName, // Will be updated later
                                  userId: listing.postUserId,
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
                                          listing.imageUrl.isNotEmpty
                                              ? listing.imageUrl
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                      Text(listing.sellerName),
                                      const SizedBox(height: 4),
                                      Text(
                                        'PHP ${listing.price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: Colors.green),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
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
        },
      ),
    );
  }
}
