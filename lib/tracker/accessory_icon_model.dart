import 'package:flutter/material.dart';

class AccessoryIconModel {
  static const List<String> icons = [
    'creditcard.fill', 'briefcase.fill', 'case.fill', 'latch.2.case.fill',
    'key.fill', 'mappin', 'globe', 'crown.fill',
    'gift.fill', 'car.fill', 'bicycle', 'figure.walk',
    'heart.fill', 'hare.fill', 'tortoise.fill', 'eye.fill',
  ];

  static const iconMapping = {
    'creditcard.fill': Icons.credit_card,
    'briefcase.fill': Icons.business_center,
    'case.fill': Icons.work,
    'latch.2.case.fill': Icons.business_center,
    'key.fill': Icons.vpn_key,
    'mappin': Icons.place,
    'globe': Icons.language,
    'crown.fill': Icons.school,
    'gift.fill': Icons.redeem,
    'car.fill': Icons.directions_car,
    'bicycle': Icons.pedal_bike,
    'figure.walk': Icons.directions_walk,
    'heart.fill': Icons.favorite,
    'hare.fill': Icons.pets,
    'tortoise.fill': Icons.bug_report,
    'eye.fill': Icons.visibility,
  };

  static IconData? mapIcon(String iconName) => iconMapping[iconName];
}
