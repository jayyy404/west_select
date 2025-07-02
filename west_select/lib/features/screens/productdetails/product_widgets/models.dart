class Product {
  const Product({
    required this.imageUrls,
    required this.productTitle,
    required this.description,
    required this.price,
    required this.sellerName,
    required this.userId,
  });

  final List<String> imageUrls;
  final String productTitle;
  final String description;
  final double price;
  final String sellerName;
  final String userId;

  factory Product.fromMap(Map<String, dynamic> data) => Product(
        imageUrls: List<String>.from(data['image_urls'] ?? []),
        productTitle: data['post_title'] ?? '',
        description: data['post_description'] ?? '',
        price: (data['price'] ?? 0).toDouble(),
        userId: data['post_users'] ?? '',
        sellerName: data['sellerName'] ?? '',
      );
}
