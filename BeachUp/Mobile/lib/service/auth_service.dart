import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/model/usuario.dart';

class AuthService {
  static Future<String?>? _refreshEmAndamento;

  static Future<bool> login(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': senha}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['accessToken'];
        final String? refreshToken = data['refreshToken'];

        final parts = token.split('.');
        final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])),
        );
        final payloadMap = jsonDecode(payload);
        final String role = payloadMap['role'];

        await _salvarToken(token);
        await _salvarRole(role);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('refreshToken', refreshToken);
        }

        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Erro no login: $e');
      return false;
    }
  }

  static Future<Usuario?> getUsuarioLogado() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payloadMap = jsonDecode(payload);

      return Usuario(email: payloadMap['sub'], role: payloadMap['role']);
    } catch (e) {
      debugPrint('Erro ao ler token: $e');
      return null;
    }
  }

  static Future<void> _salvarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> salvarToken(String accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString('refreshToken', refreshToken);
    }
    try {
      final parts = accessToken.split('.');
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final role = (jsonDecode(payload) as Map)['role'] as String?;
      if (role != null) await prefs.setString('role', role);
    } catch (_) {}
  }

  static Future<void> _salvarRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    if (!_estaExpirado(token)) return token;

    return _renovarToken();
  }

  static bool _estaExpirado(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return true;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is! int) return false; 
      final expiraEm = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiraEm.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }

  static Future<String?> _renovarToken() async {
    if (_refreshEmAndamento != null) return _refreshEmAndamento;

    _refreshEmAndamento = _executarRenovacao();
    try {
      return await _refreshEmAndamento;
    } finally {
      _refreshEmAndamento = null;
    }
  }

  static Future<String?> _executarRenovacao() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      await logout();
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String novoAccessToken = data['accessToken'];
        final String? novoRefreshToken = data['refreshToken'];
        await salvarToken(novoAccessToken, novoRefreshToken);
        return novoAccessToken;
      } else {
        await logout();
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao renovar token: $e');
      return prefs.getString('token');
    }
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('refreshToken');
    await prefs.remove('user_foto_url');
  }

  static Future<bool> estaLogado() async {
    final token = await getToken();
    return token != null;
  }
}