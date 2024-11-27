import 'package:flutter/material.dart';

class MessagePage extends StatelessWidget {
  MessagePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: messages.isNotEmpty
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
              style: const TextStyle(color: Colors.grey, fontSize: 12),
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
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text("Chat screen (to be implemented)"),
      ),
    );
  }
}
