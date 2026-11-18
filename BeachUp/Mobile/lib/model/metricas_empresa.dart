class MetricasEmpresa {
  final double faturamentoTotal;
  final double faturamentoMesAtual;
  final double ticketMedio;
  final int totalReservas;
  final int reservasConfirmadas;
  final int reservasPendentes;
  final int reservasCanceladas;
  final int reservasHoje;
  final int totalArenas;
  final int totalQuadras;
  final List<QuadraRanking> topQuadras;
  final List<FaturamentoMensal> faturamentoUltimos6Meses;

  MetricasEmpresa({
    required this.faturamentoTotal,
    required this.faturamentoMesAtual,
    required this.ticketMedio,
    required this.totalReservas,
    required this.reservasConfirmadas,
    required this.reservasPendentes,
    required this.reservasCanceladas,
    required this.reservasHoje,
    required this.totalArenas,
    required this.totalQuadras,
    required this.topQuadras,
    required this.faturamentoUltimos6Meses,
  });

  factory MetricasEmpresa.fromJson(Map<String, dynamic> json) {
    return MetricasEmpresa(
      faturamentoTotal: _toDouble(json['faturamentoTotal']),
      faturamentoMesAtual: _toDouble(json['faturamentoMesAtual']),
      ticketMedio: _toDouble(json['ticketMedio']),
      totalReservas: (json['totalReservas'] ?? 0) as int,
      reservasConfirmadas: (json['reservasConfirmadas'] ?? 0) as int,
      reservasPendentes: (json['reservasPendentes'] ?? 0) as int,
      reservasCanceladas: (json['reservasCanceladas'] ?? 0) as int,
      reservasHoje: (json['reservasHoje'] ?? 0) as int,
      totalArenas: (json['totalArenas'] ?? 0) as int,
      totalQuadras: (json['totalQuadras'] ?? 0) as int,
      topQuadras: ((json['topQuadras'] ?? []) as List)
          .map((e) => QuadraRanking.fromJson(e))
          .toList(),
      faturamentoUltimos6Meses: ((json['faturamentoUltimos6Meses'] ?? []) as List)
          .map((e) => FaturamentoMensal.fromJson(e))
          .toList(),
    );
  }

  static double _toDouble(dynamic valor) {
    if (valor == null) return 0.0;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString()) ?? 0.0;
  }
}

class QuadraRanking {
  final String nomeQuadra;
  final int totalReservas;

  QuadraRanking({required this.nomeQuadra, required this.totalReservas});

  factory QuadraRanking.fromJson(Map<String, dynamic> json) {
    return QuadraRanking(
      nomeQuadra: json['nomeQuadra'] ?? '',
      totalReservas: (json['totalReservas'] ?? 0) as int,
    );
  }
}

class FaturamentoMensal {
  final int ano;
  final int mes;
  final String mesNome;
  final double total;

  FaturamentoMensal({
    required this.ano,
    required this.mes,
    required this.mesNome,
    required this.total,
  });

  factory FaturamentoMensal.fromJson(Map<String, dynamic> json) {
    return FaturamentoMensal(
      ano: (json['ano'] ?? 0) as int,
      mes: (json['mes'] ?? 0) as int,
      mesNome: json['mesNome'] ?? '',
      total: MetricasEmpresa._toDouble(json['total']),
    );
  }
}