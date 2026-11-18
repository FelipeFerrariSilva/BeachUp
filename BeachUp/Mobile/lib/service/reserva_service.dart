import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/model/reserva.dart';
import 'package:flutter_application_1/service/auth_service.dart';

class ReservaService {
  static Future<Reserva> criar({
    required int quadraId,
    required DateTime dataHoraInicio,
    required DateTime dataHoraFim,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/reservas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'quadraId': quadraId,
        'dataHoraInicio': _formatarDateTime(dataHoraInicio),
        'dataHoraFim': _formatarDateTime(dataHoraFim),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Reserva.fromJson(jsonDecode(response.body));
    } else {
      final msg = _extrairMensagemErro(response.body);
      throw Exception(msg);
    }
  }

  static Future<List<Reserva>> minhasReservas() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reservas/minhas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Reserva.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar reservas: ${response.statusCode}');
    }
  }

  static Future<Reserva> cancelar(int reservaId) async {
    final token = await AuthService.getToken();

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/reservas/$reservaId/cancelar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Reserva.fromJson(jsonDecode(response.body));
    } else {
      final msg = _extrairMensagemErro(response.body);
      throw Exception(msg);
    }
  }

  static Future<Reserva> buscarPorId(int id) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reservas/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Reserva.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Reserva não encontrada');
    }
  }


  static String _formatarDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-${d}T$h:$mi:00';
  }

  static String _extrairMensagemErro(String body) {
    try {
      final json = jsonDecode(body);
      return json['message'] ?? json['error'] ?? body;
    } catch (_) {
      return body.isNotEmpty ? body : 'Erro desconhecido';
    }
  }
}