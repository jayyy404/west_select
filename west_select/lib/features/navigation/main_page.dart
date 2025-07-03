import 'package:flutter/material.dart';
import 'package:cc206_west_select/features/screens/favorite/favorite_page.dart';
import 'package:cc206_west_select/features/screens/message/message_page.dart';
import 'package:cc206_west_select/features/screens/home/home_page.dart';
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

  // Keep reference to HomePage
  late HomePage _homePage;

  @override
  void initState() {
    super.initState();
    _homePage = const HomePage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: Container(
        width: double.infinity,
        height: 88,
        padding: const EdgeInsets.all(10),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _homePage;
      case 1:
        return FavoritePage();
      case 2:
        return MessagePage();
      case 3:
        return MessagePage();
      case 4:
        return ProfilePage(appUser: widget.appUser!);
      default:
        return _homePage;
    }
  }

  void _onTabTapped(int index) {
    // If clicking on home button (index 0) and we're already on home page, clear filters
    if (index == 0 && _currentIndex == 0) {
      // We need to recreate the home page to trigger a refresh
      setState(() {
        _homePage = const HomePage();
      });
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildNavItem(IconData filledIcon, IconData outlinedIcon, int index) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Icon(
        isActive ? filledIcon : outlinedIcon,
        size: 28,
        color: isActive ? Color(0xFF5191DB) : Color(0xFF6F767E),
      ),
    );
  }
}
