import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:pointycastle/ecc/api.dart';
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as pc_utils;

import 'find_my_controller.dart';
import 'decrypt_reports.dart';
import '../accessory_battery.dart';

class FindMyLocationReport {
  static const _pointCorrection = 0xFFFFFFFF / 10000000;

  double? latitude;
  double? longitude;
  int? accuracy;
  DateTime? timestamp;
  int? confidence;
  AccessoryBatteryStatus? batteryStatus;
  dynamic result;
  String? base64privateKey;
  String? id;
  String? hash;

  FindMyLocationReport(this.latitude, this.longitude, this.accuracy,
      this.timestamp, this.confidence, this.batteryStatus);

  FindMyLocationReport.withHash(
      this.latitude, this.longitude, this.timestamp, this.hash) {
    accuracy = 50;
  }

  FindMyLocationReport.decrypted(this.result, this.base64privateKey, this.id) {
    hash = result['payload'];
  }

  bool isEncrypted() => latitude == null;

  String? getId() => id;

  Future<void> decrypt() async {
    await Future.delayed(const Duration(milliseconds: 1));
    if (isEncrypted()) {
      final report = FindMyReport(
          base64Decode(result['payload']), id!, result['statusCode']);
      final decrypted = await DecryptReports.decryptReport(
          report, base64Decode(base64privateKey!));
      latitude    = _correctCoordinate(decrypted.latitude!, 90);
      longitude   = _correctCoordinate(decrypted.longitude!, 180);
      accuracy    = decrypted.accuracy;
      timestamp   = decrypted.timestamp;
      confidence  = decrypted.confidence;
      batteryStatus = decrypted.batteryStatus;
      result = null;
      base64privateKey = null;
    }
  }

  double _correctCoordinate(double c, int threshold) {
    if (c >  threshold) c -= _pointCorrection;
    if (c < -threshold) c += _pointCorrection;
    return c;
  }
}

class FindMyReport {
  Uint8List payload;
  String id;
  int statusCode;
  int? confidence;
  DateTime? timestamp;

  FindMyReport(this.payload, this.id, this.statusCode);
}

class FindMyKeyPair {
  final ECPublicKey _publicKey;
  final ECPrivateKey _privateKey;
  final String hashedPublicKey;
  String? privateKeyBase64;
  final DateTime startTime;
  final double duration;

  FindMyKeyPair(this._publicKey, this.hashedPublicKey, this._privateKey,
      this.startTime, this.duration);

  String getBase64PublicKey() => base64Encode(_publicKey.Q!.getEncoded(false));

  String getBase64PrivateKey() =>
      base64Encode(pc_utils.encodeBigIntAsUnsigned(_privateKey.d!));

  String getBase64AdvertisementKey() =>
      base64Encode(_getAdvertisementKey());

  Uint8List _getAdvertisementKey() {
    final pkBytes = _publicKey.Q!.getEncoded(true);
    return pkBytes.sublist(1, pkBytes.length);
  }

  String getHashedAdvertisementKey() {
    final key = _getAdvertisementKey();
    return FindMyController.getHashedPublicKey(publicKeyBytes: key);
  }
}
