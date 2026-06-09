import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String clientId =
      'DkaB9fr83vOFhBoBBIJLOXBih1lBn1dM7meHEqIu';

  static const String redirectUrl = 'com.example.frontend://auth';

  static const String linuxRedirectUrl =
      'http://localhost:3000/callback';

  static const String issuer =
      'https://authentik.ismailmehmood.co.uk/application/o/drp-aac';

  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
  ];

  Future<bool> login() async {
    try {
      if (Platform.isLinux) {
        return await _loginLinux();
      }
      return await _loginMobile();
    } catch (e) {
      debugPrint('Auth login failed: $e');
      return false;
    }
  }

  // ------------------------------------------------------------
  // Mobile (Android / iOS / macOS)
  // ------------------------------------------------------------
  Future<bool> _loginMobile() async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        redirectUrl,
        discoveryUrl: '$issuer/.well-known/openid-configuration',
        scopes: scopes,
        promptValues: const ['login'],
      ),
    );

    if (result == null) return false;

    await _storeTokens(
      accessToken: result.accessToken,
      idToken: result.idToken,
      refreshToken: result.refreshToken,
    );

    return true;
  }

  // ------------------------------------------------------------
  // Linux (system browser + localhost callback)
  // ------------------------------------------------------------
  Future<bool> _loginLinux() async {
    final discoveryResponse = await http.get(
      Uri.parse('$issuer/.well-known/openid-configuration'),
    );

    if (discoveryResponse.statusCode != 200) {
      throw Exception(
        'Discovery failed: ${discoveryResponse.statusCode} ${discoveryResponse.body}',
      );
    }

    final discovery = jsonDecode(discoveryResponse.body);

    final authorizationEndpoint = discovery['authorization_endpoint'];
    final tokenEndpoint = discovery['token_endpoint'];

    // PKCE
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final authUrl = Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': linuxRedirectUrl,
        'response_type': 'code',
        'scope': scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'prompt': 'login',
      },
    );

    // 1. Start callback server BEFORE opening browser
    final server = await HttpServer.bind('localhost', 3000);

    // 2. Open browser
    await launchUrl(
      Uri.parse(authUrl.toString()),
      mode: LaunchMode.externalApplication,
    );

    // 3. Wait for redirect
    final request = await server.first;
    final uri = request.uri;

    request.response
      ..statusCode = 200
      ..headers.set('Content-Type', 'text/plain')
      ..write('Login complete. You can close this window.')
      ..close();

    await server.close();

    final code = uri.queryParameters['code'];

    if (code == null) return false;

    // 4. Exchange token
    final tokenResponse = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'code': code,
        'redirect_uri': linuxRedirectUrl,
        'code_verifier': codeVerifier,
      },
    );

    if (tokenResponse.statusCode != 200) {
      debugPrint(tokenResponse.body);
      return false;
    }

    final tokenJson = jsonDecode(tokenResponse.body);

    await _storeTokens(
      accessToken: tokenJson['access_token'],
      idToken: tokenJson['id_token'],
      refreshToken: tokenJson['refresh_token'],
    );

    return true;
  }

  // ------------------------------------------------------------
  // Storage
  // ------------------------------------------------------------
  Future<void> _storeTokens({
    String? accessToken,
    String? idToken,
    String? refreshToken,
  }) async {
    if (accessToken != null) {
      await _storage.write(key: 'access_token', value: accessToken);
    }
    if (idToken != null) {
      await _storage.write(key: 'id_token', value: idToken);
    }
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  // ------------------------------------------------------------
  // PKCE Helpers (fixed)
  // ------------------------------------------------------------
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (_) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = sha256.convert(utf8.encode(verifier)).bytes;
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  // ------------------------------------------------------------
  // Utils
  // ------------------------------------------------------------
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: 'access_token');

  Future<bool> isLoggedIn() async =>
      (await _storage.read(key: 'access_token')) != null;
}