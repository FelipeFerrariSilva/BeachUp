import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/home/login/login_screen.dart';
import 'package:flutter_application_1/service/recuperar_senha_service.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  int _etapa = 0;
  bool _carregando = false;

  final txtEmailController = TextEditingController();

  @override
  void dispose() {
    txtEmailController.dispose();
    super.dispose();
  }

  Future<void> _enviarEmail() async {
    final email = txtEmailController.text.trim();

    if (email.isEmpty) {
      _mostrarSnack('Informe seu e-mail');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _mostrarSnack('E-mail inválido');
      return;
    }

    setState(() => _carregando = true);

    final erro = await RecuperarSenhaService.solicitarReset(email: email);

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      _mostrarSnack(erro);
      return;
    }

    setState(() => _etapa = 1);
  }

  void _mostrarSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _irParaLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String get _titulo =>
      _etapa == 0 ? 'Informe seu e-mail' : 'Verifique seu e-mail';

  String get _subtitulo => _etapa == 0
      ? 'Enviaremos um link de\nrecuperação para você.'
      : 'Enviamos um link para\n${txtEmailController.text.trim()}';

  Widget _conteudoEtapa() {
    return _etapa == 0 ? _etapaEmail() : _etapaInstrucoes();
  }

  Widget _etapaEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _campo(
          controller: txtEmailController,
          hint: 'E-mail cadastrado',
          icone: Icons.email_outlined,
          teclado: TextInputType.emailAddress,
        ),
        const SizedBox(height: 28),
        _botaoPrincipal(
          label: 'Enviar link de recuperação',
          onTap: _carregando ? null : _enviarEmail,
        ),
      ],
    );
  }

  Widget _etapaInstrucoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kOffWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _passoInstrucao('1', 'Abra o e-mail que enviamos.'),
              const SizedBox(height: 10),
              _passoInstrucao(
                '2',
                'Toque no botão "Redefinir senha" e crie sua nova senha pela página que abrir.',
              ),
              const SizedBox(height: 10),
              _passoInstrucao(
                '3',
                'Volte ao app e entre com a nova senha.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Não recebeu? Verifique a caixa de spam ou tente reenviar. '
                  'O link expira em 30 minutos.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _botaoPrincipal(
          label: 'Já redefini — Entrar',
          onTap: _carregando ? null : _irParaLogin,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _carregando ? null : _enviarEmail,
            child: const Text(
              'Reenviar e-mail',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passoInstrucao(String numero, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            numero,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              texto,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_etapa > 0) {
                              setState(() => _etapa--);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const Text(
                          'RECUPERAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Text(
                          'SUA SENHA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
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
                      padding: const EdgeInsets.only(
                        top: 32,
                        left: 25,
                        right: 25,
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _indicadorEtapas(),
                            const SizedBox(height: 24),
                            Text(
                              _titulo,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kTextPri,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _etapa == 0
                                  ? 'Siga os passos para recuperar o acesso'
                                  : 'Falta pouco para voltar a jogar',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _conteudoEtapa(),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Lembrou a senha?',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                TextButton(
                                  onPressed: _irParaLogin,
                                  child: const Text(
                                    'Entrar',
                                    style: TextStyle(
                                      color: Colors.orange,
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

  Widget _indicadorEtapas() {
    return Row(
      children: List.generate(2, (i) {
        final ativo = i == _etapa;
        final concluido = i < _etapa;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: ativo ? 32 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: concluido || ativo
                    ? Colors.orange
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: concluido
                  ? const Icon(Icons.check, color: Colors.white, size: 9)
                  : null,
            ),
            if (i < 1)
              Container(
                width: 24,
                height: 2,
                color: concluido ? Colors.orange : const Color(0xFFE0E0E0),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
          ],
        );
      }),
    );
  }

  Widget _botaoPrincipal({
    required String label,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: const Color(
            0xFF1e3e1f,
          ).withValues(alpha: 0.6),
        ),
        onPressed: onTap,
        child: _carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.orange,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    TextInputType teclado = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
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
      ),
    );
  }
}