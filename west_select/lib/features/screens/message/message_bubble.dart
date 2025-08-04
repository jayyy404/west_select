import 'package:cc206_west_select/features/screens/message/time_utils.dart';
import 'package:cc206_west_select/features/screens/message/message_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final Timestamp? timestamp;
  final String? conversationId;
  final String? otherUserId;

  const MessageBubble({
    super.key,
    required this.isMe,
    required this.text,
    required this.timestamp,
    this.conversationId,
    this.otherUserId,
  });

  String _getDecryptedText() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    //return original text
    if (conversationId == null ||
        otherUserId == null ||
        currentUserId == null) {
      return text;
    }

    // Check if the message is encrypted
    if (!MessagesService.isMessageEncrypted(text)) {
      return text;
    }

    // Decrypt the message
    return MessagesService.decryptMessage(
      encryptedText: text,
      conversationId: conversationId!,
      senderId: isMe ? currentUserId : otherUserId!,
      receiverId: isMe ? otherUserId! : currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final decryptedText = _getDecryptedText();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF5191DB) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    decryptedText,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      TimeUtils.formatBubbleTime(timestamp!.toDate()),
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubbleAuto extends StatefulWidget {
  final bool isMe;
  final String text;
  final Timestamp? timestamp;
  final String messageId;
  final String conversationId;

  const MessageBubbleAuto({
    super.key,
    required this.isMe,
    required this.text,
    required this.timestamp,
    required this.messageId,
    required this.conversationId,
  });

  @override
  State<MessageBubbleAuto> createState() => _MessageBubbleAutoState();
}

class _MessageBubbleAutoState extends State<MessageBubbleAuto> {
  String? _decryptedText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _decryptMessage();
  }

  Future<void> _decryptMessage() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      setState(() {
        _decryptedText = widget.text;
      });
      return;
    }

    try {
      // Check if the message is encrypted
      if (!MessagesService.isMessageEncrypted(widget.text)) {
        setState(() {
          _decryptedText = widget.text;
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Get conversation to find other participant
      final convoDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .get();

      if (!convoDoc.exists) {
        setState(() {
          _decryptedText = widget.text;
          _isLoading = false;
        });
        return;
      }

      final convoData = convoDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(convoData['participants'] ?? []);
      final otherUserId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) {
        setState(() {
          _decryptedText = widget.text;
          _isLoading = false;
        });
        return;
      }

      // Decrypt the message
      final decrypted = MessagesService.decryptMessage(
        encryptedText: widget.text,
        conversationId: widget.conversationId,
        senderId: widget.isMe ? currentUserId : otherUserId,
        receiverId: widget.isMe ? otherUserId : currentUserId,
      );

      setState(() {
        _decryptedText = decrypted;
        _isLoading = false;
      });
    } catch (e) {
      print('Error decrypting message: $e');
      setState(() {
        _decryptedText = widget.text;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator only for encrypted messages
    if (_isLoading && MessagesService.isMessageEncrypted(widget.text)) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isMe ? const Color(0xFF5191DB) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                  bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isMe ? Colors.white70 : Colors.grey[400]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Decrypting...',
                    style: TextStyle(
                      color: widget.isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return MessageBubble(
      isMe: widget.isMe,
      text: _decryptedText ?? widget.text,
      timestamp: widget.timestamp,
    );
  }
}
