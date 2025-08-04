import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver getObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  static Future<void> setUserId(String uid) async {
    await _analytics.setUserId(id: uid);
  }

  static Future<void> setUserProperties({
    String? email,
    String? displayName,
    String? userType,
  }) async {
    if (email != null) {
      await _analytics.setUserProperty(name: 'email', value: email);
    }
    if (displayName != null) {
      await _analytics.setUserProperty(
          name: 'display_name', value: displayName);
    }
    if (userType != null) {
      await _analytics.setUserProperty(name: 'user_type', value: userType);
    }
  }

  static Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  static Future<void> logCreateListing({
    required String userId,
    required String productTitle,
    required double price,
  }) async {
    await _analytics.logEvent(
      name: 'create_listing',
      parameters: {
        'user_id': userId,
        'product_title': productTitle,
        'price': price,
      },
    );
  }

  static Future<void> logAddToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
  }) async {
    await _analytics.logAddToCart(
      currency: 'PHP',
      value: price * quantity,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          price: price,
          quantity: quantity,
        )
      ],
    );
  }

  static Future<void> logAddToFavorites({
    required String productId,
    required String productName,
  }) async {
    await _analytics.logEvent(
      name: 'add_to_favorites',
      parameters: {
        'item_id': productId,
        'item_name': productName,
      },
    );
  }

  static Future<void> logBeginCheckout({
    required double total,
    required List<AnalyticsEventItem> items,
  }) async {
    await _analytics.logBeginCheckout(
      currency: 'PHP',
      value: total,
      items: items,
    );
  }

  static Future<void> logPurchase({
    required String orderId,
    required double total,
    required List<AnalyticsEventItem> items,
  }) async {
    await _analytics.logPurchase(
      currency: 'PHP',
      value: total,
      transactionId: orderId,
      items: items,
    );
  }

  static Future<void> logMessageSent({
    required String senderId,
    required String receiverId,
    required int messageLength,
  }) async {
    await _analytics.logEvent(
      name: 'send_message',
      parameters: {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message_length': messageLength,
      },
    );
  }

  static Future<void> logMessageReceived({
    required String senderId,
    required String receiverId,
    required int messageLength,
  }) async {
    await _analytics.logEvent(
      name: 'receive_message',
      parameters: {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message_length': messageLength,
      },
    );
  }

  static Future<void> logOrderCompleted({
    required String orderId,
    required String sellerId,
    required double total,
    required List<AnalyticsEventItem> items,
  }) async {
    await _analytics.logEvent(
      name: 'order_completed',
      parameters: {
        'order_id': orderId,
        'seller_id': sellerId,
        'total': total,
        'items_count': items.length,
      },
    );
  }

  static Future<void> logProductView({
    required String productId,
    required String productName,
    required double price,
    required String category,
    required String sellerId,
  }) async {
    await _analytics.logViewItem(
      currency: 'PHP',
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          itemCategory: category,
        )
      ],
    );
  }

  static Future<void> logSearch({
    required String searchTerm,
    required int resultsCount,
  }) async {
    await _analytics.logSearch(
      searchTerm: searchTerm,
      numberOfNights: resultsCount,
    );
  }
}
