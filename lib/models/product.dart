class Product {
  final String id;
  final String name;
  final String sku;
  final String? type;
  final String? categoryName;
  final String? barcode;
  final String? description;
  final List<String> tags;
  final int quantity;
  final double? price;
  final String? storageLocation;
  final String? photoUrl;
  final String? qrData;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.type,
    this.categoryName,
    this.barcode,
    this.description,
    this.tags = const [],
    this.quantity = 0,
    this.price,
    this.storageLocation,
    this.photoUrl,
    this.qrData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    List<String> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString()).toList();
    }

    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      type: json['category_id'] ?? json['type'],
      categoryName: json['category_name'],
      barcode: json['barcode'],
      description: json['description'],
      tags: parsedTags,
      quantity: json['quantity'] ?? 0,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      storageLocation: json['storage_location'],
      photoUrl: json['photo_url'],
      qrData: json['qr_data'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sku': sku,
        if (type != null) 'type': type,
        'barcode': barcode,
        'description': description,
        'tags': tags,
        'quantity': quantity,
        'price': price,
        'storage_location': storageLocation,
      };
}
