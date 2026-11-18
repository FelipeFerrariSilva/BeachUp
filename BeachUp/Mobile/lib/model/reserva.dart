class Reserva {
  final int id;
  final int quadraId;
  final String nomeQuadra;
  final int jogadorId;
  final String nomeJogador;
  final DateTime dataHoraInicio;
  final DateTime dataHoraFim;
  final double valorTotal;
  final String status;

  Reserva({
    required this.id,
    required this.quadraId,
    required this.nomeQuadra,
    required this.jogadorId,
    required this.nomeJogador,
    required this.dataHoraInicio,
    required this.dataHoraFim,
    required this.valorTotal,
    required this.status,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
        id: json['id'],
        quadraId: json['quadraId'],
        nomeQuadra: json['nomeQuadra'] ?? '',
        jogadorId: json['jogadorId'],
        nomeJogador: json['nomeJogador'] ?? '',
        dataHoraInicio: DateTime.parse(json['dataHoraInicio']),
        dataHoraFim: DateTime.parse(json['dataHoraFim']),
        valorTotal: (json['valorTotal'] as num).toDouble(),
        status: json['status'] ?? 'PENDENTE',
      );

  bool get isPendente => status == 'PENDENTE';
  bool get isConfirmada => status == 'CONFIRMADA';
  bool get isCancelada => status == 'CANCELADA';
}