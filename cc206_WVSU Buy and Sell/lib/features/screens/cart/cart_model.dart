import 'package:flutter/material.dart';

class CartItem {
  final String imageUrl;
  final String title;
  final String subtitle;
  final double price;
  int quantity;

  CartItem({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.price,
    this.quantity = 1,
  });
}

class CartModel extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  void addItem(CartItem item) {
    final index =
        _items.indexWhere((existingItem) => existingItem.title == item.title);
    if (index != -1) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void updateQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      _items.remove(item);
    } else {
      // Update the quantity
      item.quantity = quantity;
    }
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }
}
