import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

/// Thrown when the backend rejects a request. [authRequired] is true for
/// 401/403 so callers can fall back to local cache / prompt re-login instead of
/// surfacing a hard error.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  bool get authRequired => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin authenticated wrapper around `http`. Every request carries the
/// Authentik Bearer token (the backend derives the owner from its `sub`), so the
/// frontend never sends or trusts an owner id itself.
class ApiClient {
  ApiClient({AuthService? authService, http.Client? httpClient})
    : _auth = authService ?? AuthService(),
      _http = httpClient ?? http.Client();

  final AuthService _auth;
  final http.Client _http;

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _auth.getAccessToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('$apiBaseUrl$path');

  Never _fail(http.Response r) =>
      throw ApiException(r.statusCode, r.body.isEmpty ? r.reasonPhrase ?? '' : r.body);

  Future<dynamic> getJson(String path) async {
    final r = await _http.get(_uri(path), headers: await _headers());
    if (r.statusCode == 200) return r.body.isEmpty ? null : jsonDecode(r.body);
    _fail(r);
  }

  Future<dynamic> postJson(String path, Object body) async {
    final r = await _http.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (r.statusCode == 200 || r.statusCode == 201) {
      return r.body.isEmpty ? null : jsonDecode(r.body);
    }
    _fail(r);
  }

  Future<dynamic> putJson(String path, Object body) async {
    final r = await _http.put(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (r.statusCode == 200 || r.statusCode == 201) {
      return r.body.isEmpty ? null : jsonDecode(r.body);
    }
    _fail(r);
  }

  Future<void> delete(String path) async {
    final r = await _http.delete(_uri(path), headers: await _headers());
    if (r.statusCode == 200 || r.statusCode == 204) return;
    _fail(r);
  }

  /// Raw bytes (used to download a saved board file from GridFS).
  Future<Uint8List> getBytes(String path) async {
    final r = await _http.get(_uri(path), headers: await _headers(json: false));
    if (r.statusCode == 200) return r.bodyBytes;
    _fail(r);
  }

  /// Multipart upload of a file plus simple string form fields.
  Future<dynamic> uploadFile(
    String path, {
    required String field,
    required String filename,
    required Uint8List bytes,
    Map<String, String> fields = const {},
    String? contentType,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(await _headers(json: false));
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(field, bytes, filename: filename),
    );
    final streamed = await _http.send(request);
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode == 200 || r.statusCode == 201) {
      return r.body.isEmpty ? null : jsonDecode(r.body);
    }
    _fail(r);
  }
}
