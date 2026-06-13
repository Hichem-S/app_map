import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inventory/models/app_notification.dart';

void main() {
  Map<String, dynamic> baseJson() => {
        'id': 'notif-001',
        'type': 'product_moved',
        'title': 'Item Moved',
        'body': 'Dell Laptop moved from Lab 1 to Lab 2',
        'product_id': 'p-001',
        'product_name': 'Dell Laptop',
        'from_room': 'Lab GI 1',
        'to_room': 'Lab GI 2',
        'created_at': '2024-06-01T10:00:00.000Z',
        'is_read': false,
      };

  group('AppNotification.fromJson', () {
    test('parses all fields correctly', () {
      final n = AppNotification.fromJson(baseJson());

      expect(n.id, 'notif-001');
      expect(n.serverId, 'notif-001');
      expect(n.type, 'product_moved');
      expect(n.title, 'Item Moved');
      expect(n.body, 'Dell Laptop moved from Lab 1 to Lab 2');
      expect(n.productId, 'p-001');
      expect(n.productName, 'Dell Laptop');
      expect(n.fromRoom, 'Lab GI 1');
      expect(n.toRoom, 'Lab GI 2');
      expect(n.isRead, isFalse);
    });

    test('parses createdAt date correctly', () {
      final n = AppNotification.fromJson(baseJson());
      expect(n.createdAt.year, 2024);
      expect(n.createdAt.month, 6);
      expect(n.createdAt.day, 1);
    });

    test('defaults type to product_moved when missing', () {
      final json = baseJson()..remove('type');
      final n = AppNotification.fromJson(json);
      expect(n.type, 'product_moved');
    });

    test('defaults title when missing', () {
      final json = baseJson()..remove('title');
      final n = AppNotification.fromJson(json);
      expect(n.title, 'Notification');
    });

    test('defaults body to empty string when missing', () {
      final json = baseJson()..remove('body');
      final n = AppNotification.fromJson(json);
      expect(n.body, '');
    });

    test('defaults isRead to false when missing', () {
      final json = baseJson()..remove('is_read');
      final n = AppNotification.fromJson(json);
      expect(n.isRead, isFalse);
    });

    test('parses isRead as true', () {
      final json = baseJson()..['is_read'] = true;
      final n = AppNotification.fromJson(json);
      expect(n.isRead, isTrue);
    });

    test('handles null optional location fields', () {
      final json = baseJson()
        ..['from_room'] = null
        ..['to_room'] = null
        ..['product_id'] = null
        ..['product_name'] = null;
      final n = AppNotification.fromJson(json);

      expect(n.fromRoom, isNull);
      expect(n.toRoom, isNull);
      expect(n.productId, isNull);
      expect(n.productName, isNull);
    });

    test('isRead is mutable', () {
      final n = AppNotification.fromJson(baseJson());
      expect(n.isRead, isFalse);
      n.isRead = true;
      expect(n.isRead, isTrue);
    });

    test('throws on invalid createdAt format', () {
      final json = baseJson()..['created_at'] = 'not-a-date';
      expect(() => AppNotification.fromJson(json), throwsA(isA<FormatException>()));
    });
  });
}
