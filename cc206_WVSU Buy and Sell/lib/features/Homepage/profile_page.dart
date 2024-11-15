import 'package:cc206_west_select/features/Homepage/home_page.dart';
import 'package:flutter/material.dart';
import '../../firebase/auth_service.dart';
import '../edit_profile.dart';
import 'listing_page.dart';
import '../log_in.dart'; // Import LoginPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 4;
  int _selectedTab = 1; // Track which tab is selected

  void _onItemTapped(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // Update navigation based on index
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateListingPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 4:
        break;
      default:
        break;
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  Future<void> _signOut() async {
    await AuthService().signOut(); // Assuming AuthService has a signOut() method
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LogInPage()),
    ); // Redirect to LoginPage after sign-out
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
            ),
            const SizedBox(height: 10),

            // User's Name
            const Text(
              "User's name",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Introduction
            const SizedBox(height: 5),
            Text(
              'Introduction about self',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Listing Tab
                _buildTabButton("Listing", 0),

                // Pending Tab (selected by default)
                _buildTabButton("Pending", 1),

                // Completed Tab
                _buildTabButton("Completed", 2),
              ],
            ),
            const SizedBox(height: 20),

            // Placeholder Boxes
            Expanded(
              child: GridView.builder(
                itemCount: 2,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    color: Colors.grey[300],
                  );
                },
              ),
            ),

            // Sign Out Button (temporary placeholder)
            Center(
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
          color: _selectedTab == index ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: _selectedTab == index ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
