import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/home/login/login_screen.dart';

import 'package:flutter_application_1/service/cadastro_service.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class CadastroUsuario extends StatefulWidget {
  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();
}

class _CadastroUsuarioState extends State<CadastroUsuario> {
  bool _isJogador = true;
  bool _senhaVisivel = false;
  bool _confSenhaVisivel = false;
  bool _enviando = false;

  final txtNomeController = TextEditingController();
  final txtDocumentoController = TextEditingController();
  final txtEmailController = TextEditingController();
  final txtSenhaController = TextEditingController();
  final txtConfSenhaController = TextEditingController();

  @override
  void dispose() {
    txtNomeController.dispose();
    txtDocumentoController.dispose();
    txtEmailController.dispose();
    txtSenhaController.dispose();
    txtConfSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_enviando) return; // evita disparar de novo enquanto já está enviando

    if (txtNomeController.text.isEmpty ||
        txtDocumentoController.text.isEmpty ||
        txtEmailController.text.isEmpty ||
        txtSenhaController.text.isEmpty ||
        txtConfSenhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    final erroValidacao = _isJogador
        ? CadastroService.validarJogador(
            nome: txtNomeController.text,
            cpf: txtDocumentoController.text,
            email: txtEmailController.text,
            senha: txtSenhaController.text,
            confirmarSenha: txtConfSenhaController.text,
          )
        : CadastroService.validarEmpresa(
            nome: txtNomeController.text,
            cnpj: txtDocumentoController.text,
            email: txtEmailController.text,
            senha: txtSenhaController.text,
            confirmarSenha: txtConfSenhaController.text,
          );

    if (erroValidacao != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erroValidacao)));
      return;
    }

    setState(() => _enviando = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final erroApi = _isJogador
        ? await CadastroService.cadastrarJogador(
            nome: txtNomeController.text,
            cpf: txtDocumentoController.text,
            email: txtEmailController.text,
            senha: txtSenhaController.text,
            confirmarSenha: txtConfSenhaController.text,
          )
        : await CadastroService.cadastrarEmpresa(
            nome: txtNomeController.text,
            cnpj: txtDocumentoController.text,
            email: txtEmailController.text,
            senha: txtSenhaController.text,
            confirmarSenha: txtConfSenhaController.text,
          );

    if (mounted) setState(() => _enviando = false);
    if (!mounted) return;
    Navigator.pop(context);

    if (erroApi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado! Faça login.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erroApi)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: kTextPri,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/beach_tela_inicial.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(flex: 1, child: const SizedBox()),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 25, left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'CRIAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'SUA CONTA',
                          style: TextStyle(
                            color: kLaranja,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Cadastre-se e comece a\nreservar as melhores\nquadras.',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(70),
                        topRight: Radius.circular(70),
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 32, left: 25, right: 25),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isJogador
                                          ? 'Cadastro de jogador'
                                          : 'Cadastro de empresa',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: kTextPri,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Preencha os dados abaixo',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _isJogador = !_isJogador;
                                    txtDocumentoController.clear();
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: kLaranja,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _isJogador ? 'Empresa' : 'Jogador',
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _campo(
                              controller: txtNomeController,
                              hint: _isJogador
                                  ? 'Nome completo'
                                  : 'Nome da empresa',
                              icone: Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                            _campo(
                              controller: txtDocumentoController,
                              hint: _isJogador ? 'CPF' : 'CNPJ',
                              icone: Icons.badge_outlined,
                              teclado: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            _campo(
                              controller: txtEmailController,
                              hint: 'E-mail',
                              icone: Icons.email_outlined,
                            ),
                            const SizedBox(height: 12),
                            _campo(
                              controller: txtSenhaController,
                              hint: 'Senha',
                              icone: Icons.lock_outline,
                              senha: true,
                              senhaVisivel: _senhaVisivel,
                              onToggleSenha: () => setState(
                                  () => _senhaVisivel = !_senhaVisivel),
                            ),
                            const SizedBox(height: 12),
                            _campo(
                              controller: txtConfSenhaController,
                              hint: 'Confirmar Senha',
                              icone: Icons.lock_outline,
                              senha: true,
                              senhaVisivel: _confSenhaVisivel,
                              onToggleSenha: () => setState(
                                  () => _confSenhaVisivel = !_confSenhaVisivel),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kLaranja,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _enviando ? null : _cadastrar,
                                child: const Text(
                                  'Cadastrar',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Text('ou',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                              const Expanded(child: Divider()),
                            ]),
                            const SizedBox(height: 16),
    
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Já tem conta?',
                                    style: TextStyle(color: Colors.grey)),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                  ),
                                  child: const Text(
                                    'Entrar',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    bool senha = false,
    bool senhaVisivel = false,
    VoidCallback? onToggleSenha,
    TextInputType teclado = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: senha && !senhaVisivel,
      keyboardType: teclado,
      style: const TextStyle(color: kTextPri),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icone),
        filled: true,
        fillColor: kOffWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: senha
            ? IconButton(
                icon: Icon(
                  senhaVisivel ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: onToggleSenha,
              )
            : null,
      ),
    );
  }
}