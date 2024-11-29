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

  // Add an item to the cart or update the quantity if it already exists
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

  // Update the quantity of an item in the cart or remove it if quantity is <= 0
  void updateQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      _items.remove(item);
    } else {
       
      item.quantity = quantity;
    }
    notifyListeners();
  }

  // Remove a specific item from the cart
  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  // Replace the cart with a new list of items
  void replaceItems(List<CartItem> items) {
    _items = items; // Replace the cart's current items
    notifyListeners();  
  }

  // Clear the entire cart
  void clear() {
    _items.clear(); 
    notifyListeners();
  }
}
