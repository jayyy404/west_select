import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final double price;
  final String imageUrl;
  final String sellerId;  // Seller ID
  late int quantity;      // Fixed to use an integer quantity

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.sellerId,  // Seller ID
    this.quantity = 1,       // Default quantity set to 1 if not passed
  });
}

class CartModel with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Add an item to the cart
  void addToCart(String productId, String title, double price, String imageUrl, String sellerId) {
    // Check if the item is already in the cart
    final existingItemIndex = _items.indexWhere((item) => item.id == productId);

    if (existingItemIndex >= 0) {
      // If the item already exists, just increase the quantity
      _items[existingItemIndex].quantity++;
    } else {
      // Otherwise, add the new item with default quantity of 1
      final newItem = CartItem(
        id: productId,  // The productId (post_id)
        title: title,
        price: price,
        imageUrl: imageUrl,
        sellerId: sellerId,  // The seller ID
      );
      _items.add(newItem);
    }

    notifyListeners();
  }

  // Remove an item from the cart
  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  // Update the quantity of a cart item
  void updateQuantity(CartItem item, int newQuantity) {
    if (newQuantity <= 0) {
      _items.remove(item);
    } else {
      item.quantity = newQuantity;
    }
    notifyListeners();
  }

  // Calculate total price
  double get totalPrice {
    return _items.fold(0.0, (total, currentItem) => total + currentItem.price * currentItem.quantity);
  }

  // Clear the cart
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
