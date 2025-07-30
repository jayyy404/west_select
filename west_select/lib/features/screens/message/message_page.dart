import 'package:cc206_west_select/features/screens/message/chat_header.dart';
import 'package:cc206_west_select/features/screens/message/message_bubble.dart';
import 'package:cc206_west_select/features/screens/message/message_service.dart';
import 'package:cc206_west_select/features/screens/message/time_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MessagePage extends StatefulWidget {
  final String? receiverId;
  final String? userName;
  final String? productName;
  final double? productPrice;
  final String? productImage;
  final bool fromPendingOrders;

  const MessagePage({
    super.key,
    this.receiverId,
    this.userName,
    this.productName,
    this.productPrice,
    this.productImage,
    this.fromPendingOrders = false,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _listCtrl = ScrollController();
  final _me = FirebaseAuth.instance.currentUser?.uid;

  String? _selectedId;
  String? _selectedName;
  bool _openedFromProduct = false;

  String? _selectedProductName;
  double? _selectedProductPrice;
  String? _selectedProductImage;

  late TabController _tab;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _tabIndex = _tab.index));

    // Force Buy tab (index 0) when coming from pending orders
    if (widget.fromPendingOrders) {
      _tabIndex = 0;
      _tab.index = 0;
    }

    // external open
    if (widget.receiverId != null && widget.userName != null) {
      _selectedId = widget.receiverId;
      _selectedName = widget.userName;
      _openedFromProduct = true;
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  void _resetIfNeeded() {
    if (widget.receiverId == null && _openedFromProduct) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedId = null;
          _selectedName = null;
          _openedFromProduct = false;
          _selectedProductName = null;
          _selectedProductPrice = null;
          _selectedProductImage = null;
        });
      });
    }
  }

  Widget _conversationList() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: const Color(0xFF5191DB),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF5191DB),
            tabs: const [
              Tab(text: 'Buy'),
              Tab(text: 'Sell'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _conversationTab(isBuyTab: true),
              _conversationTab(isBuyTab: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _conversationTab({required bool isBuyTab}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: _me)
          .orderBy('lastUpdated', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snap.data!.docs;
        if (all.isEmpty) {
          return _emptyState(isBuyTab);
        }

        return FutureBuilder<List<DocumentSnapshot>>(
          future: MessagesService.filterConversations(all, isBuyTab),
          builder: (_, filterSnap) {
            if (!filterSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final convos = filterSnap.data!;
            if (convos.isEmpty) return _emptyState(isBuyTab);

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: convos.length,
              itemBuilder: (_, i) {
                final data = convos[i].data() as Map<String, dynamic>;
                final other = (List<String>.from(data['participants']))
                    .firstWhere((id) => id != _me);
                final last = data['lastMessage'] ?? '';
                final ts = data['lastUpdated'] as Timestamp?;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(other)
                      .get(),
                  builder: (_, uSnap) {
                    final user =
                        (uSnap.data?.data() as Map<String, dynamic>?) ?? {};
                    final name = user['displayName'] ?? 'User';
                    final photo =
                        (user['profilePictureUrl'] as String?)?.trim();

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: (photo != null && photo.isNotEmpty)
                              ? NetworkImage(photo)
                              : null,
                          child: (photo == null || photo.isEmpty)
                              ? Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['productName'] != null)
                              Text(
                                'Product: ${data['productName']}',
                                style: TextStyle(
                                    color: Colors.blue[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            Text(
                              MessagesService.isMessageEncrypted(last)
                                  ? MessagesService.decryptMessage(
                                      encryptedText: last,
                                      conversationId: convos[i].id,
                                      senderId:
                                          data['lastMessageSenderId'] ?? _me,
                                      receiverId: other,
                                    )
                                  : last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                        trailing: ts != null
                            ? Text(
                                TimeUtils.formatListTime(ts.toDate()),
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              )
                            : null,
                        onTap: () => setState(() {
                          _selectedId = other;
                          _selectedName = name;
                          _openedFromProduct = false;

                          // Store the conversation's product information
                          _selectedProductName = data['productName'] as String?;
                          _selectedProductPrice = (data['productPrice'] is int)
                              ? (data['productPrice'] as int).toDouble()
                              : data['productPrice'] as double?;
                          _selectedProductImage =
                              data['productImage'] as String?;
                        }),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _emptyState(bool isBuy) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isBuy
                    ? Icons.shopping_cart_outlined
                    : Icons.storefront_outlined,
                size: 64,
                color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
                isBuy
                    ? 'No buying conversations yet.'
                    : 'No selling conversations yet.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );

  Widget _chatView() {
    final productName =
        _openedFromProduct ? widget.productName : _selectedProductName;
    final productPrice =
        _openedFromProduct ? widget.productPrice : _selectedProductPrice;
    final productImage =
        _openedFromProduct ? widget.productImage : _selectedProductImage;

    return FutureBuilder<String>(
      future: MessagesService.resolveCurrentConversation(
        otherId: _selectedId,
        fromProductPage: _openedFromProduct,
        productName: productName,
        productPrice: productPrice,
        productImage: productImage,
        activeTabIndex: _tabIndex,
        fromPendingOrders: widget.fromPendingOrders,
      ),
      builder: (_, idSnap) {
        if (!idSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final convoId = idSnap.data!;
        final messagesQuery = FirebaseFirestore.instance
            .collection('conversations')
            .doc(convoId)
            .collection('messages')
            .orderBy('timestamp', descending: true);

        return Column(
          children: [
            ChatHeader(
              conversationId: convoId,
              explicitProductName: productName,
              explicitProductPrice: productPrice,
              explicitProductImage: productImage,
              peerName: _selectedName,
              explicitIsBuying: true,
            ),
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: StreamBuilder<QuerySnapshot>(
                  stream: messagesQuery.snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final msgs = snap.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      controller: _listCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) {
                        final m = msgs[i];
                        final isMe = m['senderId'] == _me;
                        return MessageBubble(
                          isMe: isMe,
                          text: m['text'],
                          timestamp: m['timestamp'] as Timestamp?,
                          conversationId: convoId,
                          otherUserId: _selectedId,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            _inputBar(convoId),
          ],
        );
      },
    );
  }

  Widget _inputBar(String convoId) => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Write a message...',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _handleSend(convoId),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: const BoxDecoration(
                    color: Color(0xFF5191DB), shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.send, size: 20, color: Colors.white),
                  onPressed: () => _handleSend(convoId),
                ),
              ),
            ],
          ),
        ),
      );

  void _handleSend(String convoId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final productName = _openedFromProduct ? widget.productName : _selectedProductName;
    final productPrice = _openedFromProduct ? widget.productPrice : _selectedProductPrice;
    final productImage = _openedFromProduct ? widget.productImage : _selectedProductImage;

    setState(() {
      _msgCtrl.clear();
    });

    try {
      await MessagesService.sendMessage(
        convoId: convoId,
        text: text,
        sellerId: _selectedId ?? '',
        productName: productName ?? '',
        productPrice: productPrice ?? 0.0,
        productImage: productImage ?? '',
      );
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // keep scrolling to bottom
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_listCtrl.hasClients) {
        _listCtrl.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    _resetIfNeeded();
    final inChat = _selectedId != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: inChat
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => setState(() {
                  _selectedId = null;
                  _selectedName = null;
                  _selectedProductName = null;
                  _selectedProductPrice = null;
                  _selectedProductImage = null;
                }),
              )
            : null,
        title: Text(
          inChat ? _selectedName ?? '' : 'Messages',
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: inChat ? _chatView() : _conversationList(),
    );
  }
}
