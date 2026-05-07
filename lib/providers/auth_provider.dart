import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  String get role => _user?['role'] as String? ?? 'technicien';

  bool get isAdmin      => role == 'admin';
  bool get isMagazinier => role == 'magazinier';
  bool get isTechnicien => role == 'technicien' || role == 'user';

  /// Can add products (all roles)
  bool get canAddProduct => true;

  /// Can place/unplace equipment on map, view maps & departments
  bool get canViewMaps => isAdmin || isMagazinier;

  /// Can access user management
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
