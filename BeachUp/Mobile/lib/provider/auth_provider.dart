import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _estaLogado = false;
  String _emailUsuario = '';
  String _role = '';
  String _accessToken = '';
  bool _carregando = true;

  bool get estaLogado => _estaLogado;
  String get emailUsuario => _emailUsuario;
  String get role => _role;
  String get accessToken => _accessToken;
  bool get carregando => _carregando;

  bool get isJogador => _role == 'ROLE_JOGADOR';
  bool get isEmpresa => _role == 'ROLE_EMPRESA';

  Future<void> verificarLogin() async {
    final logado = await AuthService.estaLogado();
    if (logado) {
      final usuario = await AuthService.getUsuarioLogado();
      final token = await AuthService.getToken();
      if (usuario != null) {
        _estaLogado = true;
        _emailUsuario = usuario.email;
        _role = usuario.role;
        _accessToken = token ?? '';
      }
    }
    _carregando = false;
    notifyListeners();
  }

  void fazerLogin(String email, String role, String accessToken) {
    _estaLogado = true;
    _emailUsuario = email;
    _role = role;
    _accessToken = accessToken;
    notifyListeners();
  }

  void sair() {
    _estaLogado = false;
    _emailUsuario = '';
    _role = '';
    _accessToken = '';
    AuthService.logout();
    notifyListeners();
  }
}