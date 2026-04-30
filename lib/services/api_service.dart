import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://172.20.10.5:3000/api';

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
      String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
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
      body: jsonEncode({'name': name, 'device_type': type, 'mqtt_topic': topic}),
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
    int page = 1,
    int limit = 20,
  }) async {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null) 'type': type,
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
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'webp': return 'image/webp';
      default:     return 'image/jpeg';
    }
  }

  static Future<void> _attachPhoto(http.MultipartRequest request, XFile photo) async {
    final bytes = await photo.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      bytes,
      filename: photo.name,
      contentType: _mediaType(photo),
    ));
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
    XFile? photo,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/products'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    if (sku != null) request.fields['sku'] = sku;
    if (type != null) request.fields['type'] = type;
    if (barcode != null) request.fields['barcode'] = barcode;
    if (description != null) request.fields['description'] = description;
    if (tags != null) request.fields['tags'] = jsonEncode(tags);
    request.fields['quantity'] = quantity.toString();
    if (price != null) request.fields['price'] = price.toString();
    if (storageLocation != null) request.fields['storage_location'] = storageLocation;
    if (photo != null) await _attachPhoto(request, photo);

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
    XFile? photo,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/products/$id'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    if (sku != null) request.fields['sku'] = sku;
    if (type != null) request.fields['type'] = type;
    if (barcode != null) request.fields['barcode'] = barcode;
    if (description != null) request.fields['description'] = description;
    if (tags != null) request.fields['tags'] = jsonEncode(tags);
    if (quantity != null) request.fields['quantity'] = quantity.toString();
    if (price != null) request.fields['price'] = price.toString();
    if (storageLocation != null) request.fields['storage_location'] = storageLocation;
    if (photo != null) await _attachPhoto(request, photo);

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> deleteProduct(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Returns the QR image URL for display in the app
  static String productQrUrl(String id) => '$baseUrl/products/$id/qr';

  // ─── Scan history ─────────────────────────────────────────────────────────────

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
    return data['success'] == true ? data['data'] as Map<String, dynamic> : null;
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

  static Future<void> addScanHistory(String productId) async {
    await http.post(
      Uri.parse('$baseUrl/products/scan-history'),
      headers: await _authHeaders(),
      body: jsonEncode({'product_id': productId}),
    );
  }
}
