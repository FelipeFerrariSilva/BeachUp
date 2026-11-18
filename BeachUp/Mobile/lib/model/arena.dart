class Endereco {
  final String? logradouro;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? cep;

  Endereco({
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) => Endereco(
        logradouro: json['logradouro'],
        numero: json['numero'],
        bairro: json['bairro'],
        cidade: json['cidade'],
        estado: json['estado'],
        cep: json['cep'],
      );
}

class Arena {
  final int id;
  final String nome;
  final String? descricao;
  final Endereco? endereco;
  final double? latitude;
  final double? longitude;
  final double? distanciaKm;
  final String? fotoUrl;

  Arena({
    required this.id,
    required this.nome,
    this.descricao,
    this.endereco,
    this.latitude,
    this.longitude,
    this.distanciaKm,
    this.fotoUrl,
  });

  String get localizacao {
    if (endereco == null) return '';
    final cidade = endereco!.cidade ?? '';
    final estado = endereco!.estado ?? '';
    if (cidade.isEmpty && estado.isEmpty) return '';
    if (estado.isEmpty) return cidade;
    return '$cidade, $estado';
  }

  factory Arena.fromJson(Map<String, dynamic> json) => Arena(
        id: json['id'],
        nome: json['nome'] ?? '',
        descricao: json['descricao'],
        endereco:
            json['endereco'] != null ? Endereco.fromJson(json['endereco']) : null,
        latitude: (json['latitute'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        distanciaKm: (json['distanciaKm'] as num?)?.toDouble(),
        fotoUrl: json['fotoUrl'],
      );
}