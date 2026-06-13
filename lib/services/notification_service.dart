import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';
import 'ws_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final List<AppNotification> _notifications = [];
  StreamSubscription? _wsSub;
  bool _initialized = false;
  bool _muted = false;

  List<AppNotification> get all => List.unmodifiable(_notifications);
  int get unreadCount => _muted ? 0 : _notifications.where((n) => !n.isRead).length;
  bool get muted => _muted;

  void setMuted(bool value) {
    if (_muted == value) return;
    _muted = value;
    if (!_muted) loadFromApi(); // catch up on any notifications received while muted
    notifyListeners();
  }

  // Idempotent — safe to call multiple times (e.g. widget rebuilds).
  // Only wires up the WS subscription once per login session.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _wsSub = WsService.stream.listen(_handle, onError: (_) {});
    await loadFromApi();
  }

  // Call on logout to allow clean re-init on next login.
  void reset() {
    _initialized = false;
    _muted = false;
    _wsSub?.cancel();
    _wsSub = null;
    _notifications.clear();
    notifyListeners();
  }

  Future<void> loadFromApi() async {
    try {
      final rows = await ApiService.getNotifications();
      _notifications
        ..clear()
        ..addAll(rows.map(AppNotification.fromJson));
      notifyListeners();
    } catch (e) {
      debugPrint('[NOTIF] loadFromApi error: $e');
    }
  }

  void _handle(dynamic event) {
    if (_muted) return;
    try {
      final msg = jsonDecode(event as String) as Map<String, dynamic>;
      if (msg['type'] == 'product_moved') {
        final mover = msg['movedByName'] as String?;
        addMoveNotification(
          serverId:    msg['notificationId'] as String?,
          productName: msg['productName']    as String?,
          fromRoom:    msg['fromRoom']        as String?,
          toRoom:      msg['toRoom']          as String?,
          body:        mover != null ? 'By $mover' : null,
        );
      } else if (msg['type'] == 'product_retired') {
        addRetiredNotification(
          serverId:    msg['notificationId'] as String?,
          productName: msg['productName']    as String?,
          body:        msg['body']           as String?,
        );
      } else if (msg['type'] == 'iot_scan') {
        addIotScanNotification(
          productName: msg['product_name'] as String?,
          fromRoom:    msg['from_room']    as String?,
          toRoom:      msg['room_name']    as String?,
          scanType:    msg['scan_type']    as String? ?? 'rfid',
          readerId:    msg['reader_id']    as String?,
        );
      }
    } catch (_) {}
  }

  void addMoveNotification({
    String? serverId,
    String? productName,
    String? fromRoom,
    String? toRoom,
    String? body,
  }) {
    if (serverId != null && _notifications.any((n) => n.serverId == serverId)) return;

    final n = AppNotification(
      id:          serverId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      serverId:    serverId,
      type:        'product_moved',
      title:       'Déplacement effectué',
      body:        body ?? '',
      productName: productName,
      fromRoom:    fromRoom,
      toRoom:      toRoom,
      createdAt:   DateTime.now(),
    );
    _notifications.insert(0, n);
    notifyListeners();
  }

  void addRetiredNotification({
    String? serverId,
    String? productName,
    String? body,
  }) {
    if (serverId != null && _notifications.any((n) => n.serverId == serverId)) return;

    final n = AppNotification(
      id:          serverId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      serverId:    serverId,
      type:        'product_retired',
      title:       'Équipement réformé',
      body:        body ?? '',
      productName: productName,
      createdAt:   DateTime.now(),
    );
    _notifications.insert(0, n);
    notifyListeners();
  }

  void addIotScanNotification({
    String? productName,
    String? fromRoom,
    String? toRoom,
    String scanType = 'rfid',
    String? readerId,
  }) {
    final label = scanType == 'ble' ? 'BLE' : 'RFID';
    final n = AppNotification(
      id:          DateTime.now().microsecondsSinceEpoch.toString(),
      type:        'iot_$scanType',
      title:       'Détecté via $label',
      body:        readerId != null ? 'Lecteur : $readerId' : '',
      productName: productName,
      fromRoom:    fromRoom,
      toRoom:      toRoom,
      createdAt:   DateTime.now(),
    );
    _notifications.insert(0, n);
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _notifications) n.isRead = true;
    notifyListeners();
    ApiService.markAllNotificationsRead().catchError((_) {});
  }

  void markRead(String id) {
    final n = _notifications.where((x) => x.id == id).firstOrNull;
    if (n != null && !n.isRead) {
      n.isRead = true;
      notifyListeners();
      if (n.serverId != null) {
        ApiService.markNotificationRead(n.serverId!).catchError((_) {});
      }
    }
  }

  void remove(String id) {
    final n = _notifications.where((x) => x.id == id).firstOrNull;
    if (n == null) return;
    _notifications.remove(n);
    notifyListeners();
    if (n.serverId != null) {
      ApiService.deleteNotification(n.serverId!).catchError((_) {});
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
    ApiService.clearAllNotifications().catchError((_) {});
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}
