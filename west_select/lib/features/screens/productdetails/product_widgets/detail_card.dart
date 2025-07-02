import 'package:flutter/material.dart';

class DetailCard extends StatelessWidget {
  const DetailCard({super.key, required this.map});

  final Map<String, dynamic> map;

  Widget _row(String label, dynamic value) => value == null || '$value'.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                  width: 80,
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600))),
              Expanded(
                  child: Text('$value',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500))),
            ],
          ),
        );

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
            const SizedBox(height: 12),
            _row('Category', map['category']),
            _row('Condition', map['condition']),
            _row('Color', map['color']),
            _row('Sizing', map['size']),
          ],
        ),
      );
}
