import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/download_helper.dart';

class ApiService {
  static const String baseUrl = 'http://172.20.10.6:3000/api';

  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ─── Token storage ──────────────────────────────────────────────────────────

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register(
      String name, String email, String password,
      {String role = 'technicien'}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'name': name, 'email': email, 'password': password, 'role': role}),
    );
    // No tokens returned until email is verified
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      await saveTokens(
        data['data']['accessToken'],
        data['data']['refreshToken'],
      );
    }
    return data;
  }

  static Future<Map<String, dynamic>> verifyEmail(
      String email, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      await saveTokens(
        data['data']['accessToken'],
        data['data']['refreshToken'],
      );
    }
    return data;
  }

  static Future<Map<String, dynamic>> resendVerification(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body:
          jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<String?> getGoogleIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  static Future<Map<String, dynamic>> googleAuth(String idToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      await saveTokens(
        data['data']['accessToken'],
        data['data']['refreshToken'],
      );
    }
    return data;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadAvatar(XFile file) async {
    final token = await getToken();
    final req = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/auth/profile'),
    );
    req.headers['Authorization'] = 'Bearer $token';
    final bytes = await file.readAsBytes();
    req.files.add(http.MultipartFile.fromBytes(
      'avatar',
      bytes,
      filename: file.name,
      contentType: _mediaType(file),
    ));
    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  static String avatarUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${baseUrl.replaceAll('/api', '')}$path';
  }

  // ─── Admin user management ───────────────────────────────────────────────────

  static Future<List<dynamic>> getUsers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/users'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>?) ?? [];
  }

  static Future<Map<String, dynamic>> updateUserRole(
      String userId, String role) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/auth/users/$userId/role'),
      headers: await _authHeaders(),
      body: jsonEncode({'role': role}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> toggleUserStatus(String userId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/auth/users/$userId/status'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/auth/users/$userId'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createUser(
      String name, String email, String password, String role) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/users'),
      headers: await _authHeaders(),
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': role}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    await clearTokens();
    await _googleSignIn.signOut();
  }

  // ─── Devices ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDevices() async {
    final res = await http.get(
      Uri.parse('$baseUrl/devices'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createDevice(
      String name, String type, String topic) async {
    final res = await http.post(
      Uri.parse('$baseUrl/devices'),
      headers: await _authHeaders(),
      body:
          jsonEncode({'name': name, 'device_type': type, 'mqtt_topic': topic}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Categories ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getCategories() async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/categories'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Products ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProducts({
    String? search,
    String? type,
    String? status,
    String? roomId,
    String? department,
    int page = 1,
    int limit = 20,
  }) async {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (roomId != null) 'room_id': roomId,
      if (department != null) 'department': department,
    };
    final res = await http.get(
      Uri.parse('$baseUrl/products').replace(queryParameters: params),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getProduct(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Called after scanning a QR code — no auth required
  static Future<Map<String, dynamic>> getProductByQR(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/scan?id=$id'),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static MediaType _mediaType(XFile photo) {
    final mime = photo.mimeType ?? _mimeFromName(photo.name);
    final parts = mime.split('/');
    return MediaType(parts[0], parts.length > 1 ? parts[1] : 'jpeg');
  }

  static String _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static Future<void> _attachPhoto(http.MultipartRequest request, XFile photo,
      [Uint8List? preReadBytes]) async {
    final bytes = preReadBytes ?? await photo.readAsBytes();
    final filename =
        photo.name.contains('/') ? photo.name.split('/').last : photo.name;
    final ct = _mediaType(photo);
    debugPrint(
        '[ATTACH_PHOTO] bytes=${bytes.length} filename=$filename contentType=$ct');
    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      bytes,
      filename: filename.isEmpty ? 'photo.jpg' : filename,
      contentType: ct,
    ));
  }

  static Future<Map<String, dynamic>> updateProductLocation(String id,
      {String? roomId}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/products/$id/location'),
      headers: await _authHeaders(),
      body: jsonEncode({'room_id': roomId}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static String get _baseHost => baseUrl.replaceAll('/api', '');

  static String isetQrUrl() => '$_baseHost/api/departments/qr/iset';
  static String departmentQrUrl(String deptId) =>
      '$_baseHost/api/departments/$deptId/qr';
  static String departmentQrUrlByCode(String code) =>
      '$_baseHost/api/departments/code/$code/qr';
  static String roomQrUrl(String roomId) =>
      '$_baseHost/api/departments/rooms/$roomId/qr';

  static Future<List<dynamic>> getDepartments() async {
    final res = await http.get(
      Uri.parse('$baseUrl/departments'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>?) ?? [];
  }

  static Future<List<dynamic>> getMapData() async {
    final res = await http.get(
      Uri.parse('$baseUrl/departments/map-data'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>?) ?? [];
  }

  static Future<List<dynamic>> getDepartmentRooms(String departmentId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/departments/$departmentId/rooms'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>?) ?? [];
  }

  static Future<Map<String, dynamic>> updateRoom(
    String roomId, {
    String? name,
    String? type,
    String? roomCode,
    String? bloc,
    String? floor,
    int? capacity,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/departments/rooms/$roomId'),
      headers: await _authHeaders(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (type != null) 'type': type,
        'room_code': roomCode,
        'bloc': bloc,
        'floor': floor,
        'capacity': capacity,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getDepartmentRoomsByCode(String code) async {
    final res = await http.get(
      Uri.parse('$baseUrl/departments/code/$code/rooms'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>?) ?? [];
  }

  static Future<Map<String, dynamic>> checkBarcode(String barcode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/barcode-check')
          .replace(queryParameters: {'barcode': barcode}),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createProduct({
    required String name,
    String? sku,
    String? type,
    String? barcode,
    String? description,
    List<String>? tags,
    int quantity = 0,
    double? price,
    String? storageLocation,
    String? roomId,
    XFile? photo,
    Uint8List? photoBytes,
    Map<String, dynamic>? specifications,
  }) async {
    final token = await getToken();
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/products'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    if (sku != null) request.fields['sku'] = sku;
    if (type != null) request.fields['type'] = type;
    if (barcode != null) request.fields['barcode'] = barcode;
    if (description != null) request.fields['description'] = description;
    if (tags != null) request.fields['tags'] = jsonEncode(tags);
    request.fields['quantity'] = quantity.toString();
    if (price != null) request.fields['price'] = price.toString();
    if (storageLocation != null)
      request.fields['storage_location'] = storageLocation;
    if (roomId != null) request.fields['room_id'] = roomId;
    if (specifications != null && specifications.isNotEmpty) {
      request.fields['specifications'] = jsonEncode(specifications);
    }
    if (photo != null) await _attachPhoto(request, photo, photoBytes);

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProduct(
    String id, {
    required String name,
    String? sku,
    String? type,
    String? barcode,
    String? description,
    List<String>? tags,
    int? quantity,
    double? price,
    String? storageLocation,
    String? roomId,
    XFile? photo,
    Uint8List? photoBytes,
    Map<String, dynamic>? specifications,
  }) async {
    final token = await getToken();
    final request =
        http.MultipartRequest('PUT', Uri.parse('$baseUrl/products/$id'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    if (sku != null) request.fields['sku'] = sku;
    if (type != null) request.fields['type'] = type;
    if (barcode != null) request.fields['barcode'] = barcode;
    if (description != null) request.fields['description'] = description;
    if (tags != null) request.fields['tags'] = jsonEncode(tags);
    if (quantity != null) request.fields['quantity'] = quantity.toString();
    if (price != null) request.fields['price'] = price.toString();
    if (storageLocation != null)
      request.fields['storage_location'] = storageLocation;
    if (roomId != null) request.fields['room_id'] = roomId;
    if (specifications != null && specifications.isNotEmpty) {
      request.fields['specifications'] = jsonEncode(specifications);
    }
    if (photo != null) await _attachPhoto(request, photo, photoBytes);

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProductStatus(
      String id, String status) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/products/$id/status'),
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> deleteProduct(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Returns the QR image URL — uses saved static file if available, else dynamic endpoint
  static String productQrUrl(String id, {String? qrImageUrl}) {
    if (qrImageUrl != null && qrImageUrl.isNotEmpty) {
      final baseHost = baseUrl.replaceAll('/api', '');
      return '$baseHost$qrImageUrl';
    }
    return '$baseUrl/products/$id/qr';
  }

  // ─── Scan history ─────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getMoveLog() async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/move-log'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>?) ?? [];
  }

  static Future<List<dynamic>> getScanHistory() async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/scan-history'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>?) ?? [];
  }

  static Future<Map<String, dynamic>?> getStats() async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/stats'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['success'] == true
        ? data['data'] as Map<String, dynamic>
        : null;
  }

  static Future<List<dynamic>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await http.get(
      Uri.parse('$baseUrl/products')
          .replace(queryParameters: {'search': query.trim(), 'limit': '8'}),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) return [];
    return (data['data'] as List<dynamic>?) ?? [];
  }

  static Future<void> addScanHistory(String productId,
      {String actionType = 'scan'}) async {
    await http.post(
      Uri.parse('$baseUrl/products/scan-history'),
      headers: await _authHeaders(),
      body: jsonEncode({'product_id': productId, 'action_type': actionType}),
    );
  }

  static Future<void> addDeptQrHistory(String code, String name) async {
    await http.post(
      Uri.parse('$baseUrl/products/scan-history'),
      headers: await _authHeaders(),
      body: jsonEncode({'department_code': code, 'department_name': name}),
    );
  }

  /// Downloads the department QR PNG and saves it to the device / triggers
  /// a browser download on web. Returns the filename/path on success, null on failure.
  static Future<String?> saveDeptQrToGallery(String code, String name) async {
    try {
      final res = await http.get(Uri.parse(departmentQrUrlByCode(code)));
      if (res.statusCode != 200) {
        debugPrint('QR fetch failed: ${res.statusCode}');
        return null;
      }
      final filename = 'qr_dept_${code.toLowerCase()}.png';
      return await downloadFileLocally(res.bodyBytes, filename);
    } catch (e, st) {
      debugPrint('saveDeptQrToGallery error: $e\n$st');
      return null;
    }
  }

  static Future<String?> saveRoomQrLocally(
      String roomId, String roomName) async {
    try {
      final res = await http.get(Uri.parse(roomQrUrl(roomId)));
      if (res.statusCode != 200) return null;
      final safe =
          roomName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      return await downloadFileLocally(res.bodyBytes, 'qr_room_$safe.png');
    } catch (e, st) {
      debugPrint('saveRoomQrLocally error: $e\n$st');
      return null;
    }
  }

  // ─── PDF reports ─────────────────────────────────────────────────────────────

  static Future<String?> _downloadAuthFile(String url, String filename) async {
    try {
      final res = await http.get(Uri.parse(url), headers: await _authHeaders());
      if (res.statusCode != 200) return null;
      return await downloadFileLocally(res.bodyBytes, filename);
    } catch (e, st) {
      debugPrint('_downloadAuthFile error: $e\n$st');
      return null;
    }
  }

  static Future<String?> downloadRoomFiche(String roomId, String roomName) {
    final safe =
        roomName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    return _downloadAuthFile(
        '$baseUrl/reports/rooms/$roomId/fiche', 'fiche_$safe.pdf');
  }

  static Future<String?> downloadRoomJournal(String roomId, String roomName) {
    final safe =
        roomName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    return _downloadAuthFile(
        '$baseUrl/reports/rooms/$roomId/journal', 'journal_$safe.pdf');
  }

  // ─── Notifications ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final res = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _authHeaders(),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['data'] as List? ?? []);
  }

  static Future<void> markNotificationRead(String id) async {
    await http.patch(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: await _authHeaders(),
    );
  }

  static Future<void> markAllNotificationsRead() async {
    await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: await _authHeaders(),
    );
  }

  static Future<void> deleteNotification(String id) async {
    await http.delete(
      Uri.parse('$baseUrl/notifications/$id'),
      headers: await _authHeaders(),
    );
  }

  static Future<void> clearAllNotifications() async {
    await http.delete(
      Uri.parse('$baseUrl/notifications'),
      headers: await _authHeaders(),
    );
  }
}
