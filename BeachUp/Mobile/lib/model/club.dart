import 'package:flutter/material.dart';
 
enum Superficie { areia, gramado, quadra }
 
class Club {
  final String nome;
  final String cidade;
  final String estado;
  final Superficie superficie;
  final double preco;
  final int maxJogadores;
  final String diasDisponiveis;
  final String horarios;
  final String comodidade;
  final String cobertura;
  final String urlImagem;
  final bool ativo;
 
  const Club({
    required this.nome,
    required this.cidade,
    required this.estado,
    required this.superficie,
    required this.preco,
    required this.maxJogadores,
    required this.diasDisponiveis,
    required this.horarios,
    required this.comodidade,
    required this.cobertura,
    required this.urlImagem,
    this.ativo = true,
  });
 
  String get superficieLabel => switch (superficie) {
        Superficie.areia   => 'Areia',
        Superficie.gramado => 'Gramado',
        Superficie.quadra  => 'Quadra',
      };
 
  IconData get superficieIcon => switch (superficie) {
        Superficie.areia   => Icons.beach_access,
        Superficie.gramado => Icons.grass,
        Superficie.quadra  => Icons.sports_tennis,
      };
 
  Color get superficieColor => switch (superficie) {
        Superficie.areia   => const Color(0xFFFAC775),
        Superficie.gramado => const Color(0xFFC0DD97),
        Superficie.quadra  => const Color(0xFFB5D4F4),
      };
}