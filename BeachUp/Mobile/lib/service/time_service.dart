import 'dart:convert';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/model/time.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:http/http.dart' as http;

class TimeService {
  Future<List<TimeModel>> getTimes() async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    int? idJogadorLogado;
    try {
      final meRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/jogador/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (meRes.statusCode == 200) {
        idJogadorLogado = jsonDecode(meRes.body)['id'] as int?;
      }
    } catch (_) {}

    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/times'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Erro ao buscar times: ${res.statusCode}');
    }

    final todos = (jsonDecode(res.body) as List)
        .map((e) => TimeModel.fromBackendJson(e))
        .toList();

    if (idJogadorLogado == null) return todos;

    return todos.where((t) {
      if (t.idJogadorDono == idJogadorLogado) return true;
      return t.membros.any((m) =>
          m.idJogador == idJogadorLogado &&
          m.status.toUpperCase() == 'ACEITO');
    }).toList();
  }

  static Future<TimeModel> criar({
    required String nome,
    String? descricao,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/times'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        if (descricao != null) 'descricao': descricao,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TimeModel.fromBackendJson(jsonDecode(response.body));
    }
    throw Exception(_extrairErro(response.body));
  }

  static Future<TimeModel> editar({
    required int timeId,
    required String nome,
    String? descricao,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/times/$timeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': nome,
        if (descricao != null) 'descricao': descricao,
      }),
    );
    if (response.statusCode == 200) {
      return TimeModel.fromBackendJson(jsonDecode(response.body));
    }
    throw Exception(_extrairErro(response.body));
  }

  static Future<void> excluir(int timeId) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/times/$timeId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extrairErro(response.body));
    }
  }

  static Future<void> removerMembro(int timeId, int jogadorId) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/times/$timeId/membros/$jogadorId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extrairErro(response.body));
    }
  }

  static Future<String> regerarConvite(int timeId) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/times/$timeId/convite/regenar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return response.body.trim().replaceAll('"', '');
    }
    throw Exception(_extrairErro(response.body));
  }

  static Future<TimeModel> entrarPorToken(String tokenConvite) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/times/entrar/$tokenConvite'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TimeModel.fromBackendJson(jsonDecode(response.body));
    }
    throw Exception(_extrairErro(response.body));
  }

  static Future<TimeModel> buscarPorId(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/times/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return TimeModel.fromBackendJson(jsonDecode(response.body));
    }
    throw Exception('Time não encontrado');
  }

  static String _extrairErro(String body) {
    try {
      final json = jsonDecode(body);
      return json['message'] ?? json['error'] ?? body;
    } catch (_) {
      return body.isNotEmpty ? body : 'Erro desconhecido';
    }
  }
}