import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inventory/models/product.dart';

void main() {
  // ── helpers ────────────────────────────────────────────────────────────────
  Map<String, dynamic> baseJson() => {
        'id': 'p-001',
        'name': 'Dell Laptop',
        'sku': 'ISET-PC-20240101-001',
        'category_name': 'Computer',
        'barcode': '123456789',
        'description': 'Core i7 laptop',
        'tags': ['laptop', 'portable'],
        'quantity': 5,
        'price': '1200.00',
        'storage_location': 'Lab 1',
        'status': 'in_stock',
        'department': 'Informatique',
        'classroom': 'Lab GI 1',
        'room_id': 'r-001',
        'room_name': 'Lab GI 1',
        'department_id': 'd-001',
        'department_code': 'I',
        'department_name': 'Informatique',
        'department_color': '#4F46E5',
        'rfid_tag': 'RFID-ABC',
        'ble_device': 'BLE-XYZ',
        'purchase_date': '2023-01-15T00:00:00.000Z',
        'warranty_expiry': '2026-01-15T00:00:00.000Z',
        'end_of_life_date': '2028-01-15T00:00:00.000Z',
        'specifications': {'ram': '16GB', 'cpu': 'i7'},
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

  group('Product.fromJson', () {
    test('parses all standard fields correctly', () {
      final p = Product.fromJson(baseJson());

      expect(p.id, 'p-001');
      expect(p.name, 'Dell Laptop');
      expect(p.sku, 'ISET-PC-20240101-001');
      expect(p.categoryName, 'Computer');
      expect(p.barcode, '123456789');
      expect(p.quantity, 5);
      expect(p.price, 1200.0);
      expect(p.status, 'in_stock');
      expect(p.tags, ['laptop', 'portable']);
    });

    test('parses location hierarchy fields', () {
      final p = Product.fromJson(baseJson());

      expect(p.roomId, 'r-001');
      expect(p.roomName, 'Lab GI 1');
      expect(p.departmentId, 'd-001');
      expect(p.departmentCode, 'I');
      expect(p.departmentName, 'Informatique');
      expect(p.departmentColor, '#4F46E5');
    });

    test('parses IoT tag fields', () {
      final p = Product.fromJson(baseJson());

      expect(p.rfidTag, 'RFID-ABC');
      expect(p.bleDevice, 'BLE-XYZ');
    });

    test('parses date fields', () {
      final p = Product.fromJson(baseJson());

      expect(p.purchaseDate, isNotNull);
      expect(p.warrantyExpiry, isNotNull);
      expect(p.endOfLifeDate, isNotNull);
      expect(p.purchaseDate!.year, 2023);
      expect(p.warrantyExpiry!.year, 2026);
    });

    test('parses specifications map', () {
      final p = Product.fromJson(baseJson());

      expect(p.specifications['ram'], '16GB');
      expect(p.specifications['cpu'], 'i7');
    });

    test('handles missing optional fields gracefully', () {
      final minimal = {
        'id': 'p-002',
        'name': 'Mouse',
        'sku': 'ISET-PER-20240101-001',
        'created_at': '2023-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };
      final p = Product.fromJson(minimal);

      expect(p.id, 'p-002');
      expect(p.price, isNull);
      expect(p.rfidTag, isNull);
      expect(p.warrantyExpiry, isNull);
      expect(p.tags, isEmpty);
      expect(p.specifications, isEmpty);
      expect(p.status, 'in_stock');
    });

    test('handles price as integer', () {
      final json = baseJson()..['price'] = 500;
      final p = Product.fromJson(json);
      expect(p.price, 500.0);
    });

    test('handles null price', () {
      final json = baseJson()..['price'] = null;
      final p = Product.fromJson(json);
      expect(p.price, isNull);
    });

    test('handles tags as non-list (falls back to empty)', () {
      final json = baseJson()..['tags'] = null;
      final p = Product.fromJson(json);
      expect(p.tags, isEmpty);
    });

    test('handles specifications as non-map (falls back to empty)', () {
      final json = baseJson()..['specifications'] = 'bad';
      final p = Product.fromJson(json);
      expect(p.specifications, isEmpty);
    });

    test('falls back to now when created_at is missing', () {
      final json = baseJson()
        ..remove('created_at')
        ..remove('updated_at');
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final p = Product.fromJson(json);
      expect(p.createdAt.isAfter(before), isTrue);
    });
  });

  group('Product.copyWith', () {
    test('returns identical product when no arguments given', () {
      final p = Product.fromJson(baseJson());
      final copy = p.copyWith();

      expect(copy.id, p.id);
      expect(copy.name, p.name);
      expect(copy.status, p.status);
      expect(copy.quantity, p.quantity);
    });

    test('overrides only the specified fields', () {
      final p = Product.fromJson(baseJson());
      final copy = p.copyWith(name: 'HP Laptop', quantity: 10);

      expect(copy.name, 'HP Laptop');
      expect(copy.quantity, 10);
      expect(copy.id, p.id);
      expect(copy.sku, p.sku);
    });

    test('can clear nullable fields to null', () {
      final p = Product.fromJson(baseJson());
      expect(p.rfidTag, isNotNull);

      final copy = p.copyWith(rfidTag: null);
      expect(copy.rfidTag, isNull);
    });

    test('preserves nullable fields when not specified', () {
      final p = Product.fromJson(baseJson());
      final copy = p.copyWith(name: 'Updated');

      expect(copy.rfidTag, p.rfidTag);
      expect(copy.warrantyExpiry, p.warrantyExpiry);
    });

    test('can update status', () {
      final p = Product.fromJson(baseJson());
      final copy = p.copyWith(status: 'in_maintenance');
      expect(copy.status, 'in_maintenance');
    });
  });

  group('Product.toJson', () {
    test('includes required fields', () {
      final p = Product.fromJson(baseJson());
      final json = p.toJson();

      expect(json['name'], 'Dell Laptop');
      expect(json['sku'], 'ISET-PC-20240101-001');
      expect(json['quantity'], 5);
      expect(json['tags'], ['laptop', 'portable']);
    });

    test('omits null type', () {
      final json = baseJson()..remove('category_id');
      final p = Product.fromJson(json);
      final out = p.toJson();
      expect(out.containsKey('type'), isFalse);
    });
  });
}
