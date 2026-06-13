import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inventory/models/room.dart';

void main() {
  Map<String, dynamic> baseJson() => {
        'id': 'r-001',
        'department_id': 'd-001',
        'name': 'Lab GI 1',
        'type': 'lab',
        'product_count': '12',
        'in_stock': '8',
        'in_maintenance': '2',
        'critical_issue': '1',
        'retired': '1',
        'room_code': 'LGI1',
        'bloc': 'A',
        'floor': '1',
        'capacity': '30',
      };

  group('Room.fromJson', () {
    test('parses all fields correctly', () {
      final r = Room.fromJson(baseJson());

      expect(r.id, 'r-001');
      expect(r.departmentId, 'd-001');
      expect(r.name, 'Lab GI 1');
      expect(r.type, 'lab');
      expect(r.roomCode, 'LGI1');
      expect(r.bloc, 'A');
      expect(r.floor, '1');
      expect(r.capacity, 30);
    });

    test('parses string-encoded counts as integers', () {
      final r = Room.fromJson(baseJson());

      expect(r.productCount, 12);
      expect(r.inStock, 8);
      expect(r.inMaintenance, 2);
      expect(r.criticalIssue, 1);
      expect(r.retired, 1);
    });

    test('parses integer counts directly', () {
      final json = baseJson()
        ..['product_count'] = 5
        ..['in_stock'] = 5;
      final r = Room.fromJson(json);
      expect(r.productCount, 5);
      expect(r.inStock, 5);
    });

    test('defaults to zero for missing counts', () {
      final json = {
        'id': 'r-002',
        'department_id': 'd-001',
        'name': 'Storage',
        'type': 'classroom',
      };
      final r = Room.fromJson(json);

      expect(r.productCount, 0);
      expect(r.inStock, 0);
      expect(r.inMaintenance, 0);
    });

    test('defaults type to classroom when missing', () {
      final json = baseJson()..remove('type');
      final r = Room.fromJson(json);
      expect(r.type, 'classroom');
    });

    test('handles null optional fields', () {
      final json = baseJson()
        ..['room_code'] = null
        ..['bloc'] = null
        ..['floor'] = null
        ..['capacity'] = null;
      final r = Room.fromJson(json);

      expect(r.roomCode, isNull);
      expect(r.bloc, isNull);
      expect(r.capacity, isNull);
    });
  });

  group('Room.copyWith', () {
    test('returns identical room when no arguments given', () {
      final r = Room.fromJson(baseJson());
      final copy = r.copyWith();

      expect(copy.id, r.id);
      expect(copy.name, r.name);
      expect(copy.type, r.type);
    });

    test('overrides specified fields', () {
      final r = Room.fromJson(baseJson());
      final copy = r.copyWith(name: 'Lab GI 2', type: 'office');

      expect(copy.name, 'Lab GI 2');
      expect(copy.type, 'office');
      expect(copy.id, r.id);
    });

    test('preserves counts from original', () {
      final r = Room.fromJson(baseJson());
      final copy = r.copyWith(name: 'Updated');

      expect(copy.productCount, r.productCount);
      expect(copy.inStock, r.inStock);
    });

    test('clearRoomCode sets roomCode to null', () {
      final r = Room.fromJson(baseJson());
      expect(r.roomCode, isNotNull);
      final copy = r.copyWith(clearRoomCode: true);
      expect(copy.roomCode, isNull);
    });

    test('clearCapacity sets capacity to null', () {
      final r = Room.fromJson(baseJson());
      final copy = r.copyWith(clearCapacity: true);
      expect(copy.capacity, isNull);
    });
  });

  group('Room._int helper', () {
    test('handles malformed string gracefully', () {
      final json = baseJson()..['product_count'] = 'abc';
      final r = Room.fromJson(json);
      expect(r.productCount, 0);
    });

    test('handles null gracefully', () {
      final json = baseJson()..['product_count'] = null;
      final r = Room.fromJson(json);
      expect(r.productCount, 0);
    });
  });
}
