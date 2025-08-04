import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cc206_west_select/services/notification_service.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.notificationService,
    required this.onBellTap,
    required this.onCartTap,
    required this.searchController,
    required this.onSearchClear,
    required this.onSearchSubmit,
  });

  final String userName;
  final NotificationService notificationService;
  final VoidCallback onBellTap;
  final VoidCallback onCartTap;
  final TextEditingController searchController;
  final VoidCallback onSearchClear;
  final VoidCallback onSearchSubmit;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.03),
          child: Column(
            children: [
              // Top row with greeting and icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hello, $userName',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenHeight * 0.026, // ~20 on standard screen
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      StreamBuilder<int>(
                          stream: notificationService.getUnreadCount(
                              FirebaseAuth.instance.currentUser?.uid ?? ''),
                          builder: (context, snap) {
                            final n = snap.data ?? 0;
                            return Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications,
                                      color: Colors.white, size: 24),
                                  onPressed: onBellTap,
                                ),
                                if (n > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 16),
                                      height: 16,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          n > 99 ? '99+' : '$n',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenHeight * 0.014, // ~10 on standard screen
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                      IconButton(
                          icon: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white, size: 24),
                          onPressed: onCartTap),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search bar inside the header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onSubmitted: (_) => onSearchSubmit(),
                  onChanged: (v) {
                    if (v.isEmpty) onSearchClear();
                  },
                  decoration: InputDecoration(
                    hintText: 'What are you looking for?',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: screenHeight * 0.018, // ~14 standard
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: onSearchClear,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02),
                  ),
                  style: TextStyle(fontSize: screenHeight * 0.02),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
