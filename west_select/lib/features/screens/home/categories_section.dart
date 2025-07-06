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
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 350;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Explore all categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF201D1B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 85, // Slightly more to accommodate text
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
              itemBuilder: (_, i) {
                final name = categories[i];
                final img = categoryImages[name]!;
                final isChosen = selected == name;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
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
                            child: Image.asset(
                              img,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60, // Restrict text container
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              fontFamily: 'Open Sans',
                              fontWeight: FontWeight.bold,
                              color: isChosen
                                  ? Colors.blue
                                  : const Color(0xFF201D1B),
                            ),
                          ),
                        ),
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
