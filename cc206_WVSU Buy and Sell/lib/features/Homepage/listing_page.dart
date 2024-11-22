import 'package:cc206_west_select/features/Homepage/home_page.dart';
import 'package:flutter/material.dart';
import 'package:cc206_west_select/features/Homepage/profile_page.dart';
import 'user_profile_page.dart';
import 'favorite.dart';
import 'messaging.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  _CreateListingPageState createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  bool isPreOrder = false;
  int stock = 10;
  int deliveryDays = 10;
  int _currentIndex = 2;

  void navigateToHomePage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const UserProfilePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  void navigateToProfile(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const UserProfilePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  void navigateToFavorites(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CreateListingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  void navigateToMessaging(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CreateListingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  void _onItemTapped(int index) {
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
          MaterialPageRoute(builder: (context) => FavoritePage()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MessagePage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Listing"),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text("Publish", style: TextStyle(color: Colors.blue)),
          ),
        ],
        leading: TextButton(
          onPressed: () {},
          child: Text("Cancel", style: TextStyle(color: Colors.red)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Section
            Container(
              height: 150,
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 40, color: Colors.grey),
                    Text("Add images\nMust add at least 3",
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Product Details
            TextField(decoration: InputDecoration(labelText: "Product Title")),
            TextField(
                decoration: InputDecoration(labelText: "Add description")),
            TextField(decoration: InputDecoration(labelText: "Price")),
            TextField(decoration: InputDecoration(labelText: "Address")),

            SizedBox(height: 20),

            // Styles Section
            ExpansionTile(
              title: Text("Styles"),
              children: [
                ListTile(
                  leading: Icon(Icons.color_lens),
                  title: Text("Color"),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
                ListTile(
                  leading: Icon(Icons.format_size),
                  title: Text("Size"),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text("Condition"),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Inventory Section
            ExpansionTile(
              title: Text("Inventory"),
              children: [
                ListTile(
                  leading: Icon(Icons.inventory),
                  title: Row(
                    children: [
                      Text("Stock"),
                      Spacer(),
                      Text(stock.toString()),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.shopping_cart),
                  title: Text("Pre-order"),
                  trailing: Switch(
                    value: isPreOrder,
                    onChanged: (value) {
                      setState(() {
                        isPreOrder = value;
                      });
                    },
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.access_time),
                  title: Row(
                    children: [
                      Text("Days to deliver"),
                      Spacer(),
                      Text("$deliveryDays days"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Listing'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey[200],
          radius: 30,
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
