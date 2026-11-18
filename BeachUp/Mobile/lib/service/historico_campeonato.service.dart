import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/historico_campeonato.dart';
import 'package:flutter_application_1/config/api_config.dart';

class HistoricoCampeonatoService {
  final String baseUrl = ApiConfig.baseUrl;
  final String endpoint = '/inscricoes/historico';

  Future<List<HistoricoCampeonatoModel>> getHistoricoCampeonatos() async {
    final url = Uri.parse('$baseUrl$endpoint');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      return data
          .map((item) => HistoricoCampeonatoModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Erro ao carregar histórico de campeonatos');
    }
  }
}