import 'package:flutter/material.dart';
import 'package:cc206_west_select/features/screens/profile/pages/pending_orders_page.dart';
import 'package:cc206_west_select/features/screens/profile/pages/user_reviews_page.dart';
import 'package:cc206_west_select/features/screens/profile/pages/order_history_page.dart';

class ShoppingSections extends StatelessWidget {
  const ShoppingSections({
    super.key,
    required this.userId,
    required this.pendingCount,
    required this.reviewsCount,
  });

  final String userId;
  final int pendingCount;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shopping',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF201D1B),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionItem(
          context,
          icon: Icons.shopping_bag_outlined,
          title: 'Pending purchases',
          subtitle: 'Orders to be delivered',
          count: pendingCount,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PendingOrdersPage(userId: userId),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionItem(
          context,
          icon: Icons.rate_review_outlined,
          title: 'Reviews',
          subtitle: 'Write about products you received',
          count: reviewsCount,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserReviewsPage(userId: userId),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionItem(
          context,
          icon: Icons.history,
          title: 'History',
          subtitle: 'Shop your past purchases',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderHistoryPage(userId: userId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    int? count,
    required VoidCallback onTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.blue[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenHeight * 0.02,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF201D1B),
                        ),
                      ),
                      if (count != null && count > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[400],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
