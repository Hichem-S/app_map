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

  List<AppNotification> get all => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    _wsSub?.cancel();
    _wsSub = WsService.stream.listen(_handle, onError: (_) {});
    await loadFromApi();
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
    try {
      final msg = jsonDecode(event as String) as Map<String, dynamic>;
      if (msg['type'] == 'product_moved') {
        addMoveNotification(
          serverId:    msg['notificationId'] as String?,
          productName: msg['productName']    as String?,
          fromRoom:    msg['fromRoom']        as String?,
          toRoom:      msg['toRoom']          as String?,
        );
      }
    } catch (_) {}
  }

  void addMoveNotification({
    String? serverId,
    String? productName,
    String? fromRoom,
    String? toRoom,
  }) {
    if (serverId != null && _notifications.any((n) => n.serverId == serverId)) return;

    final n = AppNotification(
      id:          serverId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      serverId:    serverId,
      type:        'product_moved',
      title:       'Déplacement effectué',
      body:        '${productName ?? 'Équipement'} → ${toRoom ?? '—'}',
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
