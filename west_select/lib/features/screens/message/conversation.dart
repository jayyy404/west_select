import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final Timestamp? lastUpdated;
  final String? transactionType;
  final String? buyerId;
  final String? sellerId;
  final String? productName;
  final double? productPrice;
  final String? productImage;

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    this.lastUpdated,
    this.transactionType,
    this.buyerId,
    this.sellerId,
    this.productName,
    this.productPrice,
    this.productImage,
  });

  factory Conversation.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participants: List<String>.from(d['participants']),
      lastMessage: d['lastMessage'] ?? '',
      lastUpdated: d['lastUpdated'] as Timestamp?,
      transactionType: d['transactionType'] as String?,
      buyerId: d['buyerId'] as String?,
      sellerId: d['sellerId'] as String?,
      productName: d['productName'] as String?,
      productPrice: (d['productPrice'] is int)
          ? (d['productPrice'] as int).toDouble()
          : d['productPrice'] as double?,
      productImage: d['productImage'] as String?,
    );
  }
}
