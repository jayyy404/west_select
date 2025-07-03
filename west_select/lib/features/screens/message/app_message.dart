import 'package:cloud_firestore/cloud_firestore.dart';

class AppMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp? timestamp;

  AppMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.timestamp,
  });

  factory AppMessage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppMessage(
      id: doc.id,
      senderId: d['senderId'],
      receiverId: d['receiverId'],
      text: d['text'],
      timestamp: d['timestamp'] as Timestamp?,
    );
  }
}
