// ignore_for_file: prefer_final_fields

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CreateListingForm extends StatefulWidget {
  const CreateListingForm({super.key});

  @override
  State<CreateListingForm> createState() => _CreateListingFormState();
}

class _CreateListingFormState extends State<CreateListingForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  List<String> _uploadedImageUrls = [];
  bool _isUploadingImage = false;

  void _removeImage(int index) {
    setState(() {
      _uploadedImageUrls.removeAt(index);
    });
  }

  Future<void> uploadImageToCloudinary() async {
    if (_uploadedImageUrls.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 3 images allowed")),
      );
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      File file = File(pickedFile.path);
      if (!file.existsSync()) return;

      String fileExtension = pickedFile.path.split('.').last.toLowerCase();

      const cloudName = 'drlvci7kt';
      const uploadPreset = 'cndztdyy';
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      var request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', fileExtension),
        ))
        ..fields['upload_preset'] = uploadPreset;

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        String imageUrl = jsonResponse['secure_url'];
        setState(() => _uploadedImageUrls.add(imageUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Image ${_uploadedImageUrls.length} uploaded successfully!")),
        );
      } else {
        throw Exception("Upload to Cloudinary failed");
      }
    } catch (e) {
      if (kDebugMode) print("Error during upload: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _validateAndCreateListing() {
    final priceText = _priceController.text;
    if (priceText.isEmpty || double.tryParse(priceText) == null) {
      _showErrorDialog("Please enter a valid numeric price.");
      return;
    }
    final price = double.parse(priceText);
    if (price > 100000) {
      _showErrorDialog("Price cannot exceed PHP 100,000.");
      return;
    }
    createListing();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Invalid Input"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> createListing() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      if (_titleController.text.isEmpty ||
          _descriptionController.text.isEmpty ||
          _priceController.text.isEmpty ||
          _uploadedImageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Please fill all fields and upload at least one image")),
        );
        return;
      }

      final listingData = {
        'post_title': _titleController.text,
        'post_description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'image_url': _uploadedImageUrls.first,
        'image_urls': _uploadedImageUrls,
        'post_users': currentUser.uid,
        'num_comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'sellerName': currentUser.displayName ?? 'Unknown Seller',
      };

      final docRef =
          await FirebaseFirestore.instance.collection('post').add(listingData);
      await docRef.update({'post_id': docRef.id});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listing created successfully!")),
      );

      setState(() {
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _uploadedImageUrls.clear();
      });
    } catch (e) {
      if (kDebugMode) print('Create listing error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating listing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Product Title")),
          const SizedBox(height: 16),
          TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Add Description")),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Price (PHP)"),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isUploadingImage || _uploadedImageUrls.length >= 3
                    ? null
                    : uploadImageToCloudinary,
                icon: _isUploadingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.image),
                label:
                    Text(_isUploadingImage ? "Uploading..." : "Upload Image"),
              ),
              const SizedBox(width: 8),
              Text("${_uploadedImageUrls.length}/3",
                  style: TextStyle(
                    color: _uploadedImageUrls.length >= 3
                        ? Colors.red
                        : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          if (_uploadedImageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Uploaded Images:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _uploadedImageUrls.length,
                      itemBuilder: (context, index) => Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(_uploadedImageUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _validateAndCreateListing,
              child: const Text("Publish Listing")),
        ],
      ),
    );
  }
}
