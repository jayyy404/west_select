import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final double price;
  final List<String> imageUrls;
  final String sellerId; // Seller ID
  late int quantity; // Fixed to use an integer quantity

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrls,
    required this.sellerId, // Seller ID
    this.quantity = 1, // Default quantity set to 1 if not passed
  });
}

class CartModel with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Add an item to the cart
  void addToCart(String productId, String title, double price,
      List<String> imageUrls, String sellerId) {
    final existingItemIndex = _items.indexWhere((item) => item.id == productId);

    if (existingItemIndex >= 0) {
      _items[existingItemIndex].quantity++;
    } else {
      final newItem = CartItem(
        id: productId,
        title: title,
        price: price,
        imageUrls: imageUrls, // Store all images
        sellerId: sellerId,
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
    return _items.fold(
        0.0,
        (total, currentItem) =>
            total + currentItem.price * currentItem.quantity);
  }

  // Clear the cart
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
