import 'package:flutter/material.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({
    super.key,
    required this.categories,
    required this.categoryImages,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final Map<String, String> categoryImages;
  final String? selected;
  final Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Explore all categories',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF201D1B))),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (_, i) {
                final name = categories[i];
                final img = categoryImages[name]!;
                final isChosen = selected == name;

                return SizedBox(
                  width: 76,
                  child: GestureDetector(
                    onTap: () => onSelect(name),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isChosen
                                ? Colors.blue.shade100
                                : const Color(0xFFE0E0E0),
                            border: isChosen
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          child: ClipOval(
                            child: Image.asset(img,
                                width: 48, height: 48, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(name,
                            style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'Open Sans',
                                fontWeight: FontWeight.bold,
                                color: isChosen
                                    ? Colors.blue
                                    : const Color(0xFF201D1B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
