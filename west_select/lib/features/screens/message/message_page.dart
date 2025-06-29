import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MessagePage extends StatefulWidget {
  final String? receiverId;
  final String? userName;
  final String? productName;
  final double? productPrice;
  final String? productImage;

  const MessagePage({
    super.key,
    this.receiverId,
    this.userName,
    this.productName,
    this.productPrice,
    this.productImage,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final _msgCtrl = TextEditingController();
  final _listCtrl = ScrollController();
  final _me = FirebaseAuth.instance.currentUser?.uid;

  String? _selectedId;
  String? _selectedName;
  bool _isExternalSelection = false;

  String? get _productName => widget.productName;
  double? get _productPrice => widget.productPrice;
  String? get _productImage => widget.productImage;

  @override
  void initState() {
    super.initState();
    if (widget.receiverId != null && widget.userName != null) {
      _selectedId = widget.receiverId;
      _selectedName = widget.userName;
      _isExternalSelection = true;
    }
  }

  void _checkForReset() {
    if (widget.receiverId == null && _isExternalSelection) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedId = null;
          _selectedName = null;
          _isExternalSelection = false;
        });
      });
    }
  }

  String get _conversationId {
    if (_me == null || _selectedId == null) return '';
    final ids = [_me, _selectedId!]..sort();
    return ids.join('_');
  }

  String _fmt(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  Future<void> _send() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty || _me == null || _selectedId == null) return;

    final convo = FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId);
    final msgsCol = convo.collection('messages');

    await msgsCol.add({
      'senderId': _me,
      'receiverId': _selectedId,
      'text': txt,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await convo.set({
      'participants': [_me, _selectedId],
      'lastMessage': txt,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _msgCtrl.clear();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_listCtrl.hasClients) {
        _listCtrl.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Widget _buildProductBar() {
    if (_productName == null ||
        _productPrice == null ||
        _productImage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(_productImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _productName!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PHP ${NumberFormat('#,##0.00', 'en_US').format(_productPrice!)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Add to Cart Button
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $_productName to cart')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5191DB),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Add to cart',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conversationList() {
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
        final convos = snap.data!.docs;
        if (convos.isEmpty) {
          return const Center(child: Text('No messages yet.'));
        }

        return ListView.builder(
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
                final uData =
                    (uSnap.data?.data() as Map<String, dynamic>?) ?? {};

                final name = uData['displayName'] ?? 'User';

                final String? photoUrl =
                    (uData['profilePictureUrl'] as String?)?.trim();

                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  title: Text(name),
                  subtitle: Text(last),
                  trailing: ts != null
                      ? Text(_fmt(ts.toDate()),
                          style: const TextStyle(fontSize: 12))
                      : null,
                  onTap: () => setState(() {
                    _selectedId = other;
                    _selectedName = name;
                    _isExternalSelection = false;
                  }),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _chatView() {
    final query = FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true);

    return Column(
      children: [
        // Product bar at the top
        _buildProductBar(),

        // Chat messages
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final msgs = snap.data!.docs;
              return ListView.builder(
                controller: _listCtrl,
                reverse: true,
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[i].data() as Map<String, dynamic>;
                  final me = m['senderId'] == _me;
                  final ts = m['timestamp'] as Timestamp?;
                  return Align(
                    alignment:
                        me ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: me ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['text'] ?? '',
                              style: TextStyle(
                                  color: me ? Colors.white : Colors.black)),
                          if (ts != null)
                            Text(_fmt(ts.toDate()),
                                style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        me ? Colors.white70 : Colors.black54)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Message input
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _checkForReset();
    final inChat = _selectedId != null && _selectedName != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(inChat ? _selectedName! : 'Messages'),
        leading: inChat
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedId = null;
                  _selectedName = null;
                  _isExternalSelection = false;
                }),
              )
            : null,
      ),
      body: inChat ? _chatView() : _conversationList(),
    );
  }
}
