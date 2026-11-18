class Jogador {
  final int id;
  final String cpf;

  Jogador({
    required this.id,
    required this.cpf,
  });

  factory Jogador.fromJson(Map<String, dynamic> json) {
    return Jogador(
      id: json['id'],
      cpf: json['cpf'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cpf': cpf,
    };
  }
}