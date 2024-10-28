import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  UserProfilePageState createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  bool isAlternateImage = false;

  // Method to simulate changing profile image on tap
  void toggleProfileImage() {
    setState(() {
      isAlternateImage = !isAlternateImage;
    });
  }

  // Method to show a dialog when a button is pressed
  void showMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Info'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Method to show a popup when tapping on a card
  void showCardPopup(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: const Text('This is some information about this item.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double profileImageRadius = screenHeight * 0.1;
    final double fontSize = screenHeight * 0.03;
    final double paddingHorizontal = screenWidth * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              showMessage('Settings page coming soon');
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: toggleProfileImage,
              child: CircleAvatar(
                radius: profileImageRadius,
                backgroundColor: Colors.grey[300],
                child: Icon(
                  isAlternateImage ? Icons.person_outline : Icons.person,
                  size: profileImageRadius,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "User's name",
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Introduction about self',
              style: TextStyle(
                fontSize: fontSize * 0.7,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showMessage('Showing Listing items');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                  ),
                  child: const Text('Listing'),
                ),
                SizedBox(width: screenWidth * 0.03),
                ElevatedButton(
                  onPressed: () {
                    showMessage('Showing Pending items');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Pending'),
                ),
                SizedBox(width: screenWidth * 0.03),
                ElevatedButton(
                  onPressed: () {
                    showMessage('Showing Completed items');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                  ),
                  child: const Text('Completed'),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            Expanded(
              child: ListView(
                children: [
                  // Dismissable widget for swipe-to-delete functionality
                  Dismissible(
                    key: UniqueKey(),
                    onDismissed: (direction) {
                      showMessage('Item dismissed');
                    },
                    background: Container(color: Colors.red),
                    child: GestureDetector(
                      onTap: () {
                        showCardPopup('Listing Item');
                      },
                      child: Container(
                        height: screenHeight * 0.2,
                        margin: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.01),
                        width: screenWidth * 0.4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('Listing Item'),
                        ),
                      ),
                    ),
                  ),
                  Dismissible(
                    key: UniqueKey(),
                    onDismissed: (direction) {
                      showMessage('Item dismissed');
                    },
                    background: Container(color: Colors.red),
                    child: GestureDetector(
                      onTap: () {
                        showCardPopup('Pending Item');
                      },
                      child: Container(
                        height: screenHeight * 0.2,
                        margin: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.01),
                        width: screenWidth * 0.4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('Pending Item'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
