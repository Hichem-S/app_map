class AppNotification {
  final String id;
  final String? serverId;
  final String type;
  final String title;
  final String body;
  final String? productId;
  final String? productName;
  final String? fromRoom;
  final String? toRoom;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    this.serverId,
    required this.type,
    required this.title,
    required this.body,
    this.productId,
    this.productName,
    this.fromRoom,
    this.toRoom,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id:          j['id'] as String,
        serverId:    j['id'] as String,
        type:        j['type'] as String? ?? 'product_moved',
        title:       j['title'] as String? ?? 'Notification',
        body:        j['body'] as String? ?? '',
        productId:   j['product_id'] as String?,
        productName: j['product_name'] as String?,
        fromRoom:    j['from_room'] as String?,
        toRoom:      j['to_room'] as String?,
        createdAt:   DateTime.parse(j['created_at'] as String).toLocal(),
        isRead:      j['is_read'] as bool? ?? false,
      );
}
