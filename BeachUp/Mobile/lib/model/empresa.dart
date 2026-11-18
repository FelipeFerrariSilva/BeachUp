class Empresa{
  final int id;
  final String cnpj;

  Empresa({
    required this.id,
    required this.cnpj,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'],
      cnpj: json['cnpj'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cnpj': cnpj,
    };
  }
}