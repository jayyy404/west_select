import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  // Mock data for messages
  final List<Map<String, String>> messages = [
    {
      "name": "Prince Alexander",
      "lastMessage": "Hey, how are you?",
      "time": "10:30 AM",
      "imageUrl": "https://via.placeholder.com/150/Avatar1",
    },
    {
      "name": "John Doe",
      "lastMessage": "Your order is on the way.",
      "time": "Yesterday",
      "imageUrl": "https://via.placeholder.com/150/Avatar2",
    },
    {
      "name": "Jane Smith",
      "lastMessage": "Thanks for the update!",
      "time": "2 days ago",
      "imageUrl": "https://via.placeholder.com/150/Avatar3",
    },
  ];

  // Selected dropdown value
  String selectedRole = 'Seller';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120), // Fixed height for AppBar
        child: Container(
          width: double.infinity,
          height: 125, // AppBar height
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white, // AppBar background color
          ),
          child: SafeArea(
            child: Center(
              child: Text(
                "Messages",
                style: TextStyle(
                  color: const Color(0xFF201D1B), // Text color
                  fontFamily: "Raleway",
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.2, // Line height
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey, // Border color
                width: 0.3, // Border thickness
              ),
            ),
            child: DropdownButton<String>(
              value: selectedRole,
              isExpanded: true,
              underline: Container(),
              items: <String>['Seller', 'Buyer'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedRole = newValue!;
                });
              },
            ),
          ),

          // Messages list
          Expanded(
            child: messages.isNotEmpty
                ? ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(message['imageUrl']!),
                        ),
                        title: Text(
                          message['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(message['lastMessage']!),
                        trailing: Text(
                          message['time']!,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        onTap: () {
                          // Navigate to chat detail (implement ChatPage if needed)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                userName: message['name']!,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      "No messages yet!",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Placeholder ChatPage for navigation
class ChatPage extends StatelessWidget {
  final String userName;

  const ChatPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
        backgroundColor: Colors.white,
      ),
      body: const Center(
        child: Text("Chat screen (to be implemented)"),
      ),
    );
  }
}
