import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Listings"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isCreatingListing = !_isCreatingListing;
                });
              },
              child: const Text("Sell a Product"),
            ),
          ),
          if (_isCreatingListing)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration:
                          const InputDecoration(labelText: "Product Title"),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: "Add Description"),
                    ),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: "Price (PHP)"),
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
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Your Listings:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('post')
                  .where('postUserId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final listings = snapshot.data!.docs;
                if (listings.isEmpty) {
                  return const Center(child: Text("No listings found."));
                }
                return ListView.builder(
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    final data = listing.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: data['image_url'] != null
                            ? Image.network(
                                data['image_url'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(data['postTitle'] ?? "No Title"),
                        subtitle: Text("PHP ${data['price'] ?? '0.0'}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteListing(listing.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print("No user is logged in.");
        return;
      }

      String userId = currentUser.uid;

      String userDisplayName = currentUser.displayName ?? 'Unknown Seller';

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

      final listingData = {
        'post_title': _titleController.text,
        'post_description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'image_url': _uploadedImageUrl,
        'post_users': userId,
        'num_comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'sellerName': userDisplayName,
      };

      await FirebaseFirestore.instance.collection('post').add(listingData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listing created successfully!")),
      );

      setState(() {
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _uploadedImageUrl = null;
        _isCreatingListing = false;
      });
    } catch (e) {
      print("Error creating listing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating listing: ${e.toString()}")),
      );
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('post')
          .doc(listingId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listing deleted successfully!")),
      );
    } catch (e) {
      print("Error deleting listing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting listing: ${e.toString()}")),
      );
    }
  }
}
