import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/model/quadra.dart';
import 'package:flutter_application_1/service/auth_service.dart';

class QuadraService {
  static Future<List<Quadra>> getAll() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/quadras'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((e) => Quadra.fromJson(e)).toList();
    }
    throw Exception('Erro ao buscar quadras: ${response.statusCode}');
  }

  static Future<Quadra> getById(int id) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/quadras/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return Quadra.fromJson(jsonDecode(response.body));
    throw Exception('Quadra não encontrada');
  }

  static Future<List<Quadra>> getByArena(int arenaId) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/quadras/arena/$arenaId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((e) => Quadra.fromJson(e)).toList();
    }
    throw Exception('Erro ao buscar quadras da arena: ${response.statusCode}');
  }

  static Future<Quadra> criar({
    required int arenaId,
    required String nome,
    required String tipoCobertura,
    required double valorHora,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/quadras/$arenaId'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'nome': nome, 'tipoCobertura': tipoCobertura, 'valorHora': valorHora}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Quadra.fromJson(jsonDecode(response.body));
    }
    throw Exception(_erroMsg(response.body));
  }

  static Future<Quadra> editar({
    required int id,
    required String nome,
    required String tipoCobertura,
    required double valorHora,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/quadras/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'nome': nome, 'tipoCobertura': tipoCobertura, 'valorHora': valorHora}),
    );
    if (response.statusCode == 200) {
      return Quadra.fromJson(jsonDecode(response.body));
    }
    throw Exception(_erroMsg(response.body));
  }

  static Future<Quadra> adicionarFotos({
    required int quadraId,
    required List<XFile> fotos,
  }) async {
    final token = await AuthService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/quadras/$quadraId/fotos'),
    )..headers['Authorization'] = 'Bearer $token';

    for (final foto in fotos) {
      final bytes = await foto.readAsBytes();
      final ext = foto.path.split('.').last.toLowerCase();
      request.files.add(http.MultipartFile.fromBytes(
        'fotos',
        bytes,
        filename: foto.name,
        contentType: MediaType('image', ext == 'jpg' ? 'jpeg' : ext),
      ));
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Quadra.fromJson(jsonDecode(response.body));
    }
    throw Exception(_erroMsg(response.body));
  }

  static Future<void> removerFoto({
    required int quadraId,
    required int fotoId,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/quadras/$quadraId/fotos/$fotoId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(_erroMsg(response.body));
    }
  }

  static Future<void> excluir(int id) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/quadras/$id'),
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