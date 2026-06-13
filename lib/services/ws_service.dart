import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

class WsService {
  static WebSocketChannel? _channel;
  static StreamSubscription? _sub;

  static final _broadcast = StreamController<dynamic>.broadcast();
  static Stream<dynamic> get stream => _broadcast.stream;

  // Token never goes in the URL — sent as first message after connect
  static String get _wsUrl => ApiService.baseUrl
      .replaceFirst(RegExp(r'^http'), 'ws')
      .replaceAll('/api', '');

  static Future<void> connect() async {
    if (_channel != null) return;

    final token = await ApiService.getToken();
    if (token == null) {
      debugPrint('[WS] No token — skipping');
      return;
    }

    debugPrint('[WS] Connecting to $_wsUrl');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      _sub = _channel!.stream.listen(
        (data) {
          debugPrint('[WS] ← $data');
          _broadcast.add(data);
        },
        onError: (e) {
          debugPrint('[WS] Error: $e');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[WS] Closed — reconnecting');
          _scheduleReconnect();
        },
        cancelOnError: false,
      );

      // Authenticate via first message — token never touches the URL or logs
      _channel!.sink.add(jsonEncode({'type': 'auth', 'token': token}));

      debugPrint('[WS] Connected ✅');
    } catch (e) {
      debugPrint('[WS] connect() threw: $e');
      _channel = null;
      _scheduleReconnect();
    }
  }

  static void _scheduleReconnect() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    Future.delayed(const Duration(seconds: 3), connect);
  }

  static void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  static void disconnect() {
    _sub?.cancel();
    _channel?.sink.close();
    _sub = null;
    _channel = null;
  }
}
