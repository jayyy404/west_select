import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteModel extends ChangeNotifier {
  final List<Map<String, String>> _favoriteItems = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currUser = FirebaseAuth.instance.currentUser?.uid;

  List<Map<String, String>> get favoriteItems => _favoriteItems;
  Future<void> fetchFavorites(String userId) async {
    final snapshot = await _firestore.collection('favorites').doc(userId).get();

    if (snapshot.exists) {
      final data = snapshot.data()?['items'] as List<dynamic>? ?? [];
      _favoriteItems
        ..clear()
        ..addAll(data.map((item) => Map<String, String>.from(item)));
      notifyListeners();
    }
  }


  Future<void> addFavorite(String userId, Map<String, String> product) async {
    _favoriteItems.add(product);
    notifyListeners();

    await _updateFavoritesInFirestore(userId);
  }
  Future<void> removeFavorite(String userId, Map<String, String> product) async {
    _favoriteItems.remove(product);
    notifyListeners();

    try {
      await _firestore.collection('favorites').doc(userId).update({
        'items': FieldValue.arrayRemove([product]),
      });
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  Future<void> _updateFavoritesInFirestore(String userId) async {
    await _firestore.collection('favorites').doc(userId).set({
      'items': _favoriteItems,
    });
  }

  void clearFavorites() {
    _favoriteItems.clear();
    notifyListeners();
  }
}
