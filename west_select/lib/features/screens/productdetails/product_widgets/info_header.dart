import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InfoHeader extends StatelessWidget {
  const InfoHeader({
    super.key,
    required this.title,
    required this.price,
  });

  final String title;
  final double price;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'PHP ${NumberFormat('#,##0', 'en_US').format(price)}',
              style: const TextStyle(
                  fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}
