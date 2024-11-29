import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  _CreateListingPageState createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _uploadedImageUrl;
  bool _isCreatingListing = false;
  bool _isViewingMyProducts = false;
  bool _isViewingAllOrders = false;
  int _pendingOrderCount = 0;
  int _completedOrderCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Shop Status Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusTile("$_pendingOrderCount", "pending orders"),
                _buildStatusTile("$_completedOrderCount", "completed"),
                _buildStatusTile("1", "reviews"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action Menu Section
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text("All orders"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                _isViewingAllOrders = true;
                _isCreatingListing = false;
                _isViewingMyProducts = false;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text("My products"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                _isViewingMyProducts = true;
                _isCreatingListing = false;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Create a listing"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                _isCreatingListing = true;
                _isViewingMyProducts = false;
              });
            },
          ),
          const Divider(),
          // Listings or Form Section
          Expanded(
            child: _isCreatingListing
                ? _buildCreateListingForm()
                : _isViewingMyProducts
                    ? _buildMyProductsList()
                    : _isViewingAllOrders
                        ? _buildOrdersList()
                        : const Center(
                            child: Text("Select an option to proceed.")),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCreateListingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Product Title"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: "Add Description"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Price (PHP)"),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: uploadImageToCloudinary,
            icon: const Icon(Icons.image),
            label: const Text("Upload Image"),
          ),
          if (_uploadedImageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Image.network(
                _uploadedImageUrl!,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: createListing,
            child: const Text("Publish Listing"),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    final currentUser = FirebaseAuth.instance.currentUser; // Get the current user
    if (currentUser == null) {
      return const Center(child: Text("User not logged in."));
    }

    final String currentUserId = currentUser.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No orders found."));
        }

        final orders = snapshot.data!.docs;

        // Pre-fetch buyer names and store them in a map
        Map<String, String> buyerNames = {};

        Future<void> fetchBuyerNames() async {
          for (var order in orders) {
            final data = order.data() as Map<String, dynamic>;
            String? buyerId = data['buyerId'];
            if (buyerId != null && !buyerNames.containsKey(buyerId)) {
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(buyerId).get();
              buyerNames[buyerId] = userDoc.exists
                  ? (userDoc.data()?['displayName'] as String?) ?? 'Unknown Buyer'
                  : 'Unknown Buyer';
            }
          }
        }

        // Filter orders based on the seller
        List<QueryDocumentSnapshot> filteredOrders = orders.where((order) {
          final data = order.data() as Map<String, dynamic>;
          final products = data['products'] as List<dynamic>;
          return products.any((product) => product['sellerId'] == currentUserId);
        }).toList();

        return FutureBuilder<void>(
          future: fetchBuyerNames(),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (filteredOrders.isEmpty) {
              return const Center(child: Text("No orders for your products."));
            }

            return ListView.builder(
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                final data = order.data() as Map<String, dynamic>;

                String? buyerId = data['buyerId'];
                String buyerName = (buyerId != null && buyerNames.containsKey(buyerId))
                    ? buyerNames[buyerId]!
                    : 'Unknown Buyer';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(buyerName), // Display the fetched buyer's name
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Price: PHP ${data['total_price']}"),
                        const SizedBox(height: 8),
                        Text("Products:"),
                        for (var product in data['products'])
                          if (product['sellerId'] == currentUserId) // Only display products sold by the current user
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                "- ${product['title']} (x${product['quantity']}): PHP ${product['price']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.blue),
                      onPressed: () => markOrderAsCompleted(order.id), // Mark order as completed
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

  Future<void> markOrderAsCompleted(String orderId) async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      final orderData = orderDoc.data() as Map<String, dynamic>;

      if (orderData['status'] == 'completed') {
        return;
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'completed',
        'completed_at': DateTime.now(),
      });

      await FirebaseFirestore.instance
          .collection('completed_orders')
          .doc(orderId)
          .set(orderData);

      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order marked as completed")),
      );
    } catch (e) {
      print("Error marking order as completed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to mark order as completed")),
      );
    }
  }


  Future<void> createNewOrder(Map<String, dynamic> orderData) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("No user is logged in.");
        return;
      }

      String buyerId = currentUser.uid;  // Get buyer's ID

      // Add the buyerId to the order data
      orderData['buyerId'] = buyerId;

      // Add the order to the 'orders' collection
      await FirebaseFirestore.instance.collection('orders').add(orderData);

      // Increment the pending order count
      await FirebaseFirestore.instance.collection('shop_status').doc('status').update({
        'pending_orders': FieldValue.increment(1),
      });

      setState(() {
        _pendingOrderCount++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New order placed!")),
      );
    } catch (e) {
      print("Error creating new order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create new order")),
      );
    }
  }


  Future<void> uploadImageToCloudinary() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        if (kDebugMode) {
          print("No image selected.");
        }
        return;
      }

      File file = File(pickedFile.path);

      if (!file.existsSync()) {
        if (kDebugMode) {
          print("File does not exist: ${pickedFile.path}");
        }
        return;
      }

      String fileExtension = pickedFile.path.split('.').last.toLowerCase();
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          break;
        case 'png':
          break;
        default:
          break;
      }

      const String cloudName = 'drlvci7kt';
      const String uploadPreset = 'cndztdyy';

      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      var request = http.MultipartRequest('POST', url);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', fileExtension),
        ),
      );

      request.fields['upload_preset'] = uploadPreset;

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        String imageUrl = jsonResponse['secure_url'];

        if (kDebugMode) {
          print("Upload complete. Image URL: $imageUrl");
        }

        setState(() {
          _uploadedImageUrl = imageUrl;
        });
      } else {
        if (kDebugMode) {
          print("Upload failed with status: ${response.statusCode}");
        }
        throw Exception("Upload to Cloudinary failed");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error during upload: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: ${e.toString()}")),
      );
    }
  }

  Future<void> createListing() async {
    try {
      // Get the current user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print("No user is logged in.");
        return;
      }

      // Get the user ID and display name
      String userId = currentUser.uid;
      String userDisplayName = currentUser.displayName ?? 'Unknown Seller';

      // Check if required fields are filled
      if (_titleController.text.isEmpty ||
          _descriptionController.text.isEmpty ||
          _priceController.text.isEmpty ||
          _uploadedImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fill all fields and upload an image"),
          ),
        );
        return;
      }

      // Create the listing data including sellerId (userId)
      final listingData = {
        'post_title': _titleController.text,
        'post_description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'image_url': _uploadedImageUrl,
        'post_users': userId,  // Store sellerId (userId)
        'num_comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'sellerName': userDisplayName,
      };

      // Add the listing data to Firestore
      await FirebaseFirestore.instance.collection('post').add(listingData);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listing created successfully!")),
      );

      // Reset the form
      setState(() {
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _uploadedImageUrl = null;
        _isCreatingListing = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error creating listing: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating listing: ${e.toString()}")),
      );
    }
  }


  // Build "My Products" List
  Widget _buildMyProductsList() {
    // Track whether the delay period has elapsed
    bool isDelayElapsed = false;

    // Trigger the half-second delay using Future.delayed
    return FutureBuilder<void>(
      future: Future.delayed(const Duration(milliseconds: 500)),
      builder: (context, delaySnapshot) {
        // Update the delay tracking variable
        if (delaySnapshot.connectionState == ConnectionState.done) {
          isDelayElapsed = true;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('post')
              .where('post_users',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // Show a loading spinner if:
            // - The delay is not yet complete, or
            // - The data has not yet been fetched
            if (!isDelayElapsed || !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final listings = snapshot.data!.docs;

            // Show a "no products" message if there are no listings
            if (listings.isEmpty) {
              return const Center(child: Text("You have no products listed."));
            }

            // Render the list of products
            return ListView.builder(
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                final data = listing.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(data['post_title']),
                    subtitle: Text("PHP ${data['price']}"),
                    leading: Image.network(
                      data['image_url'] ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteListing(listing.id),
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


  Future<void> deleteListing(String listingId) async {
    try {
      // Delete listing from Firestore
      await FirebaseFirestore.instance
          .collection('post')
          .doc(listingId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listing deleted successfully")),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting listing: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete listing")),
      );
    }
  }
}
