import 'package:cc206_west_select/features/screens/productdetails/seller_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerBlock extends StatelessWidget {
  const SellerBlock({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.onMsgTap,
  });

  final String sellerId;
  final String sellerName;
  final VoidCallback onMsgTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Meet the Seller',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(sellerId)
                      .get(),
                  builder: (_, snap) {
                    String? url;
                    if (snap.hasData) {
                      url = (snap.data!.data()
                          as Map<String, dynamic>?)?['profilePictureUrl'];
                    }
                    return CircleAvatar(
                      radius: 20,
                      backgroundImage: url != null && url.isNotEmpty
                          ? NetworkImage(url)
                          : null,
                      backgroundColor: Colors.grey,
                      child: (url == null || url.isEmpty)
                          ? const Icon(Icons.person,
                              size: 20, color: Colors.white)
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SellerProfileView(
                                  sellerId: sellerId,
                                  sellerName: sellerName,
                                ))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sellerName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                                decoration: TextDecoration.underline)),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(sellerId)
                              .get(),
                          builder: (_, s) {
                            if (!s.hasData || !s.data!.exists) {
                              return const SizedBox.shrink();
                            }
                            final yr = (s.data!.data()
                                as Map<String, dynamic>?)?['year'];
                            return yr == null
                                ? const SizedBox.shrink()
                                : Text('$yr',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.message_outlined),
                    onPressed: onMsgTap)
              ],
            ),
          ],
        ),
      );
}
