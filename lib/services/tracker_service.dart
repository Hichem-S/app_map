import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tracker.dart';

class TrackerService {
  // Default API endpoint - configured for user's PC
  static String _baseUrl = 'http://192.168.31.23:6176';

  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  static String get baseUrl => _baseUrl;

  /// Fetch all trackers from the Macless-Haystack API
  static Future<List<Tracker>> getTrackers() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/trackers'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Tracker.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trackers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to tracker API: $e');
    }
  }

  /// Fetch location reports for a specific tracker
  static Future<List<Map<String, dynamic>>> getTrackerReports(
      String trackerId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/trackers/$trackerId/reports'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load reports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to tracker API: $e');
    }
  }

  /// Get the main endpoint status
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/'),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
