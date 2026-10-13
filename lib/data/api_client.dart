import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.errors]);

  final String message;
  final Object? errors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final instance = ApiClient._();
  static const _baseUrlKey = 'carego_api_base_url';

  // HP fisik dan komputer harus berada pada Wi-Fi yang sama.
  static const defaultBaseUrl = String.fromEnvironment(
    'CAREGO_API_URL',
    defaultValue: 'http://192.168.18.81:8000/api/v1',
  );
  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  String? token;
  static const requestTimeout = Duration(seconds: 25);
  static const _usbDebugBaseUrl = 'http://127.0.0.1:8000/api/v1';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_baseUrlKey);
    _baseUrl = _normalizeBaseUrl(saved) ?? defaultBaseUrl;
  }

  Future<void> saveBaseUrl(String value) async {
    final normalized = _normalizeBaseUrl(value);
    if (normalized == null) {
      throw const ApiException('Alamat API tidak valid.');
    }
    _baseUrl = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);
  }

  static String? _normalizeBaseUrl(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    var normalized = raw;
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    normalized = normalized.replaceAll(RegExp(r'/+$'), '');
    if (!normalized.contains('/api/v1')) {
      normalized = '$normalized/api/v1';
    }
    return Uri.tryParse(normalized)?.hasAuthority == true ? normalized : null;
  }

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _send('PATCH', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final urls = <String>[
      baseUrl,
      if (baseUrl != _usbDebugBaseUrl) _usbDebugBaseUrl,
    ];

    http.Response? response;
    Map<String, dynamic>? decoded;
    Object? lastError;
    for (final url in urls) {
      try {
        response = await _sendOnce(url, method, path, headers, body);
        decoded = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body) as Map<String, dynamic>;
        break;
      } catch (error) {
        lastError = error;
      }
    }

    if (response == null || decoded == null) {
      if (lastError is TimeoutException) {
        throw const ApiException(
          'Server tidak merespons. Periksa alamat API dan koneksi Wi-Fi.',
        );
      }
      throw const ApiException(
        'Tidak dapat terhubung ke server. Pastikan Laravel aktif dan HP berada di Wi-Fi yang sama.',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['success'] == false) {
      throw ApiException(
        decoded['message'] as String? ?? 'Permintaan gagal.',
        decoded['errors'],
      );
    }
    return decoded['data'];
  }

  Future<http.Response> _sendOnce(
    String url,
    String method,
    String path,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    final uri = Uri.parse('$url$path');
    return (switch (method) {
      'GET' => http.get(uri, headers: headers),
      'POST' => http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
      'PATCH' =>
        http.patch(uri, headers: headers, body: jsonEncode(body ?? {})),
      'DELETE' => http.delete(uri, headers: headers),
      _ => throw UnsupportedError('HTTP method $method tidak didukung'),
    })
        .timeout(requestTimeout);
  }
}
