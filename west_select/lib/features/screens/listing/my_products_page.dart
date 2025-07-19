import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cc206_west_select/features/screens/listing/create_listing_page.dart';
import 'package:cc206_west_select/features/screens/listing/edit_product_details.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> tabCounts = {'listed': 0, 'soldout': 0, 'delist': 0};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTabCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTabCounts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserId = currentUser.uid;

    final productsSnapshot = await FirebaseFirestore.instance
        .collection('post')
        .where('post_users', isEqualTo: currentUserId)
        .get();

    int listedCount = 0;
    int soldoutCount = 0;
    int delistCount = 0;

    for (var doc in productsSnapshot.docs) {
      final data = doc.data();
      final stock = data['stock'] ?? 0;
      final status = data['status'] ?? 'listed';

      if (status == 'delisted') {
        delistCount++;
      } else if (status == 'soldout' || (status == 'listed' && stock == 0)) {
        soldoutCount++;
      } else if (status == 'listed' && stock > 0) {
        listedCount++;
      }
    }

    if (mounted) {
      setState(() {
        tabCounts = {
          'listed': listedCount,
          'soldout': soldoutCount,
          'delist': delistCount,
        };
      });
    }
  }

  Future<void> _updateProductStatus(String productId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('post')
          .doc(productId)
          .update({'status': newStatus});

      _loadTabCounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Product ${newStatus == 'delisted' ? 'delisted' : 'updated'} successfully')),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update product')),
        );
      }
    }
  }

  Future<void> _restockProduct(String productId, int newStock) async {
    try {
      // Update both stock and status when restocking
      await FirebaseFirestore.instance
          .collection('post')
          .doc(productId)
          .update({
        'stock': newStock,
        'status': 'listed', // Change status back to listed when restocked
      });

      _loadTabCounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product restocked successfully')),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Restock error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restock product')),
        );
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('post')
          .doc(productId)
          .delete();

      _loadTabCounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete product')),
        );
      }
    }
  }

  Widget _buildProductCard(
      Map<String, dynamic> data, String productId, String type) {
    String image = '';
    if (data['image_urls'] != null && (data['image_urls'] as List).isNotEmpty) {
      image = data['image_urls'].first;
    } else if (data['image_urls'] != null) {
      image = data['image_urls'];
    }

    final stock = data['stock'] ?? 0;
    final price = data['price'] ?? 0;
    final sold = data['sold'] ?? 0;
    final likes = data['likes'] ?? 0;

    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade200,
                      ),
                      child: image.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                image,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.image,
                              size: 40, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['post_title'] ?? 'Product',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Php ${price.toString()}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(Icons.inventory, 'Stock: $stock'),
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.favorite, 'Like: $likes'),
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.shopping_cart, 'Sold: $sold'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditListingPage(
                                productId: productId,
                                productData: data,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Edit Details',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(data, productId, type),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (type == 'delist')
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => _showDeleteConfirmDialog(productId),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      Map<String, dynamic> data, String productId, String type) {
    switch (type) {
      case 'listed':
        return ElevatedButton(
          onPressed: () => _updateProductStatus(productId, 'delisted'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Delist', style: TextStyle(color: Colors.white)),
        );
      case 'soldout':
        return ElevatedButton(
          onPressed: () => _showRestockDialog(productId),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Restock', style: TextStyle(color: Colors.white)),
        );
      case 'delist':
        return ElevatedButton(
          onPressed: () => _showPublishDialog(productId),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Publish',
              style: TextStyle(color: Colors.white, fontSize: 13)),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showRestockDialog(String productId) {
    final TextEditingController stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restock Product'),
        content: TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter new stock quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(stockController.text) ?? 0;
              if (newStock > 0) {
                _restockProduct(productId, newStock);
                Navigator.pop(context);
              }
            },
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  void _showPublishDialog(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Product'),
        content:
            const Text('Are you sure you want to publish this product again?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateProductStatus(productId, 'listed');
              Navigator.pop(context);
            },
            child: const Text('Publish'),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
            'Are you sure you want to permanently delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteProduct(productId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabView(String type) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("User not logged in."));
    }

    final currentUserId = currentUser.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('post')
          .where('post_users', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No products found."));
        }

        final products = snapshot.data!.docs;
        final filteredProducts = products.where((product) {
          final data = product.data() as Map<String, dynamic>;
          final stock = data['stock'] ?? 0;
          final status = data['status'] ?? 'listed';

          switch (type) {
            case 'listed':
              return status == 'listed' && stock > 0;
            case 'soldout':
              return status == 'soldout' || (status == 'listed' && stock == 0);
            case 'delist':
              return status == 'delisted';
            default:
              return false;
          }
        }).toList();

        if (filteredProducts.isEmpty) {
          String message;
          switch (type) {
            case 'listed':
              message = "No listed products.";
              break;
            case 'soldout':
              message = "No sold out products.";
              break;
            case 'delist':
              message = "No delisted products.";
              break;
            default:
              message = "No products found.";
          }
          return Center(child: Text(message));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            final data = product.data() as Map<String, dynamic>;

            return _buildProductCard(data, product.id, type);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My products",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateListingPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          indicatorWeight: 2,
          tabs: [
            Tab(text: "Listed(${tabCounts['listed']})"),
            Tab(text: "Soldout(${tabCounts['soldout']})"),
            Tab(text: "Delist(${tabCounts['delist']})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabView('listed'),
          _buildTabView('soldout'),
          _buildTabView('delist'),
        ],
      ),
    );
  }
}
