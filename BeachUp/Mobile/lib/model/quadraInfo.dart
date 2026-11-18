class QuadraInfo {
  final String id;
  final String nome;
  final double precoPorHora;

  QuadraInfo({
    required this.id,
    required this.nome,
    required this.precoPorHora,
  });

  factory QuadraInfo.fromJson(Map<String, dynamic> json) {
    return QuadraInfo(
      id: json['id'],
      nome: json['nome'],
      precoPorHora: (json['preco_por_hora'] as num).toDouble(),
    );
  }
}