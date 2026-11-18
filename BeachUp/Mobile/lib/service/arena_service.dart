import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/model/arena.dart';
import 'package:flutter_application_1/service/auth_service.dart';

class ArenaService {
  static Future<List<Arena>> getAll() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/arenas'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((e) => Arena.fromJson(e)).toList();
    }
    throw Exception('Erro ao buscar arenas: ${response.statusCode}');
  }

  static Future<List<Arena>> getMinhas() async {
    final token = await AuthService.getToken();
    debugPrint('[ArenaService.getMinhas] TOKEN: $token');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/arenas/minhas'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((e) => Arena.fromJson(e)).toList();
    }
    throw Exception('Erro ao buscar suas arenas: ${response.statusCode}');
  }

  static Future<List<Arena>> buscarPorProximidade({
    required double latitude,
    required double longitude,
    double raioKm = 10.0,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/arenas/proximidade'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'latitude': latitude, 'longitude': longitude, 'raioKm': raioKm}),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((e) => Arena.fromJson(e)).toList();
    }
    throw Exception('Erro ao buscar por proximidade: ${response.statusCode}');
  }

  static Future<Arena> criar({
    required String nome,
    required String descricao,
    required String logradouro,
    required String numero,
    required String bairro,
    required String cidade,
    required String estado,
    required String cep,
    XFile? foto,
  }) async {
    final token = await AuthService.getToken();
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/arenas'))
      ..headers['Authorization'] = 'Bearer $token';

    request.files.add(http.MultipartFile.fromString(
      'dados',
      jsonEncode({
        'nome': nome,
        'descricao': descricao,
        'endereco': {
          'logradouro': logradouro,
          'numero': numero,
          'bairro': bairro,
          'cidade': cidade,
          'estado': estado,
          'cep': cep,
        },
      }),
      contentType: MediaType('application', 'json'),
    ));

    if (foto != null) {
      final bytes = await foto.readAsBytes();
      final ext = foto.path.split('.').last.toLowerCase();
      request.files.add(http.MultipartFile.fromBytes(
        'foto',
        bytes,
        filename: foto.name,
        contentType: MediaType('image', ext == 'jpg' ? 'jpeg' : ext),
      ));
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Arena.fromJson(jsonDecode(response.body));
    }
    throw Exception(_erroMsg(response.body));
  }

  static Future<Arena> editar({
    required int id,
    required String nome,
    required String descricao,
    required String logradouro,
    required String numero,
    required String bairro,
    required String cidade,
    required String estado,
    required String cep,
    XFile? foto,
  }) async {
    final token = await AuthService.getToken();
    final request = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.baseUrl}/arenas/$id'))
      ..headers['Authorization'] = 'Bearer $token';

    request.files.add(http.MultipartFile.fromString(
      'dados',
      jsonEncode({
        'nome': nome,
        'descricao': descricao,
        'endereco': {
          'logradouro': logradouro,
          'numero': numero,
          'bairro': bairro,
          'cidade': cidade,
          'estado': estado,
          'cep': cep,
        },
      }),
      contentType: MediaType('application', 'json'),
    ));

    if (foto != null) {
      final bytes = await foto.readAsBytes();
      final ext = foto.path.split('.').last.toLowerCase();
      request.files.add(http.MultipartFile.fromBytes(
        'foto',
        bytes,
        filename: foto.name,
        contentType: MediaType('image', ext == 'jpg' ? 'jpeg' : ext),
      ));
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      return Arena.fromJson(jsonDecode(response.body));
    }
    throw Exception(_erroMsg(response.body));
  }

  static Future<void> excluir(int id) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/arenas/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(_erroMsg(response.body));
    }
  }

  static String _erroMsg(String body) {
    try {
      final j = jsonDecode(body);
      return j['message'] ?? j['error'] ?? body;
    } catch (_) {
      return body.isNotEmpty ? body : 'Erro desconhecido';
    }
  }
}