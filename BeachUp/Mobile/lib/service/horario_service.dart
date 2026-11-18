import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/service/auth_service.dart';

class HorarioFuncionamento {
  final int? id;
  final String diaSemana;      
  final String diaSemanaLabel;
  final String horaAbertura;   
  final String horaFechamento; 

  HorarioFuncionamento({
    this.id,
    required this.diaSemana,
    required this.diaSemanaLabel,
    required this.horaAbertura,
    required this.horaFechamento,
  });

  factory HorarioFuncionamento.fromJson(Map<String, dynamic> json) {
    String _fmt(dynamic t) {
      if (t == null) return '';
      final s = t.toString();
      final parts = s.split(':');
      if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
      return s;
    }

    return HorarioFuncionamento(
      id: json['id'],
      diaSemana: json['diaSemana'] ?? '',
      diaSemanaLabel: json['diaSemanaLabel'] ?? json['diaSemana'] ?? '',
      horaAbertura: _fmt(json['horaAbertura']),
      horaFechamento: _fmt(json['horaFechamento']),
    );
  }

  Map<String, dynamic> toJson() => {
        'diaSemana': diaSemana,
        'horaAbertura': horaAbertura.length == 5 ? '$horaAbertura:00' : horaAbertura,
        'horaFechamento': horaFechamento.length == 5 ? '$horaFechamento:00' : horaFechamento,
      };
}

class HorarioService {
  static Future<List<HorarioFuncionamento>> listar(int arenaId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/arenas/$arenaId/horarios'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => HorarioFuncionamento.fromJson(e)).toList();
    }
    throw Exception('Erro ao buscar horários: ${response.statusCode}');
  }

  static Future<HorarioFuncionamento> salvar(
      int arenaId, HorarioFuncionamento horario) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/arenas/$arenaId/horarios'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(horario.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return HorarioFuncionamento.fromJson(jsonDecode(response.body));
    }
    try {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['error'] ?? 'Erro ao salvar horário');
    } catch (_) {
      throw Exception('Erro ao salvar horário: ${response.statusCode}');
    }
  }

  static Future<void> remover(int arenaId, String diaSemana) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/arenas/$arenaId/horarios/$diaSemana'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao remover horário: ${response.statusCode}');
    }
  }
}

const diasDaSemana = [
  {'valor': 'MONDAY',    'label': 'Segunda-feira'},
  {'valor': 'TUESDAY',   'label': 'Terça-feira'},
  {'valor': 'WEDNESDAY', 'label': 'Quarta-feira'},
  {'valor': 'THURSDAY',  'label': 'Quinta-feira'},
  {'valor': 'FRIDAY',    'label': 'Sexta-feira'},
  {'valor': 'SATURDAY',  'label': 'Sábado'},
  {'valor': 'SUNDAY',    'label': 'Domingo'},
];
