import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error creating notification: $e');
      }
    }
  }

  // Get notifications for a specific user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    if (userId.isEmpty) {
      if (kDebugMode) {
        print('Warning: userId is empty in getUserNotifications');
      }
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to prevent excessive data loading
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) {
              try {
                return NotificationModel.fromFirestore(doc);
              } catch (e) {
                if (kDebugMode) {
                  print('Error parsing notification document ${doc.id}: $e');
                }
                return null;
              }
            })
            .where((notification) => notification != null)
            .cast<NotificationModel>()
            .toList();
      } catch (e) {
        if (kDebugMode) {
          print('Error processing notifications snapshot: $e');
        }
        return <NotificationModel>[];
      }
    }).handleError((error) {
      if (kDebugMode) {
        print('Error in getUserNotifications stream: $error');
      }
    });
  }

  Stream<List<NotificationModel>> getUserNotificationsSimple(String userId) {
    if (userId.isEmpty) {
      if (kDebugMode) {
        print('Warning: userId is empty in getUserNotificationsSimple');
      }
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .limit(10) // Small limit for testing
        .snapshots()
        .map((snapshot) {
      try {
        if (kDebugMode) {
          print('Received ${snapshot.docs.length} notification documents');
        }

        return snapshot.docs
            .map((doc) {
              try {
                if (kDebugMode) {
                  print('Processing document ${doc.id}: ${doc.data()}');
                }
                return NotificationModel.fromFirestore(doc);
              } catch (e) {
                if (kDebugMode) {
                  print('Error parsing notification document ${doc.id}: $e');
                }
                return null;
              }
            })
            .where((notification) => notification != null)
            .cast<NotificationModel>()
            .toList();
      } catch (e) {
        if (kDebugMode) {
          print('Error processing notifications snapshot: $e');
        }
        return <NotificationModel>[];
      }
    }).handleError((error) {
      if (kDebugMode) {
        print('Error in getUserNotificationsSimple stream: $error');
      }
    });
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all notifications: $e');
      }
    }
  }

  // Get unread notification count
  Stream<int> getUnreadCount(String userId) {
    if (userId.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.length;
      } catch (e) {
        if (kDebugMode) {
          print('Error getting unread count: $e');
        }
        return 0;
      }
    }).handleError((error) {
      if (kDebugMode) {
        print('Error in getUnreadCount stream: $error');
      }
    });
  }

  Future<void> createOrderNotification({
    required String sellerId,
    required String productName,
    required String buyerName,
    String? productId,
  }) async {
    await createNotification(
      userId: sellerId,
      title: 'New Order Received!',
      body: '$buyerName purchased your $productName',
      type: 'order',
      data: {
        'productId': productId,
        'buyerName': buyerName,
      },
    );
  }

  Future<void> createMessageNotification({
    required String recipientId,
    required String senderName,
    required String productName,
    String? conversationId,
  }) async {
    await createNotification(
      userId: recipientId,
      title: 'New Message',
      body: '$senderName sent you a message about $productName',
      type: 'message',
      data: {
        'conversationId': conversationId,
        'senderName': senderName,
      },
    );
  }

  Future<void> createReviewNotification({
    required String sellerId,
    required String productName,
    required int rating,
    String? productId,
  }) async {
    await createNotification(
      userId: sellerId,
      title: 'New Review',
      body: 'Your $productName received a $rating-star review',
      type: 'review',
      data: {
        'productId': productId,
        'rating': rating,
      },
    );
  }

  Future<void> createTestNotification(String userId) async {
    if (userId.isEmpty) {
      if (kDebugMode) {
        print('Cannot create test notification: userId is empty');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('Creating test notification for user: $userId');
      }

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Test Notification',
        'body': 'This is a test notification to verify the system is working',
        'type': 'test',
        'data': {},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'imageUrl': null,
      });

      if (kDebugMode) {
        print('Test notification created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating test notification: $e');
      }
    }
  }
}
