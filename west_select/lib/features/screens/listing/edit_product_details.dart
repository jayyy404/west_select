import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class EditListingPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditListingPage(
      {super.key, required this.productId, required this.productData});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _stockController;
  late TextEditingController _colorController;
  late TextEditingController _sizeController;

  String? _selectedCategory;
  String? _selectedCondition;
  List<String> _uploadedImageUrls = [];
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final data = widget.productData;

    _titleController = TextEditingController(text: data['post_title']);
    _descriptionController =
        TextEditingController(text: data['post_description']);
    _priceController = TextEditingController(text: data['price'].toString());
    _locationController = TextEditingController(text: data['location']);
    _stockController = TextEditingController(text: data['stock'].toString());
    _colorController = TextEditingController(text: data['color'] ?? '');
    _sizeController = TextEditingController(text: data['size'] ?? '');

    _selectedCategory = data['category'];
    _selectedCondition = data['condition'];
    _uploadedImageUrls = List<String>.from(data['image_urls'] ?? []);
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

      if (pickedFile == null) {
        if (mounted) setState(() => _isUploadingImage = false);
        return;
      }

      File file = File(pickedFile.path);
      if (!file.existsSync()) {
        if (mounted) setState(() => _isUploadingImage = false);
        return;
      }

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
        if (mounted) {
          setState(() => _uploadedImageUrls.add(imageUrl));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Image ${_uploadedImageUrls.length} uploaded successfully!")),
          );
        }
      } else {
        throw Exception("Upload to Cloudinary failed");
      }
    } catch (e) {
      if (kDebugMode) print("Upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload image: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImageUrls.removeAt(index);
    });
  }

  Future<void> _updateListing() async {
    setState(() => _isSubmitting = true);
    try {
      final updatedData = {
        'post_title': _titleController.text.trim(),
        'post_description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'stock': int.parse(_stockController.text.trim()),
        'condition': _selectedCondition,
        'color': _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        'size': _sizeController.text.trim().isNotEmpty
            ? _sizeController.text.trim()
            : null,
        'image_url':
            _uploadedImageUrls.isNotEmpty ? _uploadedImageUrls.first : null,
        'image_urls': _uploadedImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.productId)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing updated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e")),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _stockController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit listing",
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _updateListing,
            child: Text(
              _isSubmitting ? "Updating..." : "Update",
              style: TextStyle(
                color: _isSubmitting ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Media",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _uploadedImageUrls.isEmpty
                  ? _isUploadingImage
                      ? const Center(child: CircularProgressIndicator())
                      : InkWell(
                          onTap: uploadImageToCloudinary,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 40, color: Colors.blue.shade300),
                              const SizedBox(height: 8),
                              const Text("Add images",
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500)),
                              const Text("Must add at least 1",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          ..._uploadedImageUrls.asMap().entries.map((entry) {
                            int index = entry.key;
                            String url = entry.value;
                            return Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(url),
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
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          if (_uploadedImageUrls.length < 3)
                            InkWell(
                              onTap: uploadImageToCloudinary,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add,
                                    size: 40, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_titleController, "Product Title", true),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, "Add description", true,
                maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(_priceController, "Price", true,
                keyboardType: TextInputType.number, prefix: "PHP "),
            const SizedBox(height: 16),
            _buildTextField(_locationController, "Address", true),
            const SizedBox(height: 24),
            _buildTextField(_colorController, "Color", false),
            const SizedBox(height: 16),
            _buildTextField(_sizeController, "Size", false),
            const SizedBox(height: 24),
            _buildTextField(_stockController, "Stock", true,
                keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool required,
      {TextInputType? keyboardType, String? prefix, int maxLines = 1}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label + (required ? " *" : ""),
        prefixText: prefix,
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(
          color: required ? Colors.black : Colors.grey,
        ),
      ),
      style: TextStyle(fontSize: screenHeight * 0.02),
    );
  }
}
