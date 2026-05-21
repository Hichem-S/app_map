import 'package:shared_preferences/shared_preferences.dart';

class TrackerSettings {
  static const _urlKey  = 'HAYSTACK_URL';
  static const _userKey = 'HAYSTACK_USER';
  static const _passKey = 'HAYSTACK_PASS';
  static const _daysKey = 'HAYSTACK_DAYS';

  static Future<String> getUrl() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_urlKey) ?? 'http://localhost:6176';
  }

  static Future<String> getUser() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_userKey) ?? '';
  }

  static Future<String> getPass() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_passKey) ?? '';
  }

  static Future<int> getDays() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_daysKey) ?? 7;
  }

  static Future<void> save({
    String? url,
    String? user,
    String? pass,
    int? days,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (url  != null) await p.setString(_urlKey,  url);
    if (user != null) await p.setString(_userKey, user);
    if (pass != null) await p.setString(_passKey, pass);
    if (days != null) await p.setInt(_daysKey,    days);
  }
}
