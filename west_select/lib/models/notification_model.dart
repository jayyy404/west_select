import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Document data is null');
      }

      DateTime createdAt;
      final createdAtData = data['createdAt'];
      if (createdAtData is Timestamp) {
        createdAt = createdAtData.toDate();
      } else {
        createdAt = DateTime.now();
      }

      return NotificationModel(
        id: doc.id,
        userId: data['userId']?.toString() ?? '',
        title: data['title']?.toString() ?? '',
        body: data['body']?.toString() ?? '',
        type: data['type']?.toString() ?? 'general',
        data: Map<String, dynamic>.from(data['data'] ?? {}),
        createdAt: createdAt,
        isRead: data['isRead'] == true,
        imageUrl: data['imageUrl']?.toString(),
      );
    } catch (e) {
      return NotificationModel(
        id: doc.id,
        userId: '',
        title: 'Error loading notification',
        body: 'There was an error loading this notification',
        type: 'error',
        data: {},
        createdAt: DateTime.now(),
        isRead: false,
      );
    }
  }
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Get icon based on notification type
  String get typeIcon {
    switch (type) {
      case 'order':
        return '🛒';
      case 'message':
        return '💬';
      case 'favorite':
        return '❤️';
      case 'price_drop':
        return '🏷️';
      case 'review':
        return '⭐';
      default:
        return '🔔';
    }
  }

  // Get relative time string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
