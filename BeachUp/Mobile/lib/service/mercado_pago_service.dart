import 'dart:convert';
import 'package:http/http.dart' as http;

class MercadoPagoService {
  static const String _baseUrl = 'https://sua-api.com';

  static Future<String> criarPreferenciaReserva({
    required String quadraNome,
    required String data,
    required String horario,
    required int duracao,
    required double valor,
    required String usuarioEmail,
    required String usuarioNome,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pagamentos/reserva'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'quadra_nome': quadraNome,
        'data': data,
        'horario': horario,
        'duracao': duracao,
        'valor': valor,
        'usuario_email': usuarioEmail,
        'usuario_nome': usuarioNome,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['init_point'] as String;
    } else {
      throw Exception(
        'Erro ao criar preferência: ${response.statusCode} - ${response.body}',
      );
    }
  }

  static Future<String> criarPreferenciaPlano({
    required String planoNome,
    required double valor,
    required String usuarioEmail,
    required String usuarioNome,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pagamentos/plano'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'plano': planoNome,
        'valor': valor,
        'usuario_email': usuarioEmail,
        'usuario_nome': usuarioNome,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['init_point'] as String;
    } else {
      throw Exception(
        'Erro ao criar preferência do plano: ${response.statusCode}',
      );
    }
  }
}
