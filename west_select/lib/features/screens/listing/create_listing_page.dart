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

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _stockController = TextEditingController();
  final _colorController = TextEditingController();
  final _sizeController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCondition;
  // Replace single size selection with a list
  List<String> _selectedSizes = [];

  List<String> _uploadedImageUrls = [];
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'School Supplies',
    'Footwear',
    'Merch',
    'Gadgets',
    'Clothing',
    'Food'
  ];

  final List<String> _conditions = ['New', 'Rarely used', 'Used'];

  final List<String> _clothingSizes = ['S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _footwearSizes = [
    '35',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
    '45',
    '46'
  ];

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
      if (pickedFile == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      File file = File(pickedFile.path);
      if (!file.existsSync()) {
        setState(() => _isUploadingImage = false);
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
        setState(() => _uploadedImageUrls.add(imageUrl));
        if (mounted) {
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
      if (kDebugMode) print("Error during upload: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload image: $e")),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Categories'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pick only 1 category.',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories
                  .map(
                    (category) => FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          if (_selectedCategory != category) {
                            // Reset sizes when changing category
                            _selectedSizes = [];
                            _sizeController.clear();
                          }
                          _selectedCategory = selected ? category : null;
                        });
                        Navigator.pop(context);
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showConditionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Condition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pick only 1 condition.',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _conditions
                  .map(
                    (condition) => FilterChip(
                      label: Text(condition),
                      selected: _selectedCondition == condition,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCondition = selected ? condition : null;
                        });
                        Navigator.pop(context);
                      },
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSizeDialog() {
    if (_selectedCategory == null) {
      _showErrorDialog("Please select a category first.");
      return;
    }

    List<String> sizeOptions = [];
    String dialogTitle = "Select Size";

    // Create a temporary copy of selected sizes for the dialog
    List<String> tempSelectedSizes = List.from(_selectedSizes);

    if (_selectedCategory == 'Clothing') {
      sizeOptions = _clothingSizes;
      dialogTitle = "Select Clothing Sizes";
    } else if (_selectedCategory == 'Footwear') {
      sizeOptions = _footwearSizes;
      dialogTitle = "Select Footwear Sizes";
    } else {
      // For other categories, use the regular size input field
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(dialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select all available sizes:',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sizeOptions
                    .map(
                      (size) => FilterChip(
                        label: Text(size),
                        selected: tempSelectedSizes.contains(size),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              tempSelectedSizes.add(size);
                            } else {
                              tempSelectedSizes.remove(size);
                            }
                          });
                        },
                        selectedColor: Colors.blue.shade100,
                        checkmarkColor: Colors.blue,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update both the global state and the text controller
                this.setState(() {
                  _selectedSizes = tempSelectedSizes;
                  if (_selectedSizes.isNotEmpty) {
                    _sizeController.text = _selectedSizes.join(', ');
                  } else {
                    _sizeController.clear();
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
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
    final price = double.parse(priceText);
    if (price <= 0) {
      _showErrorDialog("Price must be greater than 0.");
      return false;
    }
    if (price > 100000) {
      _showErrorDialog("Price cannot exceed PHP 100,000.");
      return false;
    }

    if (_locationController.text.trim().isEmpty) {
      _showErrorDialog("Please enter a location.");
      return false;
    }

    if (_selectedCategory == null) {
      _showErrorDialog("Please select a category.");
      return false;
    }

    if (_selectedCategory == 'Clothing' || _selectedCategory == 'Footwear') {
      if (_selectedSizes.isEmpty) {
        _showErrorDialog(
            "Please select at least one size for this ${_selectedCategory?.toLowerCase()}.");
        return false;
      }
    }

    final stockText = _stockController.text.trim();
    if (stockText.isEmpty || int.tryParse(stockText) == null) {
      _showErrorDialog("Please enter a valid stock quantity.");
      return false;
    }
    final stock = int.parse(stockText);
    if (stock < 0) {
      _showErrorDialog("Stock cannot be negative.");
      return false;
    }

    if (_uploadedImageUrls.isEmpty) {
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

  Future<void> _createListing() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      final listingData = {
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
        'size':
            _selectedCategory == 'Clothing' || _selectedCategory == 'Footwear'
                ? _selectedSizes // Store as array for clothing/footwear
                : (_sizeController.text.trim().isNotEmpty
                    ? _sizeController.text.trim()
                    : null),
        'image_url': _uploadedImageUrls.first,
        'image_urls': _uploadedImageUrls,
        'post_users': currentUser.uid,
        'num_comments': 0,
        'likes': 0,
        'sold': 0,
        'status': 'listed',
        'createdAt': FieldValue.serverTimestamp(),
        'sellerName': currentUser.displayName ?? 'Unknown Seller',
      };

      final docRef =
          await FirebaseFirestore.instance.collection('post').add(listingData);
      await docRef.update({'post_id': docRef.id});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing created successfully!")),
        );
        Navigator.pop(context); // Go back to previous page
      }
    } catch (e) {
      if (kDebugMode) print('Create listing error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating listing: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
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
          "Create listing",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _createListing,
            child: Text(
              _isSubmitting ? "Publishing..." : "Publish",
              style: TextStyle(
                color: _isSubmitting ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Section
            const Text(
              "Media",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.blue, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _uploadedImageUrls.isEmpty
                  ? InkWell(
                  onTap: _isUploadingImage ? null : uploadImageToCloudinary,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown, // 👈 This scales child down if needed
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.blue.shade300,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Add images",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            "Must add at least 1",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          if (_isUploadingImage)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                  )
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
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          if (_uploadedImageUrls.length < 3)
                            InkWell(
                              onTap: _isUploadingImage
                                  ? null
                                  : uploadImageToCloudinary,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _isUploadingImage
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : const Icon(Icons.add,
                                        size: 40, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Required Fields
            _buildTextField(
              controller: _titleController,
              label: "Product Title",
              required: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _descriptionController,
              label: "Add description",
              required: true,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _priceController,
              label: "Price",
              required: true,
              keyboardType: TextInputType.number,
              prefix: "PHP ",
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _locationController,
              label: "Address",
              required: true,
            ),
            const SizedBox(height: 16),

            // Product Description Section
            const Text(
              "Product Description",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Category (Required)
            _buildSelectableField(
              label: "Category",
              value: _selectedCategory,
              required: true,
              onTap: _showCategoryDialog,
            ),
            const SizedBox(height: 16),

            // Condition (Optional)
            _buildSelectableField(
              label: "Condition",
              value: _selectedCondition,
              required: false,
              onTap: _showConditionDialog,
            ),
            const SizedBox(height: 16),

            // Color (Optional)
            _buildTextField(
              controller: _colorController,
              label: "Color",
              required: false,
            ),
            const SizedBox(height: 16),

            // Size field - conditional based on category
            if (_selectedCategory == 'Clothing' ||
                _selectedCategory == 'Footwear')
              _buildSelectableField(
                label: _selectedCategory == 'Clothing'
                    ? "Clothing Size"
                    : "Footwear Size",
                value: _selectedSizes.isNotEmpty
                    ? _selectedSizes.join(", ")
                    : null,
                required: true,
                onTap: _showSizeDialog,
              )
            else
              _buildTextField(
                controller: _sizeController,
                label: "Size",
                required: false,
              ),
            const SizedBox(height: 16),

            // Inventory Section
            const Text(
              "Inventory",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _stockController,
              label: "Stock",
              required: true,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool required,
    TextInputType? keyboardType,
    String? prefix,
    int maxLines = 1,
  }) {
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
    );
  }

  Widget _buildSelectableField({
    required String label,
    required dynamic value,
    required bool required,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              required ? Icons.add_circle_outline : Icons.add_circle_outline,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                // For clothing and footwear sizes, show the selected sizes
                (label.contains("Size") && _selectedSizes.isNotEmpty)
                    ? _selectedSizes.join(", ")
                    : (value != null
                        ? value.toString()
                        : label + (required ? " *" : "")),
                style: TextStyle(
                  fontSize: 16,
                  color:
                      (label.contains("Size") && _selectedSizes.isNotEmpty) ||
                              value != null
                          ? Colors.black
                          : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
