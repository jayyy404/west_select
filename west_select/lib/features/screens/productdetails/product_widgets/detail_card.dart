import 'package:flutter/material.dart';

class DetailCard extends StatefulWidget {
  const DetailCard({
    super.key,
    required this.map,
    required this.onSizeSelected,
  });

  final Map<String, dynamic> map;
  final Function(String?) onSizeSelected;

  @override
  State<DetailCard> createState() => _DetailCardState();
}

class _DetailCardState extends State<DetailCard> {
  String? selectedSize;

  // Check if this is a clothing or footwear item that needs size selection
  bool get requiresSizeSelection =>
      widget.map['category'] == 'Clothing' ||
      widget.map['category'] == 'Footwear';

  // Convert size data to a list regardless of how it's stored
  List<String> get availableSizes {
    final size = widget.map['size'];
    if (size == null) return [];

    // Handle different ways size might be stored
    if (size is List) {
      return List<String>.from(size);
    } else if (size is String) {
      return size.split(',').map((s) => s.trim()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _detailColumn('Category', widget.map['category']),
                const SizedBox(width: 16),
                _detailColumn('Condition', widget.map['condition']),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _detailColumn('Color', widget.map['color']),
                const SizedBox(width: 16),
                requiresSizeSelection
                    ? _buildSizeSelectorColumn()
                    : _detailColumn('Sizing', widget.map['size']),
              ],
            ),
          ],
        ),
      );

  Widget _detailColumn(String label, dynamic value) =>
      value == null || '$value'.isEmpty
          ? const SizedBox.shrink()
          : Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );

  Widget _buildSizeSelectorColumn() => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Size',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select size:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableSizes.map((size) {
                return ChoiceChip(
                  label: Text(size),
                  selected: selectedSize == size,
                  onSelected: (selected) {
                    setState(() {
                      selectedSize = selected ? size : null;
                    });

                    widget.onSizeSelected(selectedSize);
                  },
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: selectedSize == size
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
}
