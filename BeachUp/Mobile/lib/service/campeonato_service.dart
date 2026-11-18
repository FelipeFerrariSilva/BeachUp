import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/config/api_config.dart';

class CampeonatoService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/campeonatos';

  static String _extrairErro(dynamic body, String fallback) {
    if (body is Map) {
      final msg =
          (body['message'] ?? body['erro'] ?? body['error'] ?? fallback)
              .toString();
      final corte = msg.indexOf('. Faca');
      return corte != -1 ? msg.substring(0, corte) : msg;
    }
    return fallback;
  }


  static Future<Map<String, dynamic>> criar({
    required String nome,
    required String descricao,
    required String categoria,
    required String dataInicio,
    required String dataFim,
    required int arenaId,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'nome': nome,
              'descricao': descricao,
              'categoria': categoria,
              'dataInicio': dataInicio,
              'dataFim': dataFim,
              'arenaId': arenaId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'sucesso': true, 'dados': body};
      }
      return {
        'sucesso': false,
        'erro': _extrairErro(body, 'Erro ao criar campeonato'),
      };
    } catch (e) {
      return {'sucesso': false, 'erro': 'Sem conexão com o servidor'};
    }
  }

  static Future<List<dynamic>> listarTodos() async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse(_baseUrl),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    debugPrint(
        '[CampeonatoService.listarTodos] status: ${response.statusCode}');
    debugPrint('[CampeonatoService.listarTodos] body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
        'Erro ${response.statusCode} ao listar campeonatos: ${response.body}');
  }

  static Future<List<dynamic>> listarMeus() async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse('$_baseUrl/meus'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    debugPrint(
        '[CampeonatoService.listarMeus] status: ${response.statusCode}');
    debugPrint('[CampeonatoService.listarMeus] body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
        'Erro ${response.statusCode} ao listar meus campeonatos: ${response.body}');
  }

  static Future<Map<String, dynamic>> buscarPorId(int id) async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse('$_baseUrl/$id'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erro ao buscar campeonato $id');
  }

  static Future<List<dynamic>> listarPartidas(int campeonatoId) async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse('$_baseUrl/$campeonatoId/partidas'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
        'Erro ao listar partidas do campeonato $campeonatoId');
  }

  static Future<Map<String, dynamic>> registrarResultado({
    required int partidaId,
    required int placarTimeCasa,
    required int placarTimeVisitante,
    required String token,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/partidas/$partidaId/resultado'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'placarTimeCasa': placarTimeCasa,
              'placarTimeVisitante': placarTimeVisitante,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {'sucesso': true, 'dados': jsonDecode(response.body)};
      }
      final body = jsonDecode(response.body);
      return {
        'sucesso': false,
        'erro': _extrairErro(body, 'Erro ao registrar resultado'),
      };
    } catch (e) {
      return {'sucesso': false, 'erro': 'Sem conexão com o servidor'};
    }
  }

  static Future<Map<String, dynamic>> iniciar({
    required int campeonatoId,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/$campeonatoId/iniciar'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {'sucesso': true, 'partidas': jsonDecode(response.body)};
      }
      final body = jsonDecode(response.body);
      return {
        'sucesso': false,
        'erro': _extrairErro(body, 'Erro ao iniciar campeonato'),
      };
    } catch (e) {
      return {'sucesso': false, 'erro': 'Sem conexão com o servidor'};
    }
  }
}