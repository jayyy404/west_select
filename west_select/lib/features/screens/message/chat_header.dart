import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'product_info.dart';

class ChatHeader extends StatelessWidget {
  final String conversationId;
  final String? explicitProductName;
  final double? explicitProductPrice;
  final String? explicitProductImage;
  final String? peerName;
  final bool explicitIsBuying;

  const ChatHeader({
    super.key,
    required this.conversationId,
    this.explicitProductName,
    this.explicitProductPrice,
    this.explicitProductImage,
    this.peerName,
    this.explicitIsBuying = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          if (explicitProductName != null &&
              explicitProductPrice != null &&
              explicitProductImage != null)
            ProductInfo(
              name: explicitProductName!,
              price: explicitProductPrice!,
              image: explicitProductImage!,
              isBuying: explicitIsBuying,
            )
          else
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(conversationId)
                  .get(),
              builder: (_, snap) {
                if (!snap.hasData || !snap.data!.exists) {
                  return const SizedBox.shrink();
                }
                final d = snap.data!.data() as Map<String, dynamic>;
                final pn = d['productName'] as String?;
                final pp = d['productPrice'] as double?;
                final pi = d['productImage'] as String?;
                if (pn != null && pp != null && pi != null) {
                  final isBuying =
                      (d['transactionType'] == 'buy' && d['buyerId'] == null)
                          ? true
                          : d['buyerId'] == null;
                  return ProductInfo(
                    name: pn,
                    price: pp,
                    image: pi,
                    isBuying: isBuying,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          if (peerName != null)
            Text(
              'Conversation with $peerName',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
