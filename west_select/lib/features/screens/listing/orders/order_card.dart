import 'package:flutter/material.dart';
import 'package:cc206_west_select/features/screens/message/message_service.dart';
import 'package:cc206_west_select/features/screens/message/message_page.dart';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ID: #${orderId.substring(0, 8)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade300,
                    child: buyerAvatar.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              buyerAvatar,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              loadingBuilder: (c, w, p) => p == null
                                  ? w
                                  : const CircularProgressIndicator(
                                      strokeWidth: 2),
                              errorBuilder: (c, e, s) => const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24),
                            ),
                          )
                        : const Icon(Icons.person,
                            color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    buyerName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final p in products) _productRow(p),
              const SizedBox(height: 4),
              Text(
                '${products.length} items',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              _buildSizeSummary(),
              const SizedBox(height: 8),
              Text(
                'Total Price: ₱${products.fold<num>(0, (s, p) => s + (p['price'] * p['quantity']))}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (onComplete != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _sendMessage(context, buyerId, buyerName),
                        child: const Text('Send a message'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade400,
                        ),
                        onPressed: onComplete,
                        child: const Text('Complete order'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Widget _productRow(Map<String, dynamic> p) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // product image
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: imgs[p['productId']] != null &&
                      imgs[p['productId']]!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imgs[p['productId']]![0],
                        fit: BoxFit.cover,
                        loadingBuilder: (c, w, p) => p == null
                            ? w
                            : Center(
                                child: CircularProgressIndicator(
                                  value: p.expectedTotalBytes != null
                                      ? p.cumulativeBytesLoaded /
                                          p.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.shopping_bag, size: 20),
                      ),
                    )
                  : const Icon(Icons.shopping_bag, size: 20),
            ),
            const SizedBox(width: 12),

            // title / qty / size
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['title'] ?? 'Product',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),

                  // Quantity
                  Text(
                    'Quantity: ${p['quantity']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  // Size – shown only if present
                  _buildSizeInfo(p),
                ],
              ),
            ),

            // price
            Text(
              '₱${p['price']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildSizeInfo(Map<String, dynamic> p) {
    final dynamic size =
        p['size'] ?? p['selectedSize'] ?? p['sizeSelected'] ?? p['variantSize'];

    final dynamic nestedSize = size ??
        (p['variant'] is Map ? p['variant']['size'] : null) ??
        (p['attributes'] is Map ? p['attributes']['size'] : null);

    if (nestedSize == null || nestedSize.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      'Size: $nestedSize',
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
    );
  }

  Widget _buildSizeSummary() {
    final Map<String, int> sizeQuantities = {};

    for (final product in products) {
      final size = _extractSizeValue(product);
      final qty = (product['quantity'] ?? 1) as int;

      if (size != null && size.toString().isNotEmpty) {
        sizeQuantities[size] = (sizeQuantities[size] ?? 0) + qty;
      }
    }

    if (sizeQuantities.isEmpty) return const SizedBox.shrink();

    final sizeTexts =
        sizeQuantities.entries.map((e) => '${e.key} (×${e.value})').toList();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'Sizes: ${sizeTexts.join(', ')}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }

  dynamic _extractSizeValue(Map<String, dynamic> product) {
    const _tryKeys = [
      'size',
      'selectedSize',
      'sizeSelected',
      'sizeValue',
      'variantSize',
    ];

    for (final k in _tryKeys) {
      if (product[k] != null) return product[k];
    }

    for (final entry in product.entries) {
      if (entry.key.toLowerCase().contains('size') && entry.value != null) {
        return entry.value;
      }
    }
    return null;
  }

  void _sendMessage(
      BuildContext context, String buyerId, String buyerName) async {
    try {
      final convoId = await MessagesService.resolveCurrentConversation(
        otherId: buyerId,
        fromProductPage: false,
        productName: null,
        activeTabIndex: 1, // seller’s “Sell” tab
        fromPendingOrders: false,
      );

      if (convoId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessagePage(
              receiverId: buyerId,
              userName: buyerName,
              fromPendingOrders: false,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
