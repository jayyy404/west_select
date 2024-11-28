import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchService {
  final FirebaseFirestore firestore;

  SearchService(this.firestore);

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> searchProducts(
      String query) async {
    try {
      final result = await firestore
          .collection('post')
          .where('post_title', arrayContains: query.toLowerCase())
          .get();
      return result.docs;
    } catch (e) {
      debugPrint('Error searching products: $e');
      return [];
    }
  }
}
