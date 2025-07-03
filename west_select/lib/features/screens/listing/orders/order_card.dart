import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerAvatar,
    required this.products,
    required this.imgs,
    required this.statusLabel,
    required this.statusColor,
    this.onComplete,
  });

  final String orderId;
  final String buyerId;
  final String buyerName;
  final String buyerAvatar;
  final List<dynamic> products;
  final Map<String, List<String>> imgs;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Order ID: #${orderId.substring(0, 8)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(.15),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)))
            ]),
            const SizedBox(height: 8),

            // buyer row
            Row(children: [
              CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  backgroundImage:
                      buyerAvatar.isNotEmpty ? NetworkImage(buyerAvatar) : null,
                  child: buyerAvatar.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null),
              const SizedBox(width: 12),
              Text(buyerName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 12),

            // product list
            for (final p in products) _productRow(p),

            const SizedBox(height: 4),
            Text('${products.length} items',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(
                'Total Price: ₱${products.fold<num>(0, (s, p) => s + (p['price'] * p['quantity']))}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            if (onComplete != null) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('Message feature coming soon!'))),
                        child: const Text('Send a message'))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade400),
                        onPressed: onComplete,
                        child: const Text('Complete order')))
              ])
            ]
          ]),
        ),
      );

  Widget _productRow(Map<String, dynamic> p) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8)),
            child:
                imgs[p['productId']] != null && imgs[p['productId']]!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(imgs[p['productId']]![0],
                            fit: BoxFit.cover))
                    : const Icon(Icons.shopping_bag, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(p['title'] ?? 'Product',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('Quantity: ${p['quantity']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
              ])),
          Text('₱${p['price']}',
              style: const TextStyle(fontWeight: FontWeight.bold))
        ]),
      );
}
