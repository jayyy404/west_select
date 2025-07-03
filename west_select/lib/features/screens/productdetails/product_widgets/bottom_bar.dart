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
  });

  final String productId;
  final String title;
  final double price;
  final String image;
  final String ownerId;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // qty
        Row(children: [
          const Text('Quantity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  iconSize: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() {
                        if (qty > 1) qty--;
                      })),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('$qty', style: const TextStyle(fontSize: 10))),
              IconButton(
                  iconSize: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => qty++)),
            ]),
          )
        ]),
        const SizedBox(height: 2),
        // add to cart
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA42D),
                padding: const EdgeInsets.symmetric(vertical: 5)),
            onPressed: () {
              cart.addToCart(widget.productId, widget.title, widget.price,
                  [widget.image], widget.ownerId);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.title} added to cart')));
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Add to Cart',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 1),
              Text(
                  '(Subtotal: PHP ${NumberFormat("#,##0").format(widget.price * qty)})',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w400))
            ]),
          ),
        )
      ]),
    );
  }
}
