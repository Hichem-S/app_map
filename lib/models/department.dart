import 'package:flutter/material.dart';

class Department {
  final String id;
  final String code;
  final String name;
  final String color;
  final int roomCount;
  final int productCount;

  const Department({
    required this.id,
    required this.code,
    required this.name,
    required this.color,
    this.roomCount = 0,
    this.productCount = 0,
  });

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        id:           json['id'] as String,
        code:         json['code'] as String,
        name:         json['name'] as String,
        color:        json['color'] as String? ?? '#6366F1',
        roomCount:    int.tryParse(json['room_count']?.toString() ?? '0') ?? 0,
        productCount: int.tryParse(json['product_count']?.toString() ?? '0') ?? 0,
      );

  Color get flutterColor => _parseHex(color);
  Color get flutterBg    => _parseHex(color).withValues(alpha: 0.15);

  static Color _parseHex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
