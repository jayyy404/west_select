import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final double price;
  final String imageUrl;
  final String sellerId;  // Seller ID
  late final int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.sellerId,  // Seller ID
    required this.quantity,
  });
}

class CartModel with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Add an item to the cart
  void addToCart(String productId, String productTitle, double productPrice, String imageUrl, String sellerId) {
    final existingItemIndex = _items.indexWhere((item) => item.id == productId);
    if (existingItemIndex >= 0) {
      _items[existingItemIndex].quantity += 1;
    } else {
      _items.add(CartItem(
        id: productId,
        title: productTitle,
        price: productPrice,
        imageUrl: imageUrl,
        sellerId: sellerId,  // Include sellerId here
        quantity: 1,
      ));
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
