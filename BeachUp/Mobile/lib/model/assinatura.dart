class Assinatura {
  final int id;
  final String tipoPlano;
  final String nomePlano;
  final int? limiteQuadras;
  final double valorMensal;
  final double taxaReserva;
  final String status;
  final bool premiumAtivo;
  final bool podeCriarCampeonato;

  Assinatura({
    required this.id,
    required this.tipoPlano,
    required this.nomePlano,
    required this.limiteQuadras,
    required this.valorMensal,
    required this.taxaReserva,
    required this.status,
    required this.premiumAtivo,
    required this.podeCriarCampeonato,
  });

  factory Assinatura.fromJson(Map<String, dynamic> json) {
    return Assinatura(
      id: json['id'],
      tipoPlano: json['tipoPlano'],
      nomePlano: json['nomePlano'],
      limiteQuadras: json['limiteQuadras'],
      valorMensal: (json['valorMensal'] as num).toDouble(),
      taxaReserva: (json['taxaReserva'] as num).toDouble(),
      status: json['status'],
      premiumAtivo: json['premiumAtivo'] ?? false,
      podeCriarCampeonato: json['podeCriarCampeonato'] ?? false,
    );
  }
}