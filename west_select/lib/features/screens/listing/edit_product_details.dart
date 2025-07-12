import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';

class EditListingPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditListingPage({super.key, required this.productId, required this.productData});

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
  List<UploadedImage> _uploadedImages = [];
  List<File> _pendingImages = [];
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final data = widget.productData;

    _titleController = TextEditingController(text: data['post_title']);
    _descriptionController = TextEditingController(text: data['post_description']);
    _priceController = TextEditingController(text: data['price'].toString());
    _locationController = TextEditingController(text: data['location']);
    _stockController = TextEditingController(text: data['stock'].toString());
    _colorController = TextEditingController(text: data['color'] ?? '');
    _sizeController = TextEditingController(text: data['size']?.toString() ?? '');

    _selectedCategory = data['category'];
    _selectedCondition = data['condition'];

    // Load existing images into _uploadedImages
    final existingImages = List<Map<String, dynamic>>.from(data['image_data'] ?? []);
    _uploadedImages = existingImages.map((e) => UploadedImage(url: e['url'], publicId: e['public_id'])).toList();
  }

  // Future<void> uploadImageToCloudinary() async {
  //   if (_uploadedImages.length >= 3) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Maximum 3 images allowed")),
  //     );
  //     return;
  //   }
  //
  //   setState(() => _isUploadingImage = true);
  //
  //   try {
  //     final picker = ImagePicker();
  //     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  //     if (pickedFile == null) return;
  //
  //     File file = File(pickedFile.path);
  //     final uploaded = await CloudinaryService.uploadImage(file);
  //
  //     if (uploaded != null && uploaded.url.isNotEmpty) {
  //       setState(() => _uploadedImages.add(uploaded));
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Image ${_uploadedImages.length} uploaded!")),
  //       );
  //     } else {
  //       throw Exception("Upload to Cloudinary failed");
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Failed to upload image: $e")),
  //     );
  //   } finally {
  //     setState(() => _isUploadingImage = false);
  //   }
  // }
  Future<void> pickImage() async {
    if ((_uploadedImages.length + _pendingImages.length) >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 3 images allowed")),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pendingImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove this image?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirm != true) return;

    final uploadedImage = _uploadedImages[index];
    String? publicId = uploadedImage.publicId;

    if (publicId == null || publicId.isEmpty) {
      publicId = CloudinaryService.extractPublicIdFromUrl(uploadedImage.url);
    }

    if (publicId == null || publicId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot remove image: missing public_id.")),
      );
      return;
    }

    final success = await CloudinaryService.deleteImage(publicId);

    if (success) {
      setState(() => _uploadedImages.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image removed successfully.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete image from Cloudinary.")),
      );
    }
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showErrorDialog("Please enter a product title.");
      return false;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showErrorDialog("Please enter a product description.");
      return false;
    }

    final priceText = _priceController.text.trim();
    if (priceText.isEmpty || double.tryParse(priceText) == null) {
      _showErrorDialog("Please enter a valid numeric price.");
      return false;
    }

    if (_locationController.text.trim().isEmpty) {
      _showErrorDialog("Please enter a location.");
      return false;
    }

    final stockText = _stockController.text.trim();
    if (stockText.isEmpty || int.tryParse(stockText) == null) {
      _showErrorDialog("Please enter a valid stock quantity.");
      return false;
    }

    // check images
    if (_uploadedImages.isEmpty && _pendingImages.isEmpty) {
      _showErrorDialog("Please upload at least one image.");
      return false;
    }

    return true;
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

  Future<void> _updateListing() async {
    if (!_validateForm()) return;
    setState(() => _isSubmitting = true);
    try {
      // Upload pending images
      for (final file in _pendingImages) {
        final uploaded = await CloudinaryService.uploadImage(file);
        if (uploaded != null && uploaded.url.isNotEmpty) {
          _uploadedImages.add(uploaded);
        } else {
          throw Exception("Failed to upload one or more images.");
        }
      }
      _pendingImages.clear();

      final updatedData = {
        'post_title': _titleController.text.trim(),
        'post_description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'stock': int.parse(_stockController.text.trim()),
        'condition': _selectedCondition,
        'color': _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
        'size': _sizeController.text.trim().isNotEmpty ? _sizeController.text.trim() : null,
        'image_url': _uploadedImages.isNotEmpty ? _uploadedImages.first.url : null,
        'image_urls': _uploadedImages.map((e) => e.url).toList(),
        'image_data': _uploadedImages.map((e) => {'url': e.url, 'public_id': e.publicId}).toList(),
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
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
            const Text("Media", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _uploadedImages.isEmpty
                  ? InkWell(
                onTap: _isUploadingImage ? null : pickImage,
                child: Center(
                  child: _isUploadingImage
                      ? const CircularProgressIndicator()
                      : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.blue.shade300),
                      const SizedBox(height: 8),
                      const Text("Add images", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                      const Text("Must add at least 1", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              )
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ..._uploadedImages.map((e) => e.url).toList()
                        .followedBy(_pendingImages.map((file) => file.path))
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      int index = entry.key;
                      String urlOrPath = entry.value;
                      bool isLocalFile = index >= _uploadedImages.length;
                      return Container(
                        // same container
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image(
                                image: isLocalFile ? FileImage(File(urlOrPath)) : NetworkImage(urlOrPath) as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isLocalFile) {
                                      _pendingImages.removeAt(index - _uploadedImages.length);
                                    } else {
                                      _removeImage(index);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    if (_uploadedImages.length < 3)
                      InkWell(
                        onTap: _isUploadingImage ? null : pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _isUploadingImage
                              ? const Center(child: CircularProgressIndicator())
                              : const Icon(Icons.add, size: 40, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_titleController, "Product Title", true),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, "Add description", true, maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(_priceController, "Price", true, keyboardType: TextInputType.number, prefix: "PHP "),
            const SizedBox(height: 16),
            _buildTextField(_locationController, "Address", true),
            const SizedBox(height: 24),
            _buildTextField(_colorController, "Color", false),
            const SizedBox(height: 16),
            _buildTextField(_sizeController, "Size", false),
            const SizedBox(height: 24),
            _buildTextField(_stockController, "Stock", true, keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool required,
      {TextInputType? keyboardType, String? prefix, int maxLines = 1}) {
    final screenHeight = MediaQuery.of(context).size.height;

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
