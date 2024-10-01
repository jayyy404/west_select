import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.blueAccent, 
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [

        

          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: const AssetImage('assets/pp.png'),
                backgroundColor: Colors.grey[200], // can change bg color for profile
              ),
            ),
          ),


                  
          const Center(
            child: Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 50.0), // Added bottom padding to create space
              child: Text(
                'Name: Joven Carl Rex Biaca',
                style: TextStyle(
                  fontSize: 22,  
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),


          const Divider(thickness: 1, indent: 40, endIndent: 40), // divider


          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 8.0),  
            child: Text(
              'Email: jovskbiaca@example.com',
              style: TextStyle(fontSize: 18, color: Colors.black),  
            ),
          ),


          const Divider(thickness: 1, indent: 40, endIndent: 40), // divider


          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 8.0),  
            child: Text(
              'Phone: +1234567890', 
              style: TextStyle(fontSize: 18, color: Colors.black),  
            ),
          ),


          const Divider(thickness: 1, indent: 40, endIndent: 40), // divider

          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 8.0),  
            child: Text(
              'Address: Taga Sooc, Iloilo City', 
              style: TextStyle(fontSize: 18, color: Colors.black), 
            ),
          ),


          const Divider(thickness: 1, indent: 40, endIndent: 40), // divider


          // Added extra field 
          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 8.0), 
            child: Text(
              'Occupation: Computer Science Student', 
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),

          const Divider(thickness: 1, indent: 40, endIndent: 40),

        ],
      ),
    );
  }
}
