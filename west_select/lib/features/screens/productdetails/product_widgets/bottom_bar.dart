import 'package:cc206_west_select/features/screens/cart/cart_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({
    super.key,
    required this.productId,
    required this.title,
    required this.price,
    required this.image,
    required this.ownerId,
    this.selectedSize,
    this.requiresSizeSelection = false,
    this.canAddToCart = true,
    this.onSizeRequiredMessage,
  });

  final String productId;
  final String title;
  final double price;
  final String image;
  final String ownerId;
  final String? selectedSize;
  final bool requiresSizeSelection;
  final bool canAddToCart;
  final VoidCallback? onSizeRequiredMessage;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int qty = 1;

  void handleAddToCart() {
    if (widget.requiresSizeSelection && widget.selectedSize == null) {
      if (widget.onSizeRequiredMessage != null) {
        widget.onSizeRequiredMessage!();
      }
      return;
    }

    final cart = Provider.of<CartModel>(context, listen: false);
    cart.addItem(
      productId: widget.productId,
      title: widget.title,
      price: widget.price,
      image: widget.image,
      quantity: qty,
      ownerId: widget.ownerId,
      size: widget.selectedSize,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.title} added to cart!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Text('Quantity',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            height: 38,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                iconSize: 14,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                icon: const Icon(Icons.remove, size: 14),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => setState(() {
                  if (qty > 1) qty--;
                }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('$qty', style: const TextStyle(fontSize: 15)),
              ),
              IconButton(
                iconSize: 16,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                icon: const Icon(Icons.add, size: 14),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => setState(() => qty++),
              ),
            ]),
          )
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.canAddToCart ? handleAddToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA42D),
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 36),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Add to Cart',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                  '(Subtotal: PHP ${NumberFormat("#,##0").format(widget.price * qty)})',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w400))
            ]),
          ),
        )
      ]),
    );
  }
}
