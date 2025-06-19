import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagePage extends StatefulWidget {
  final String? receiverId;
  final String? userName;

  const MessagePage({super.key, this.receiverId, this.userName});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  String? selectedReceiverId;
  String? selectedUserName;

  @override
  void initState() {
    super.initState();

    if (widget.receiverId != null && widget.userName != null) {
      selectedReceiverId = widget.receiverId;
      selectedUserName = widget.userName;
    }
  }

  String get conversationId {
    final ids = [currentUserId, selectedReceiverId]..sort();
    return ids.join('_');
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUserId == null || selectedReceiverId == null) {
      return;
    }

    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);
    final messagesRef = convoRef.collection('messages');

    await messagesRef.add({
      'senderId': currentUserId,
      'receiverId': selectedReceiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await convoRef.set({
      'participants': [currentUserId, selectedReceiverId],
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  Widget buildConversationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastUpdated', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversations = snapshot.data!.docs;

        if (conversations.isEmpty) {
          return const Center(
            child: Text("No messages yet."),
          );
        }

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final data = conversations[index].data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants']);
            final otherUserId =
                participants.firstWhere((id) => id != currentUserId);
            final lastMessage = data['lastMessage'] ?? '';
            final lastUpdated = data['lastUpdated'] as Timestamp?;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnapshot) {
                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>?;
                final userName = userData?['displayName'] ?? 'User';

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(userName[0].toUpperCase()),
                  ),
                  title: Text(userName),
                  subtitle: Text(lastMessage),
                  trailing: lastUpdated != null
                      ? Text(_formatTime(lastUpdated.toDate()),
                          style: const TextStyle(fontSize: 12))
                      : null,
                  onTap: () {
                    setState(() {
                      selectedReceiverId = otherUserId;
                      selectedUserName = userName;
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildChatView() {
    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);
    final messagesQuery =
        convoRef.collection('messages').orderBy('timestamp', descending: true);

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: messagesQuery.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!.docs;

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index].data() as Map<String, dynamic>;
                  final isMe = msg['senderId'] == currentUserId;
                  final messageText = msg['text'] ?? '';
                  final timestamp = msg['timestamp'] as Timestamp?;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            messageText,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          if (timestamp != null)
                            Text(
                              _formatTime(timestamp.toDate()),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white60 : Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChatSelected =
        selectedReceiverId != null && selectedUserName != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isChatSelected ? selectedUserName! : "Messages"),
        leading: isChatSelected
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedReceiverId = null;
                    selectedUserName = null;
                  });
                },
              )
            : null,
      ),
      body: isChatSelected ? buildChatView() : buildConversationList(),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
