import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ReportsFetcher {
  static final _log = Logger(printer: PrettyPrinter(methodCount: 0));

  static Future<List> fetchLocationReports(
    Iterable<String> hashedKeys,
    int daysToFetch,
    String url,
    String user,
    String pass,
  ) async {
    final keys = hashedKeys.toList(growable: false);
    _log.i('Requesting ${keys.length} key(s) from $url');

    String? credentials;
    if (user.trim().isNotEmpty || pass.trim().isNotEmpty) {
      credentials = 'Basic ${base64.encode(utf8.encode("$user:$pass"))}';
    }

    final body = jsonEncode({'ids': keys, 'days': daysToFetch});

    if (kIsWeb) {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (credentials != null) headers['Authorization'] = credentials;

      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 401) throw Exception('Authentication failure');
      if (response.statusCode == 200) {
        final out = jsonDecode(response.body)['results'] as List;
        _log.i('Found ${out.length} reports');
        return out;
      }
      throw Exception('Failed: ${response.statusCode}');
    } else {
      final httpClient = HttpClient()
        ..badCertificateCallback = (_, __, ___) => true;

      final request = await httpClient.postUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (credentials != null) {
        request.headers.set(HttpHeaders.authorizationHeader, credentials);
      }
      request.headers.set(HttpHeaders.contentLengthHeader, utf8.encode(body).length);
      request.write(body);

      final response = await request.close();
      if (response.statusCode == 401) throw Exception('Authentication failure');
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final out = jsonDecode(responseBody)['results'] as List;
        _log.i('Found ${out.length} reports');
        return out;
      }
      throw Exception('Failed: ${response.statusCode}');
    }
  }
}
