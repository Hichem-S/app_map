import 'dart:typed_data';

import 'package:pointycastle/export.dart';
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as pc_utils;

import 'models.dart';
import '../accessory_battery.dart';

class DecryptReports {
  static Future<FindMyLocationReport> decryptReport(
      FindMyReport report, Uint8List key) async {
    final curveDomainParam = ECCurve_secp224r1();
    var payloadData = report.payload;
    if (payloadData.length > 88) {
      final modifiedData = Uint8List(payloadData.length - 1);
      modifiedData.setRange(0, 4, payloadData);
      modifiedData.setRange(4, modifiedData.length, payloadData, 5);
      payloadData = modifiedData;
    }

    final ephemeralKeyBytes = payloadData.sublist(5, 62);
    final encData = payloadData.sublist(62, 72);
    final tag = payloadData.sublist(72, payloadData.length);

    _decodeTimeAndConfidence(payloadData, report);

    final privateKey =
        ECPrivateKey(pc_utils.decodeBigIntWithSign(1, key), curveDomainParam);
    final decodePoint = curveDomainParam.curve.decodePoint(ephemeralKeyBytes);
    final ephemeralPublicKey = ECPublicKey(decodePoint, curveDomainParam);

    final Uint8List sharedKeyBytes = _ecdh(ephemeralPublicKey, privateKey);
    final Uint8List derivedKey = _kdf(sharedKeyBytes, ephemeralKeyBytes);
    final decryptedPayload = _decryptPayload(encData, derivedKey, tag);
    return _decodePayload(decryptedPayload, report);
  }

  static void _decodeTimeAndConfidence(
      Uint8List payloadData, FindMyReport report) {
    final seenTimeStamp =
        payloadData.sublist(0, 4).buffer.asByteData().getInt32(0, Endian.big);
    report.timestamp =
        DateTime.utc(2001).add(Duration(seconds: seenTimeStamp)).toLocal();
    report.confidence = payloadData.elementAt(4);
  }

  static Uint8List _ecdh(
      ECPublicKey ephemeralPublicKey, ECPrivateKey privateKey) {
    final sharedKey = ephemeralPublicKey.Q! * privateKey.d;
    final bytes = sharedKey!.x!
        .toBigInteger()!
        .toUnsigned(28 * 8)
        .toRadixString(16)
        .padLeft(28 * 2, '0');
    return Uint8List.fromList(List.generate(
        28, (i) => int.parse(bytes.substring(i * 2, i * 2 + 2), radix: 16)));
  }

  static FindMyLocationReport _decodePayload(
      Uint8List payload, FindMyReport report) {
    final latitude  = payload.buffer.asByteData(0, 4).getUint32(0, Endian.big);
    final longitude = payload.buffer.asByteData(4, 4).getUint32(0, Endian.big);
    final accuracy  = payload.buffer.asByteData(8, 1).getUint8(0);
    final status    = payload.buffer.asByteData(9, 1).getUint8(0);

    AccessoryBatteryStatus? batteryStatus;
    if (status & 00100000 != 0 || status > 0) {
      switch (status >> 6) {
        case 0: batteryStatus = AccessoryBatteryStatus.ok; break;
        case 1: batteryStatus = AccessoryBatteryStatus.medium; break;
        case 2: batteryStatus = AccessoryBatteryStatus.low; break;
        case 3: batteryStatus = AccessoryBatteryStatus.criticalLow; break;
      }
    }

    return FindMyLocationReport(
      latitude  / 10000000.0,
      longitude / 10000000.0,
      accuracy,
      report.timestamp,
      report.confidence,
      batteryStatus,
    );
  }

  static Uint8List _decryptPayload(
      Uint8List cipherText, Uint8List symmetricKey, Uint8List tag) {
    final decryptionKey = symmetricKey.sublist(0, 16);
    final iv = symmetricKey.sublist(16, symmetricKey.length);

    final aesGcm = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(
          KeyParameter(decryptionKey), tag.lengthInBytes * 8, iv, tag));

    final plainText = Uint8List(cipherText.length);
    var offset = 0;
    while (offset < cipherText.length) {
      offset += aesGcm.processBlock(cipherText, offset, plainText, offset);
    }
    return plainText;
  }

  static Uint8List _kdf(Uint8List secret, Uint8List ephemeralKey) {
    var shaDigest = SHA256Digest();
    shaDigest.update(secret, 0, secret.length);
    final counterData = ByteData(4)..setUint32(0, 1);
    final counterBytes = counterData.buffer.asUint8List();
    shaDigest.update(counterBytes, 0, counterBytes.lengthInBytes);
    shaDigest.update(ephemeralKey, 0, ephemeralKey.lengthInBytes);
    final out = Uint8List(shaDigest.digestSize);
    shaDigest.doFinal(out, 0);
    return out;
  }
}
