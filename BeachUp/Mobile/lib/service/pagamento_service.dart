import 'dart:convert';
import 'package:flutter_application_1/model/Pagamento_Checkout.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/model/assinatura.dart';
import 'package:flutter_application_1/service/auth_service.dart';

class PagamentoService {
  static Future<PagamentoCheckout> iniciarPagamentoReserva(int reservaId) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/pagamentos/reserva/$reservaId/iniciar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PagamentoCheckout.fromJson(jsonDecode(response.body));
    } else {
      final msg = _extrairMensagemErro(response.body);
      throw Exception(msg);
    }
  }

  static Future<PagamentoCheckout> assinarPlano(String tipoPlano) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/pagamentos/plano/iniciar?tipoPlano=$tipoPlano'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PagamentoCheckout.fromJson(jsonDecode(response.body));
    } else {
      final msg = _extrairMensagemErro(response.body);
      throw Exception(msg);
    }
  }

  static Future<String> obterUrlConexaoMercadoPago() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/pagamentos/oauth/conectar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var body = response.body.trim();
      if (body.startsWith('"') && body.endsWith('"')) {
        body = body.substring(1, body.length - 1);
      }
      return body;
    } else {
      final msg = _extrairMensagemErro(response.body);
      throw Exception(msg);
    }
  }

  static Future<Assinatura> minhaAssinatura() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/planos/minha-assinatura'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Assinatura.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao buscar assinatura atual');
    }
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