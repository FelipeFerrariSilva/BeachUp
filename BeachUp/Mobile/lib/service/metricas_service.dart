import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/model/metricas_empresa.dart';
import 'package:flutter_application_1/service/auth_service.dart';

class MetricasService {
  static Future<MetricasEmpresa> obterMetricasEmpresa() async {
    final token = await AuthService.getToken();
    debugPrint('[MetricasService] TOKEN: $token');
    debugPrint('[MetricasService] URL: ${ApiConfig.baseUrl}/metricas/empresa');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/metricas/empresa'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('[MetricasService] STATUS: ${response.statusCode}');
    debugPrint('[MetricasService] BODY: ${response.body}');

    if (response.statusCode == 200) {
      return MetricasEmpresa.fromJson(jsonDecode(response.body));
    }
    throw Exception(_erroMsg(response.body, response.statusCode));
  }

  static String _erroMsg(String body, int statusCode) {
    try {
      final j = jsonDecode(body);
      return j['message'] ?? j['error'] ?? 'Erro ao buscar métricas: $statusCode';
    } catch (_) {
      return body.isNotEmpty ? body : 'Erro ao buscar métricas: $statusCode';
    }
  }
}