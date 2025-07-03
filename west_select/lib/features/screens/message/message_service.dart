import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/notification_service.dart';
import '../../../firebase/notification_service.dart' as firebase_notif;

class MessagesService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String makeConversationId(
    String userA,
    String userB, {
    bool isBuying = false,
    String? productName,
  }) {
    final ids = [userA, userB]..sort();
    return isBuying && productName != null
        ? '${ids[0]}_${ids[1]}_buy_${productName.hashCode.abs()}'
        : ids.join('_');
  }

  static Future<String> resolveCurrentConversation({
    required String? otherId,
    bool fromProductPage = false,
    String? productName,
    double? productPrice,
    String? productImage,
    required int activeTabIndex,
    bool fromPendingOrders = false,
  }) async {
    final me = _auth.currentUser?.uid;
    if (me == null || otherId == null) return '';

    //If opened from a product page, create / reuse the buy convo ID
    if (fromProductPage &&
        productName != null &&
        productPrice != null &&
        productImage != null) {
      return makeConversationId(me, otherId,
          isBuying: true, productName: productName);
    }

    // Otherwise search existing conversations between the two users
    final query = await _db
        .collection('conversations')
        .where('participants', arrayContains: me)
        .get();

    final userConvos = query.docs.where((c) {
      final p = List<String>.from(c['participants']);
      return p.contains(otherId);
    }).toList();

    if (userConvos.isEmpty) {
      return makeConversationId(me, otherId);
    }

    // Special case: When coming from pending orders, prioritize buyer conversations
    if (fromPendingOrders) {
      // Look for conversations where current user is the buyer
      for (final doc in userConvos) {
        final data = doc.data();
        if (data['transactionType'] == 'buy' && data['buyerId'] == me) {
          return doc.id;
        }
      }
      // If no buyer conversation found, create a new general conversation
      return makeConversationId(me, otherId);
    }

    // If we have a specific product context, try to find the matching conversation
    if (productName != null) {
      final productConvos = userConvos.where((doc) {
        final data = doc.data();
        return data['productName'] == productName;
      }).toList();

      if (productConvos.isNotEmpty) {
        // Find the conversation that matches our role (buyer/seller)
        for (final doc in productConvos) {
          final data = doc.data();
          if (activeTabIndex == 0) {
            // Buy view – conversation where current user is the buyer
            if (data['transactionType'] == 'buy' && data['buyerId'] == me) {
              return doc.id;
            }
          } else {
            // Sell view - conversation where current user is the seller
            if (data['transactionType'] == 'buy' && data['sellerId'] == me) {
              return doc.id;
            }
          }
        }
        // If no role-specific match, return first product conversation
        return productConvos.first.id;
      }
    }

    // No specific product context, so filter by tab (0 = Buy, 1 = Sell)
    if (userConvos.length > 1) {
      for (final doc in userConvos) {
        final data = doc.data();
        if (activeTabIndex == 0) {
          // Buy view – conversation where current user is the buyer
          if (data['transactionType'] == 'buy' && data['buyerId'] == me) {
            return doc.id;
          }
        } else {
          // Sell view - conversation where current user is the seller
          if (data['transactionType'] == 'buy' && data['sellerId'] == me) {
            return doc.id;
          }
          // Also include general conversations (no transaction type) in sell view
          if (!data.containsKey('transactionType')) return doc.id;
        }
      }
    }

    // Otherwise just use first one
    return userConvos.first.id;
  }

  static Future<bool> isBuyConversation(String convoId) async {
    final me = _auth.currentUser?.uid;
    if (me == null) return true;

    final snap = await _db.collection('conversations').doc(convoId).get();
    if (!snap.exists) return true;

    final d = snap.data() as Map<String, dynamic>;
    if (d.containsKey('transactionType') && d.containsKey('buyerId')) {
      return d['buyerId'] == me;
    }

    // check who sent first message
    final firstMsg = await _db
        .collection('conversations')
        .doc(convoId)
        .collection('messages')
        .orderBy('timestamp')
        .limit(1)
        .get();

    if (firstMsg.docs.isEmpty) return true;

    return firstMsg.docs.first['senderId'] == me;
  }

  static Future<List<DocumentSnapshot>> filterConversations(
    List<DocumentSnapshot> all,
    bool isBuyTab,
  ) async {
    final filtered = <DocumentSnapshot>[];

    for (final doc in all) {
      final isBuy = await isBuyConversation(doc.id);
      if ((isBuyTab && isBuy) || (!isBuyTab && !isBuy)) {
        filtered.add(doc);
      }
    }
    return filtered;
  }

  static Future<void> sendMessage({
    required String convoId,
    required String text,
    String? productName,
    double? productPrice,
    String? productImage,
    String? sellerId,
  }) async {
    final me = _auth.currentUser?.uid;
    if (me == null || text.trim().isEmpty) return;

    final convoRef = _db.collection('conversations').doc(convoId);
    final msgRef = convoRef.collection('messages');

    await msgRef.add({
      'senderId': me,
      'receiverId': sellerId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final meta = {
      'participants': [me, sellerId],
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (productName != null &&
        productPrice != null &&
        productImage != null &&
        sellerId != null) {
      meta.addAll({
        'transactionType': 'buy',
        'buyerId': me,
        'sellerId': sellerId,
        'productName': productName,
        'productPrice': productPrice,
        'productImage': productImage,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await convoRef.set(meta, SetOptions(merge: true));

    // Create notification for the message recipient
    if (sellerId != null && sellerId != me) {
      try {
        // Get sender's name
        final senderDoc = await _db.collection('users').doc(me).get();
        String senderName = 'Someone';
        if (senderDoc.exists) {
          final senderData = senderDoc.data() as Map<String, dynamic>;
          senderName =
              senderData['displayName'] ?? senderData['name'] ?? 'Someone';
        }

        // Create in-app notification
        final notificationService = NotificationService();
        await notificationService.createMessageNotification(
          recipientId: sellerId,
          senderName: senderName,
          productName: productName ?? 'a product',
          conversationId: convoId,
        );

        // Send push notification via Firebase
        await firebase_notif.NotificationService.instance.sendPushNotification(
          recipientUserId: sellerId,
          title: 'New Message',
          body: productName != null
              ? '$senderName sent you a message about $productName'
              : '$senderName sent you a message',
          data: {
            'type': 'message',
            'conversationId': convoId,
            'senderName': senderName,
            'productName': productName ?? '',
          },
        );
      } catch (e) {
        print('Error creating message notification: $e');
      }
    }
  }
}
