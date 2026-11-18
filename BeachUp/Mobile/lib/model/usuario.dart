class Usuario{
  final String email;
  final String role;

  Usuario({
    required this.email,
    required this.role,
  });

  bool get isJogador => role == 'ROLE_JOGADOR';

  bool get isEmpresa => role == 'ROLE_EMPRESA';
}