class CampeonatoDTO {
  final int id;
  final String nome;
  final String descricao;
  final String categoria;
  final String dataInicio;
  final String dataFim;
  final String status;
  final String tokenInscricao;
  final int totalInscritos;

  CampeonatoDTO({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.dataInicio,
    required this.dataFim,
    required this.status,
    required this.tokenInscricao,
    required this.totalInscritos,
  });

  factory CampeonatoDTO.fromJson(Map<String, dynamic> json) => CampeonatoDTO(
    id: json['id'],
    nome: json['nome'],
    descricao: json['descricao'] ?? '',
    categoria: json['categoria'] ?? '',
    dataInicio: json['dataInicio'],
    dataFim: json['dataFim'],
    status: json['status'],
    tokenInscricao: json['tokenInscricao'],
    totalInscritos: json['totalInscritos'] ?? 0,
  );
}