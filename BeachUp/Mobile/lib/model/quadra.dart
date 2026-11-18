import 'package:flutter_application_1/config/api_config.dart';

class Quadra {
  final int id;
  final String nome;
  final String? tipoCobertura;
  final double valorHora;
  final List<String> fotos;

  Quadra({
    required this.id,
    required this.nome,
    this.tipoCobertura,
    required this.valorHora,
    this.fotos = const [],
  });

  factory Quadra.fromJson(Map<String, dynamic> json) {
    String absoluta(String? url) {
      if (url == null || url.isEmpty) return '';
      if (url.startsWith('http')) return url;
      return '${ApiConfig.baseUrl}$url';
    }

    return Quadra(
      id: json['id'],
      nome: json['nome'] ?? '',
      tipoCobertura: json['tipoCobertura'],
      valorHora: (json['valorHora'] as num).toDouble(),
      fotos: (json['fotos'] as List<dynamic>?)
              ?.map((e) => absoluta(e.toString()))
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
    );
  }

  bool get temCobertura => tipoCobertura == 'COBERTA';

  String get coberturaLabel {
    switch (tipoCobertura) {
      case 'COBERTA':
        return 'Com cobertura';
      case 'DESCOBERTA':
        return 'Sem cobertura';
      default:
        return tipoCobertura ?? '';
    }
  }
}