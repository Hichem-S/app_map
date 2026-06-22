import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  String get role => _user?['role'] as String? ?? 'technicien';

  bool get isAdmin      => role == 'admin';
  bool get isMagazinier => role == 'magazinier';
  bool get isTechnicien => role == 'technicien' || role == 'user';

  /// Only magazinier physically adds stock
  bool get canAddProduct    => isMagazinier;

  /// Admin + magazinier can edit; only magazinier can delete
  bool get canEditProduct   => isAdmin || isMagazinier;
  bool get canDeleteProduct => isMagazinier;
  bool get canChangeStatus  => isAdmin || isTechnicien;

  /// Admin + technicien see 2D/3D maps and can place equipment
  bool get canViewMaps => isAdmin || isTechnicien;

  /// Reports tab visible to admin + technicien; hidden for magazinier
  bool get canViewReports => isAdmin || isTechnicien;

  /// IoT features — RFID, BLE, tracker, move log, maintenance (blocked for magazinier)
  bool get canViewIoT         => isAdmin || isTechnicien;
  bool get canViewTracker     => isAdmin || isTechnicien;
  bool get canViewMaintenance => isAdmin || isTechnicien;
  bool get canViewMoveLog     => isAdmin || isTechnicien;

  /// User management — admin only
  bool get canManageUsers => isAdmin;

  String get displayRole {
    switch (role) {
      case 'admin':        return 'Administrateur';
      case 'magazinier':   return 'Magazinier';
      case 'technicien':   return 'Technicien';
      default:             return role;
    }
  }

  Future<void> loadUser() async {
    try {
      final res = await ApiService.getMe();
      if (res['success'] == true) {
        _user = res['data'] as Map<String, dynamic>;
        notifyListeners();
      }
    } catch (_) {}
  }

  void setUser(Map<String, dynamic> u) {
    _user = u;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
