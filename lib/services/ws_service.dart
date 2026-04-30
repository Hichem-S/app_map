import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

class WsService {
  static WebSocketChannel? _channel;
  static const String wsUrl = 'ws://172.20.10.5:3000';

  static Future<void> connect() async {
    final token = await ApiService.getToken();
    _channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl?token=$token'),
    );
    print('WebSocket connected');
  }

  static Stream? get stream => _channel?.stream;

  static void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  static void disconnect() {
    _channel?.sink.close();
  }
}
