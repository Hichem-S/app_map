import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:pointycastle/export.dart';
// ignore: implementation_imports
import 'package:pointycastle/src/platform_check/platform_check.dart';
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as pc_utils;

import 'models.dart';
import 'reports_fetcher.dart';
import '../tracker_settings.dart';

class FindMyController {
  static const _storage = FlutterSecureStorage();
  static final ECCurve_secp224r1 _curveParams = ECCurve_secp224r1();
  static final HashMap _keyCache = HashMap();


  static Future<List<FindMyLocationReport>> computeResults(
      List<FindMyKeyPair> keyPairs, String? url) async {
    for (final kp in keyPairs) {
      await _loadPrivateKey(kp);
    }

    final days = await TrackerSettings.getDays();
    final user = await TrackerSettings.getUser();
    final pass = await TrackerSettings.getPass();

    if (url == null || url.isEmpty) url = 'http://localhost:6176';

    final map = <String, Object>{
      'keyPair':     keyPairs,
      'url':         url,
      'daysToFetch': days,
      'user':        user,
      'pass':        pass,
    };
    return compute(_getListedReportResults, map);
  }

  static Future<List<FindMyLocationReport>> _getListedReportResults(
      Map map) async {
    final keyPairs = map['keyPair'] as List<FindMyKeyPair>;
    final url = map['url'] as String;
    final daysToFetch = map['daysToFetch'] as int;
    final user = map['user'] as String;
    final pass = map['pass'] as String;

    final hashedMap = {for (final kp in keyPairs) kp.getHashedAdvertisementKey(): kp};

    final jsonResults = await ReportsFetcher.fetchLocationReports(
        hashedMap.keys, daysToFetch, url, user, pass);

    final results = <FindMyLocationReport>[];
    FindMyLocationReport? latest;
    for (final result in jsonResults) {
      final keyPair = hashedMap[result['id']] as FindMyKeyPair;
      final report = FindMyLocationReport.decrypted(
          result, keyPair.getBase64PrivateKey(), keyPair.getHashedAdvertisementKey());
      latest ??= report;
      results.add(report);
    }
    if (latest != null) await latest.decrypt();
    return results;
  }

  static Future<void> _loadPrivateKey(FindMyKeyPair keyPair) async {
    if (!_keyCache.containsKey(keyPair.hashedPublicKey)) {
      final privateKey = await _storage.read(key: keyPair.hashedPublicKey);
      _keyCache.putIfAbsent(keyPair.hashedPublicKey, () => privateKey);
    }
    keyPair.privateKeyBase64 = _keyCache[keyPair.hashedPublicKey] as String?;
  }

  static ECPublicKey _derivePublicKey(ECPrivateKey privateKey) {
    final pk = _curveParams.G * privateKey.d;
    return ECPublicKey(pk, _curveParams);
  }

  static Future<FindMyKeyPair> getKeyPair(String base64HashedPublicKey) async {
    final privateKeyBase64 = await _storage.read(key: base64HashedPublicKey);
    final privateKey = ECPrivateKey(
        pc_utils.decodeBigIntWithSign(1, base64Decode(privateKeyBase64!)),
        _curveParams);
    return FindMyKeyPair(
        _derivePublicKey(privateKey), base64HashedPublicKey, privateKey,
        DateTime.now(), -1);
  }

  static Future<FindMyKeyPair> importKeyPair(String privateKeyBase64) async {
    final privateKeyBytes = base64Decode(privateKeyBase64);
    final privateKey = ECPrivateKey(
        pc_utils.decodeBigIntWithSign(1, privateKeyBytes), _curveParams);
    final publicKey = _derivePublicKey(privateKey);
    final hashedPublicKey = getHashedPublicKey(publicKey: publicKey);
    final keyPair = FindMyKeyPair(
        publicKey, hashedPublicKey, privateKey, DateTime.now(), -1);
    await _storage.write(key: hashedPublicKey, value: keyPair.getBase64PrivateKey());
    return keyPair;
  }

  static Future<FindMyKeyPair> generateKeyPair() async {
    final ecCurve = ECCurve_secp224r1();
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(
          Platform.instance.platformEntropySource().getBytes(32)));
    final keyGen = ECKeyGenerator()
      ..init(ParametersWithRandom(ECKeyGeneratorParameters(ecCurve), secureRandom));
    final newKeyPair = keyGen.generateKeyPair();
    final publicKey  = newKeyPair.publicKey;
    final privateKey = newKeyPair.privateKey;
    final hashedKey  = getHashedPublicKey(publicKey: publicKey);
    final keyPair = FindMyKeyPair(publicKey, hashedKey, privateKey, DateTime.now(), -1);
    await _storage.write(key: hashedKey, value: keyPair.getBase64PrivateKey());
    return keyPair;
  }

  static String getHashedPublicKey(
      {Uint8List? publicKeyBytes, ECPublicKey? publicKey}) {
    final pkBytes = publicKeyBytes ?? publicKey!.Q!.getEncoded(false);
    final shaDigest = SHA256Digest();
    shaDigest.update(pkBytes, 0, pkBytes.lengthInBytes);
    final out = Uint8List(shaDigest.digestSize);
    shaDigest.doFinal(out, 0);
    return base64Encode(out);
  }
}
