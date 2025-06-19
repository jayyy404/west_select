import 'package:flutter/material.dart';
import 'package:cc206_west_select/features/screens/favorite/favorite_page.dart';
import 'package:cc206_west_select/features/screens/message/message_page.dart';
import 'package:cc206_west_select/features/screens/home/home_page.dart';
import 'package:cc206_west_select/features/screens/listing/listing_page.dart';
import 'package:cc206_west_select/features/screens/profile/profile_page.dart';
import 'package:cc206_west_select/firebase/app_user.dart';

class MainPage extends StatefulWidget {
  final AppUser? appUser;

  const MainPage({super.key, this.appUser});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages with ProfilePage receiving appUser
    _pages = [
      HomePage(),
      FavoritePage(),
      CreateListingPage(),
      MessagePage(
        userName: '',
        receiverId: '',
      ),
      ProfilePage(
        appUser: widget.appUser!,
      ),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        width: double.infinity,
        height: 88, // Custom height
        padding: const EdgeInsets.all(10), // Custom padding
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: Offset(0, -6),
              blurRadius: 13.9,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Even spacing
          children: [
            _buildNavItem(Icons.home, Icons.home_outlined, 0),
            _buildNavItem(Icons.favorite, Icons.favorite_border, 1),
            _buildNavItem(Icons.receipt, Icons.receipt_long_outlined, 2),
            _buildNavItem(Icons.message, Icons.message_outlined, 3),
            _buildNavItem(Icons.person, Icons.person_outline, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData filledIcon, IconData outlinedIcon, int index) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Icon(
        isActive ? filledIcon : outlinedIcon,
        size: 28, // Uniform size for icons
        color: isActive
            ? Color(0xFF5191DB) // Blue for active
            : Color(0xFF6F767E), // Gray for inactive
      ),
    );
  }
}
