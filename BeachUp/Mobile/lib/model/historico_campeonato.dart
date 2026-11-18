
class HistoricoCampeonatoModel {
  final int id;
  final String nomeCampeonato;
  final String nomeTime;
  final String status;
  final String? dataInscricao;
  final String? dataCampeonato;
  final double? taxaInscricao;

  HistoricoCampeonatoModel({
    required this.id,
    required this.nomeCampeonato,
    required this.nomeTime,
    required this.status,
    this.dataInscricao,
    this.dataCampeonato,
    this.taxaInscricao,
  });

  factory HistoricoCampeonatoModel.fromJson(Map<String, dynamic> json) {
    return HistoricoCampeonatoModel(
      id: json['id'],
      nomeCampeonato: json['nomeCampeonato'] ?? '',
      nomeTime: json['nomeTime'] ?? '',
      status: json['status'] ?? '',
      dataInscricao: json['dataInscricao'],
      dataCampeonato: json['dataCampeonato'],
      taxaInscricao: json['taxaInscricao'] != null
          ? double.tryParse(json['taxaInscricao'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeCampeonato': nomeCampeonato,
      'nomeTime': nomeTime,
      'status': status,
      'dataInscricao': dataInscricao,
      'dataCampeonato': dataCampeonato,
      'taxaInscricao': taxaInscricao,
    };
  }
}
