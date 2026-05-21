import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

import 'accessory_model.dart';
import 'findmy/find_my_controller.dart';
import 'findmy/models.dart';
import 'tracker_settings.dart';

const _accessoryKey = 'ACCESSORIES';
const _historyKey   = 'HISTORY';

class AccessoryRegistry extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  List<Accessory> _accessories = [];
  bool loading = false;
  bool initialLoadFinished = false;


  UnmodifiableListView<Accessory> get accessories =>
      UnmodifiableListView(_accessories);

  Future<void> loadAccessories() async {
    loading = true;
    notifyListeners();

    String? serialized;
    try {
      serialized = await _storage.read(key: _accessoryKey);
    } catch (_) {}

    if (serialized != null) {
      final list = json.decode(serialized) as List;
      _accessories = list.map((v) => Accessory.fromJson(v)).toList();
      await _clearInvalidAccessories();
    } else {
      _accessories = [];
    }

    await _loadHistory();
    loading = false;
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final history = await _storage.read(key: _historyKey);
    if (history == null) return;
    final decoded = jsonDecode(history) as Map<String, dynamic>;
    for (final item in _accessories) {
      final curr = decoded[item.id];
      if (curr != null) item.addLocationHistory(curr as List);
    }
  }

  Future<int> loadLocationReports(Iterable<Accessory> toUpdate) async {
    final url = await TrackerSettings.getUrl();

    final requests = <Future<List<FindMyLocationReport>>>[];
    for (final accessory in toUpdate) {
      final keyPair = await FindMyController.getKeyPair(accessory.hashedPublicKey);
      final additionalPairs = await Stream.fromIterable(accessory.additionalKeys)
          .asyncMap(FindMyController.getKeyPair)
          .toList();
      additionalPairs.add(keyPair);
      requests.add(FindMyController.computeResults(additionalPairs, url));
    }

    final reportsForAll = await Future.wait(requests);
    int total = 0;
    final historyMap = <Accessory, Future<List<LocationPair>>>{};

    for (int i = 0; i < toUpdate.length; i++) {
      final accessory = toUpdate.elementAt(i);
      final reports   = reportsForAll[i];
      total += reports.length;

      final decrypted = reports.where((r) => !r.isEncrypted());
      if (decrypted.isNotEmpty) {
        final last = decrypted.first;
        final reportDate = last.timestamp ?? DateTime.fromMicrosecondsSinceEpoch(0);
        if (accessory.datePublished == null ||
            reportDate.isAfter(accessory.datePublished!)) {
          accessory.datePublished = reportDate;
          accessory.lastLocation  = LatLng(last.latitude!, last.longitude!);
          accessory.lastBatteryStatus = last.batteryStatus;
          accessory.hasChangedFlag = true;
        }
      }
      historyMap[accessory] = _fillHistory(reports, accessory);
    }

    await _storeAccessories();
    await _storeHistory(historyMap);
    initialLoadFinished = true;
    notifyListeners();
    return total;
  }

  Future<List<LocationPair>> _fillHistory(
      List<FindMyLocationReport> reports, Accessory accessory) async {
    final fresh = <FindMyLocationReport>[];

    for (final r in reports) {
      if (!accessory.containsHash(r.hash)) {
        accessory.addDecryptedHash(r.hash);
        await r.decrypt();
        fresh.add(r);
      }
    }

    accessory.removeOldHashes();
    fresh.sort((a, b) =>
        (a.timestamp ?? DateTime(1970)).compareTo(b.timestamp ?? DateTime(1970)));

    if (fresh.isNotEmpty) {
      final last = fresh.last;
      final ts = last.timestamp ?? DateTime(1971);
      if (accessory.datePublished == null ||
          accessory.datePublished!.isBefore(ts)) {
        accessory.lastLocation = LatLng(last.latitude!, last.longitude!);
        accessory.datePublished = ts;
        accessory.lastBatteryStatus = last.batteryStatus;
        accessory.hasChangedFlag = true;
        notifyListeners();
      }
    }

    for (final r in fresh) {
      if (r.longitude!.abs() <= 180 && r.latitude!.abs() <= 90) {
        accessory.addLocationHistoryEntry(r);
      }
    }

    await _storeAccessories();
    return accessory.locationHistory;
  }

  Future<void> _storeHistory(
      Map<Accessory, Future<List<LocationPair>>> map) async {
    final result = <String, List<LocationPair>>{};
    final cutoff = DateTime.now().subtract(const Duration(days: 7));

    for (final entry in map.entries) {
      final filtered = (await entry.value)
          .where((p) => p.end.isAfter(cutoff))
          .toList();
      result[entry.key.id] = filtered;
    }
    for (final a in _accessories) {
      if (!result.containsKey(a.id)) result[a.id] = a.locationHistory;
    }
    await _storage.write(
        key: _historyKey, value: jsonEncode(result));
  }

  Future<void> _storeAccessories() async {
    final list = _accessories.map(jsonEncode).toList();
    await _storage.write(key: _accessoryKey, value: jsonEncode(list));
  }

  void addAccessory(Accessory accessory) {
    _accessories.removeWhere(
        (a) => a.hashedPublicKey == accessory.hashedPublicKey);
    _accessories.add(accessory);
    _storeAccessories();
    notifyListeners();
  }

  void removeAccessory(Accessory accessory) {
    _accessories.remove(accessory);
    accessory.getHashedPublicKey().then((k) => _storage.delete(key: k));
    _storeAccessories();
    notifyListeners();
  }

  void editAccessory(Accessory old, Accessory updated) {
    old.update(updated);
    _storeAccessories();
    notifyListeners();
  }

  void deleteData(Accessory accessory) {
    accessory
      ..lastBatteryStatus = null
      ..lastLocation = null
      ..hashesWithTS.clear()
      ..datePublished = DateTime(1970)
      ..place = Future.value(null)
      ..locationHistory.clear();
    _removeHistoryEntry(accessory);
    _storeAccessories();
    notifyListeners();
  }

  Future<void> _removeHistoryEntry(Accessory a) async {
    final raw = await _storage.read(key: _historyKey);
    if (raw == null || raw.isEmpty) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    map.remove(a.id);
    await _storage.write(key: _historyKey, value: jsonEncode(map));
  }

  void saveOrderUpdates(List<Accessory> newOrder) {
    final positions = {for (int i = 0; i < newOrder.length; i++) newOrder[i]: i};
    _accessories.sort((a, b) => positions[a]!.compareTo(positions[b]!));
    _storeAccessories();
  }

  Future<void> _clearInvalidAccessories() async {
    final toRemove = <int>[];
    for (int i = 0; i < _accessories.length; i++) {
      final has = await _storage.containsKey(key: _accessories[i].hashedPublicKey);
      if (!has) toRemove.add(i);
    }
    for (final idx in toRemove.reversed) {
      _accessories.removeAt(idx);
    }
  }
}
