import 'package:cc206_west_select/features/screens/productdetails/product_widgets/bottom_bar.dart';
import 'package:cc206_west_select/features/screens/productdetails/product_widgets/detail_card.dart';
import 'package:cc206_west_select/features/screens/productdetails/product_widgets/image_gallery.dart';
import 'package:cc206_west_select/features/screens/productdetails/product_widgets/info_header.dart';
import 'package:cc206_west_select/features/screens/productdetails/product_widgets/models.dart';
import 'package:cc206_west_select/features/screens/productdetails/product_widgets/reviews_section.dart';
import 'package:cc206_west_select/features/screens/productdetails/product_widgets/seller_block.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../favorite/favorite_model.dart';
import '../cart/shopping_cart.dart';
import '../message/message_page.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.productId});
  final String productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _favBusy = ValueNotifier(false);

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  Product? _product;
  bool _isFav = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final postSnap = await FirebaseFirestore.instance
        .collection('post')
        .doc(widget.productId)
        .get();
    if (!postSnap.exists) return;
    final data = postSnap.data()!;
    final sellerId = data['post_users'];
    final sellerSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(sellerId)
        .get();
    final sellerName = sellerSnap.data()?['displayName'] ?? 'Unknown';

    _product = Product.fromMap({...data, 'sellerName': sellerName});
    await _checkFav();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkFav() async {
    if (_uid == null) return;
    final favSnap = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(_uid)
        .get();
    final items = favSnap.data()?['items'] ?? [];
    _isFav = items.any((it) => it['id'] == widget.productId);
  }

  void _toggleFav() async {
    if (_uid == null || _product == null) return;
    final fav = Provider.of<FavoriteModel>(context, listen: false);
    final map = {
      'id': widget.productId,
      'title': _product!.productTitle,
      'imageUrls': _product!.imageUrls.join(','),
      'price': _product!.price.toString(),
      'seller': _product!.sellerName,
    };
    _favBusy.value = true;
    if (_isFav) {
      await fav.removeFavorite(_uid, map);
    } else {
      await fav.addFavorite(_uid, map);
    }
    _isFav = !_isFav;
    _favBusy.value = false;
  }

  void _msg() {
    if (_uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to send messages')));
      return;
    }
    if (_uid == _product!.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot message yourself')));
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MessagePage(
                  receiverId: _product!.userId,
                  userName: _product!.sellerName,
                  productName: _product!.productTitle,
                  productPrice: _product!.price,
                  productImage: _product!.imageUrls.first,
                )));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context)),
            actions: [
              ValueListenableBuilder(
                  valueListenable: _favBusy,
                  builder: (_, busy, __) => busy
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: Icon(
                              _isFav ? Icons.favorite : Icons.favorite_border,
                              color: _isFav ? Colors.red : Colors.black),
                          onPressed: _toggleFav)),
              IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined,
                      color: Colors.black),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ShoppingCartPage()))),
            ]),
        body: _loading || _product == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // gallery
                    SizedBox(
                        height: 300,
                        child: ImageGallery(images: _product!.imageUrls)),
                    const SizedBox(height: 16),
                    // info
                    InfoHeader(
                        title: _product!.productTitle, price: _product!.price),
                    const SizedBox(height: 20),
                    // details
                    FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('post')
                            .doc(widget.productId)
                            .get(),
                        builder: (_, s) => !s.hasData
                            ? const SizedBox.shrink()
                            : DetailCard(
                                map: s.data!.data() as Map<String, dynamic>)),
                    const SizedBox(height: 20),
                    // description
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Description',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(_product!.description,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.5))
                            ])),
                    const SizedBox(height: 20),
                    // pickup location
                    FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('post')
                            .doc(widget.productId)
                            .get(),
                        builder: (_, s) {
                          if (!s.hasData) return const SizedBox.shrink();
                          final loc = (s.data!.data()
                              as Map<String, dynamic>)['location'];
                          return loc == null || '$loc'.isEmpty
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Pickup Location',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text('$loc',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                        const SizedBox(height: 20)
                                      ]));
                        }),
                    // seller row
                    SellerBlock(
                        sellerId: _product!.userId,
                        sellerName: _product!.sellerName,
                        onMsgTap: _msg),
                    const SizedBox(height: 20),
                    // reviews
                    ReviewsSection(
                      postId: widget.productId,
                      ownerId: _product!.userId,
                      productTitle: _product!.productTitle,
                      productPrice: _product!.price,
                      productImage: _product!.imageUrls.first,
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
        bottomNavigationBar: _product == null
            ? null
            : BottomBar(
                productId: widget.productId,
                title: _product!.productTitle,
                price: _product!.price,
                image: _product!.imageUrls.first,
                ownerId: _product!.userId,
              ),
      );
}
