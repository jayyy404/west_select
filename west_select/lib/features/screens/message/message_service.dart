import 'package:cc206_west_select/features/screens/message/message_encryption.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/notification_service.dart';
import '../../../firebase/notification_service.dart' as firebase_notif;

class MessagesService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _encryptionService = MessageEncryptionService();

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

  /// Encrypts a message for storage
  static String _encryptMessage({
    required String plaintext,
    required String conversationId,
    required String senderId,
    required String receiverId,
  }) {
    return _encryptionService.encryptMessage(
      plaintext: plaintext,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
    );
  }

  /// Decrypts a message for display
  static String decryptMessage({
    required String encryptedText,
    required String conversationId,
    required String senderId,
    required String receiverId,
  }) {
    return _encryptionService.decryptMessage(
      encryptedText: encryptedText,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
    );
  }

  /// Checks if a message is encrypted
  static bool isMessageEncrypted(String text) {
    return _encryptionService.isEncrypted(text);
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

    if (sellerId == null || sellerId.isEmpty) {
      throw Exception('Receiver ID is required for message encryption');
    }

    try {
      final convoRef = _db.collection('conversations').doc(convoId);
      final msgRef = convoRef.collection('messages');

      // Encrypt the message before storing
      final encryptedText = _encryptMessage(
        plaintext: text.trim(),
        conversationId: convoId,
        senderId: me,
        receiverId: sellerId,
      );

      // Store encrypted message in messages subcollection
      await msgRef.add({
        'senderId': me,
        'receiverId': sellerId,
        'text': encryptedText,
        'timestamp': FieldValue.serverTimestamp(),
      });
      final meta = {
        'participants': [me, sellerId],
        'lastMessage': _encryptMessage(
            plaintext: text.trim(),
            conversationId: convoId,
            senderId: me,
            receiverId: sellerId),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (productName != null &&
          productPrice != null &&
          productImage != null &&
          sellerId.isNotEmpty) {
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
      if (sellerId != me) {
        try {
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
          await firebase_notif.NotificationService.instance
              .sendPushNotification(
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
        } catch (e) {}
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Migrates existing unencrypted messages to encrypted format
  static Future<void> migrateExistingMessages() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get all conversations for current user
      final conversationsQuery = await _db
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .get();

      int totalConversations = conversationsQuery.docs.length;
      int processedConversations = 0;
      int totalMessages = 0;
      int encryptedMessages = 0;

      for (final convoDoc in conversationsQuery.docs) {
        final conversationId = convoDoc.id;
        final convoData = convoDoc.data();
        final participants = List<String>.from(convoData['participants'] ?? []);

        if (participants.length < 2) {
          continue;
        }

        final otherId = participants.firstWhere((id) => id != currentUserId);

        // Get all messages in this conversation
        final messagesQuery = await _db
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .get();

        if (messagesQuery.docs.isEmpty) {
          processedConversations++;
          continue;
        }

        final batch = _db.batch();
        bool hasBatchUpdates = false;

        for (final messageDoc in messagesQuery.docs) {
          final messageData = messageDoc.data();
          final text = messageData['text'] as String?;
          final senderId = messageData['senderId'] as String?;

          totalMessages++;

          if (text != null && senderId != null) {
            // Check if message is already encrypted
            if (!_encryptionService.isEncrypted(text)) {
              try {
                // Encrypt the message
                final encryptedText = _encryptionService.encryptMessage(
                  plaintext: text,
                  conversationId: conversationId,
                  senderId: senderId,
                  receiverId:
                      senderId == currentUserId ? otherId : currentUserId,
                );

                // Update the message
                batch.update(messageDoc.reference, {'text': encryptedText});
                hasBatchUpdates = true;
                encryptedMessages++;
              } catch (e) {}
            }
          }
        }

        // Commit batch if there are updates
        if (hasBatchUpdates) {
          try {
            await batch.commit();
          } catch (e) {}
        }

        processedConversations++;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Helper method to get conversation participants
  static Future<List<String>> getConversationParticipants(
      String conversationId) async {
    try {
      final convoDoc =
          await _db.collection('conversations').doc(conversationId).get();
      if (!convoDoc.exists) return [];

      final data = convoDoc.data() as Map<String, dynamic>?;
      return List<String>.from(data?['participants'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Test encryption/decryption functionality
  static Future<bool> testEncryption() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      const testMessage = 'This is a test message for encryption';
      const testConversationId = 'test_conversation';
      const testReceiverId = 'test_receiver';

      // Test encryption
      final encrypted = _encryptionService.encryptMessage(
        plaintext: testMessage,
        conversationId: testConversationId,
        senderId: currentUserId,
        receiverId: testReceiverId,
      );

      // Test decryption
      final decrypted = _encryptionService.decryptMessage(
        encryptedText: encrypted,
        conversationId: testConversationId,
        senderId: currentUserId,
        receiverId: testReceiverId,
      );

      final success = decrypted == testMessage;
      if (!success) {}

      return success;
    } catch (e) {
      return false;
    }
  }
}
