import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocode;
import 'package:latlong2/latlong.dart';
import 'accessory_battery.dart';
import 'accessory_icon_model.dart';
import 'findmy/find_my_controller.dart';
import 'findmy/models.dart';
import 'location_model.dart';

const defaultTrackerIcon = Icons.push_pin;

// Shared instance used only for reverse-geocoding calls
final _geoHelper = TrackerLocationModel();

class LocationPair {
  final LatLng location;
  final DateTime start;
  DateTime end;

  LocationPair(this.location, this.start, this.end);

  Map<String, dynamic> toJson() => {
        'lat': location.latitude,
        'lon': location.longitude,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };

  static LocationPair fromJson(Map<String, dynamic> json) => LocationPair(
        LatLng(json['lat'], json['lon']),
        DateTime.parse(json['start']),
        DateTime.parse(json['end']),
      );
}

class Accessory {

  String id;
  String hashedPublicKey;
  String name;
  List<String> additionalKeys;
  String _icon;
  Color color;
  bool isActive;
  DateTime? datePublished;
  LatLng? _lastLocation;
  AccessoryBatteryStatus? lastBatteryStatus;
  List<LocationPair> locationHistory = [];
  Map<String, dynamic> hashesWithTS = {};
  Future<geocode.Placemark?> place = Future.value(null);
  bool hasChangedFlag = false;

  Accessory({
    required this.id,
    required this.name,
    required this.hashedPublicKey,
    required this.datePublished,
    this.isActive = true,
    LatLng? lastLocation,
    String icon = 'mappin',
    this.color = Colors.grey,
    required this.additionalKeys,
    required this.hashesWithTS,
    required this.lastBatteryStatus,
    required this.locationHistory,
  })  : _icon = icon,
        _lastLocation = lastLocation {
    if (_lastLocation != null) {
      place = _geoHelper.getAddress(_lastLocation!);
    }
  }

  Accessory clone() => Accessory(
        id: id,
        name: name,
        hashedPublicKey: hashedPublicKey,
        datePublished: datePublished,
        color: color,
        icon: _icon,
        isActive: isActive,
        lastLocation: _lastLocation,
        hashesWithTS: hashesWithTS,
        additionalKeys: additionalKeys,
        locationHistory: locationHistory,
        lastBatteryStatus: lastBatteryStatus,
      );

  void update(Accessory other) {
    id = other.id;
    name = other.name;
    hashedPublicKey = other.hashedPublicKey;
    color = other.color;
    _icon = other._icon;
    isActive = other.isActive;
    hashesWithTS = other.hashesWithTS;
    locationHistory = other.locationHistory;
    additionalKeys = other.additionalKeys;
  }

  LatLng? get lastLocation => _lastLocation;
  set lastLocation(LatLng? v) {
    _lastLocation = v;
    if (v != null) place = _geoHelper.getAddress(v);
  }

  IconData get icon => AccessoryIconModel.mapIcon(_icon) ?? defaultTrackerIcon;
  String get rawIcon => _icon;
  void setIcon(String icon) => _icon = icon;

  Accessory.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        hashedPublicKey = json['hashedPublicKey'],
        datePublished = json['datePublished'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['datePublished'])
            : null,
        _lastLocation = json['latitude'] != null && json['longitude'] != null
            ? LatLng(json['latitude'].toDouble(), json['longitude'].toDouble())
            : null,
        isActive = json['isDeployed'] ?? json['isActive'],
        _icon = json['icon'],
        color = Color(int.parse(json['color'].substring(0, 8), radix: 16)),
        lastBatteryStatus = json['lastBatteryStatus'] != null
            ? AccessoryBatteryStatus.values.byName(json['lastBatteryStatus'])
            : null,
        hashesWithTS = json['hashesWithTS'] != null
            ? jsonDecode(json['hashesWithTS']) as Map<String, dynamic>
            : {},
        additionalKeys = (json['additionalKeys'] as List?)?.cast<String>() ?? [] {
    if (_lastLocation != null) place = _geoHelper.getAddress(_lastLocation!);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hashedPublicKey': hashedPublicKey,
        'datePublished': datePublished?.millisecondsSinceEpoch,
        'latitude': _lastLocation?.latitude,
        'longitude': _lastLocation?.longitude,
        'isActive': isActive,
        'icon': _icon,
        'color': color.toARGB32().toRadixString(16).padLeft(8, '0'),
        'hashesWithTS': jsonEncode(hashesWithTS),
        'additionalKeys': additionalKeys,
        if (lastBatteryStatus != null) 'lastBatteryStatus': lastBatteryStatus!.name,
      };

  Future<String> getHashedPublicKey() async => hashedPublicKey;

  Future<List<String>> getAdditionalPrivateKeys() =>
      Stream.fromIterable(additionalKeys)
          .asyncMap(FindMyController.getKeyPair)
          .map((kp) => kp.getBase64PrivateKey())
          .toList();

  void addLocationHistoryEntry(FindMyLocationReport report) {
    final reportDate = report.timestamp!;
    LocationPair? closest;

    for (final pair in locationHistory) {
      if (reportDate.isAtSameMomentAs(pair.start) ||
          reportDate.isAtSameMomentAs(pair.end) ||
          (locationHistory.isNotEmpty &&
              reportDate.isAfter(locationHistory[0].start) &&
              reportDate.isBefore(locationHistory[0].end))) {
        closest = pair;
        break;
      }
      if (closest != null &&
          pair.start.isBefore(reportDate) &&
          reportDate.isAfter(closest.start)) {
        closest = pair;
        continue;
      }
      if (closest == null && pair.start.isBefore(reportDate)) {
        closest = pair;
      }
    }

    if (closest != null) {
      final latClose =
          (closest.location.latitude - report.latitude!).abs() <= 0.001;
      final lonClose =
          (closest.location.longitude - report.longitude!).abs() <= 0.001;
      if (latClose && lonClose) {
        if (reportDate.isAfter(closest.end)) closest.end = reportDate;
      } else if (!reportDate.isAtSameMomentAs(closest.start) &&
          !reportDate.isAtSameMomentAs(closest.end)) {
        locationHistory.add(LocationPair(
            LatLng(report.latitude!, report.longitude!), reportDate, reportDate));
        if (reportDate.isAfter(closest.start) &&
            reportDate.isBefore(closest.end)) {
          locationHistory.add(LocationPair(
              LatLng(closest.location.latitude, closest.location.longitude),
              closest.end,
              closest.end));
          closest.end = closest.start;
        }
      }
    } else {
      locationHistory.add(LocationPair(
          LatLng(report.latitude!, report.longitude!), reportDate, reportDate));
    }
  }

  void addLocationHistory(List<dynamic> list) =>
      locationHistory = list.map((e) => LocationPair.fromJson(e)).toList();

  DateTime latestHistoryEntry() => locationHistory.isEmpty
      ? DateTime.fromMicrosecondsSinceEpoch(0)
      : locationHistory.first.end;

  void addDecryptedHash(String? hash) {
    if (hash != null && hash.length >= 10) {
      hashesWithTS[hash.substring(hash.length - 10)] =
          DateTime.now().millisecondsSinceEpoch;
    }
  }

  bool containsHash(String? hash) {
    if (hash == null || hash.length < 10) return false;
    return hashesWithTS.containsKey(hash.substring(hash.length - 10));
  }

  void removeOldHashes() {
    final cutoff =
        DateTime.now().millisecondsSinceEpoch - 7 * 24 * 60 * 60 * 1000;
    hashesWithTS.removeWhere((_, v) => v < cutoff);
  }

  List<LocationPair> getSortedLocationHistory() {
    locationHistory.sort((a, b) => a.start.compareTo(b.start));
    return locationHistory;
  }
}
