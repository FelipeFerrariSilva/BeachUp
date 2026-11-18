import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:cpf_cnpj_validator/cpf_validator.dart';
import 'package:cpf_cnpj_validator/cnpj_validator.dart';
import 'package:flutter_application_1/config/api_config.dart';

class CadastroService {
  static String? validarJogador({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) {
    debugPrint('CPF recebido: $cpf');
    if (nome.isEmpty ||
        cpf.isEmpty ||
        email.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      return 'Preencha todos os campos';
    }
    if (!CPFValidator.isValid(cpf)) return 'CPF inválido';
    if (!email.contains('@') || !email.contains('.')) return 'Email inválido';
    if (senha != confirmarSenha) return 'As senhas não coincidem';
    if (senha.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  static String? validarEmpresa({
    required String nome,
    required String cnpj,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) {
    if (nome.isEmpty ||
        cnpj.isEmpty ||
        email.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      return 'Preencha todos os campos';
    }
    if (!CNPJValidator.isValid(cnpj)) return 'CNPJ inválido';
    if (!email.contains('@') || !email.contains('.')) return 'Email inválido';
    if (senha != confirmarSenha) return 'As senhas não coincidem';
    if (senha.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  static Future<String?> cadastrarJogador({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
    required String cpf,
  }) async {
    final cpfLimpo = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    final body = jsonEncode({
      'nome': nome,
      'email': email,
      'senha': senha,
      'confirmarSenha': confirmarSenha,
      'cpf': cpfLimpo,
    });

    for (int tentativa = 1; tentativa <= 2; tentativa++) {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/jogador/cadastro'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        debugPrint('Cadastro jogador: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          return null;
        }
        return _extrairMensagem(response.body);
      } catch (e) {
        debugPrint('Erro no cadastro jogador (tentativa $tentativa): $e');
        if (tentativa == 2) return 'Erro de conexão. Tente novamente.';
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    return 'Erro de conexão. Tente novamente.';
  }

  static Future<String?> cadastrarEmpresa({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
    required String cnpj,
  }) async {
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    final body = jsonEncode({
      'nome': nome,
      'email': email,
      'senha': senha,
      'confirmarSenha': confirmarSenha,
      'cnpj': cnpjLimpo,
    });

    for (int tentativa = 1; tentativa <= 2; tentativa++) {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/empresa/cadastro'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        debugPrint('Cadastro empresa: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          return null;
        }
        return _extrairMensagem(response.body);
      } catch (e) {
        debugPrint('Erro no cadastro empresa (tentativa $tentativa): $e');
        if (tentativa == 2) return 'Erro de conexão. Tente novamente.';
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    return 'Erro de conexão. Tente novamente.';
  }

  static String _extrairMensagem(String body) {
    try {
      final json = jsonDecode(body);
      return json['message'] ??
          json['error'] ??
          json['detail'] ??
          'Erro ao cadastrar.';
    } catch (_) {
      return body.isNotEmpty ? body : 'Erro ao cadastrar.';
    }
  }
}