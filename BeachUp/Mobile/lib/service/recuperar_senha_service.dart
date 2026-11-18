import 'dart:convert';
import 'package:http/http.dart' as http;

class RecuperarSenhaService {
  static const String _baseUrl = 'https://beachup-production.up.railway.app/auth';

  static Future<String?> solicitarReset({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/esqueceu-senha'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return null; 
      return _extrairMensagem(response.body);
    } catch (e) {
      return 'Sem conexão com o servidor';
    }
  }

  static Future<String?> redefinirSenha({
    required String token,
    required String novaSenha,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/redefinir-senha'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'novaSenha': novaSenha}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return null;
      return _extrairMensagem(response.body);
    } catch (e) {
      return 'Sem conexão com o servidor';
    }
  }

  static String _extrairMensagem(String body) {
    try {
      final json = jsonDecode(body);
      return json['mensagem'] ?? json['message'] ?? json['error'] ?? 'Erro ao processar solicitação';
    } catch (_) {
      return body.isNotEmpty ? body : 'Erro ao processar solicitação';
    }
  }
}