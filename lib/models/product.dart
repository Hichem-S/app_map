const _sentinel = Object();

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
  final String? qrImageUrl;
  final String status;
  final Map<String, dynamic> specifications;
  final String? department;
  final String? classroom;
  // New structured location fields (from rooms/departments JOIN)
  final String? roomId;
  final String? roomName;
  final String? departmentId;
  final String? departmentCode;
  final String? departmentName;
  final String? departmentColor;
  final String? rfidTag;
  final String? bleDevice;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;
  final DateTime? endOfLifeDate;
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
    this.qrImageUrl,
    this.status = 'in_stock',
    this.specifications = const {},
    this.department,
    this.classroom,
    this.roomId,
    this.roomName,
    this.departmentId,
    this.departmentCode,
    this.departmentName,
    this.departmentColor,
    this.rfidTag,
    this.bleDevice,
    this.purchaseDate,
    this.warrantyExpiry,
    this.endOfLifeDate,
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
      qrImageUrl: json['qr_image_url'],
      status: json['status'] ?? 'in_stock',
      department: json['department'],
      classroom: json['classroom'],
      roomId:          json['room_id'],
      roomName:        json['room_name'],
      departmentId:    json['department_id'],
      departmentCode:  json['department_code'],
      departmentName:  json['department_name'],
      departmentColor: json['department_color'],
      rfidTag:         json['rfid_tag'],
      bleDevice:       json['ble_device'],
      purchaseDate:    json['purchase_date']    != null ? DateTime.tryParse(json['purchase_date'])    : null,
      warrantyExpiry:  json['warranty_expiry']  != null ? DateTime.tryParse(json['warranty_expiry'])  : null,
      endOfLifeDate:   json['end_of_life_date'] != null ? DateTime.tryParse(json['end_of_life_date']) : null,
      specifications: json['specifications'] is Map
          ? Map<String, dynamic>.from(json['specifications'] as Map)
          : const {},
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? type,
    String? categoryName,
    String? barcode,
    String? description,
    List<String>? tags,
    int? quantity,
    double? price,
    String? storageLocation,
    String? photoUrl,
    String? qrData,
    String? qrImageUrl,
    String? status,
    Map<String, dynamic>? specifications,
    Object? department = _sentinel,
    Object? classroom = _sentinel,
    Object? roomId = _sentinel,
    Object? roomName = _sentinel,
    Object? departmentId = _sentinel,
    Object? departmentCode = _sentinel,
    Object? departmentName = _sentinel,
    Object? departmentColor = _sentinel,
    Object? rfidTag = _sentinel,
    Object? bleDevice = _sentinel,
    Object? purchaseDate = _sentinel,
    Object? warrantyExpiry = _sentinel,
    Object? endOfLifeDate = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      type: type ?? this.type,
      categoryName: categoryName ?? this.categoryName,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      storageLocation: storageLocation ?? this.storageLocation,
      photoUrl: photoUrl ?? this.photoUrl,
      qrData: qrData ?? this.qrData,
      qrImageUrl: qrImageUrl ?? this.qrImageUrl,
      status: status ?? this.status,
      specifications: specifications ?? this.specifications,
      department:      department      == _sentinel ? this.department      : department      as String?,
      classroom:       classroom       == _sentinel ? this.classroom       : classroom       as String?,
      roomId:          roomId          == _sentinel ? this.roomId          : roomId          as String?,
      roomName:        roomName        == _sentinel ? this.roomName        : roomName        as String?,
      departmentId:    departmentId    == _sentinel ? this.departmentId    : departmentId    as String?,
      departmentCode:  departmentCode  == _sentinel ? this.departmentCode  : departmentCode  as String?,
      departmentName:  departmentName  == _sentinel ? this.departmentName  : departmentName  as String?,
      departmentColor: departmentColor == _sentinel ? this.departmentColor : departmentColor as String?,
      rfidTag:         rfidTag         == _sentinel ? this.rfidTag         : rfidTag         as String?,
      bleDevice:       bleDevice       == _sentinel ? this.bleDevice       : bleDevice       as String?,
      purchaseDate:    purchaseDate    == _sentinel ? this.purchaseDate    : purchaseDate    as DateTime?,
      warrantyExpiry:  warrantyExpiry  == _sentinel ? this.warrantyExpiry  : warrantyExpiry  as DateTime?,
      endOfLifeDate:   endOfLifeDate   == _sentinel ? this.endOfLifeDate   : endOfLifeDate   as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
