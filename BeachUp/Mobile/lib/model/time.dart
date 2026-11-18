class MembroTime {
  final int idJogador;
  final String nomeUsuario;
  final String status; 

  MembroTime({
    required this.idJogador,
    required this.nomeUsuario,
    required this.status,
  });

  factory MembroTime.fromJson(Map<String, dynamic> json) => MembroTime(
        idJogador: json['idJogador'],
        nomeUsuario: json['nomeUsuario'] ?? '',
        status: json['status'] ?? '',
      );
}

class TimeModel {
  final int id;
  final String nome;
  final String? descricao;
  final String? cidade;
  final String? status;

  final int? idJogadorDono;
  final String? urlConvite;
  final List<MembroTime> membros;

  TimeModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.cidade,
    this.status,
    this.idJogadorDono,
    this.urlConvite,
    this.membros = const [],
  });

  factory TimeModel.fromJson(Map<String, dynamic> json) {
    return TimeModel(
      id: json['id'],
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      cidade: json['cidade'],
      status: json['status'],
    );
  }

  factory TimeModel.fromBackendJson(Map<String, dynamic> json) {
    final membrosList = (json['membros'] as List<dynamic>? ?? [])
        .map((m) => MembroTime.fromJson(m as Map<String, dynamic>))
        .toList();

    final totalMembros = membrosList
        .where((m) => m.status.toUpperCase() == 'ACEITO')
        .length;
    final statusDerivado = totalMembros >= 2 ? 'COMPLETO' : 'ABERTO';

    return TimeModel(
      id: json['id'],
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      cidade: null, 
      status: statusDerivado,
      idJogadorDono: json['idJogadorDono'],
      urlConvite: json['urlConvite'],
      membros: membrosList,
    );
  }

  int get totalMembros =>
      membros.where((m) => m.status.toUpperCase() == 'ACEITO').length;

  bool get estaCompleto => totalMembros >= 2;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'descricao': descricao,
        'cidade': cidade,
        'status': status,
      };
}
