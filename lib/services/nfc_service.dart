import 'package:flutter/services.dart';

class NfcService {
  static const _channel = EventChannel('com.example.app_map/nfc');

  static Stream<String> get tagStream =>
      _channel.receiveBroadcastStream().map((e) => e as String);
}
