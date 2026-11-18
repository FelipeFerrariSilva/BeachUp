import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/model/time.dart';
import 'package:flutter_application_1/service/time_service.dart';


import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class CriarTimeJogadorScreen extends StatefulWidget {
  const CriarTimeJogadorScreen({super.key});

  @override
  State<CriarTimeJogadorScreen> createState() => _CriarTimeJogadorScreenState();
}

class _CriarTimeJogadorScreenState extends State<CriarTimeJogadorScreen> {
  final _nomeCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  bool _carregando   = false;
  TimeModel? _timeCriado;

  String get _linkConvite {
    if (_timeCriado?.urlConvite == null) return '';
    return 'https://www.beachup.com.br/aceitar-convite/${_timeCriado!.urlConvite}';
  }

  String get _mensagemConvite {
    if (_timeCriado == null) return '';
    return 'Ei! Entra no meu time *\${_timeCriado!.nome}* no BeachUp 🏖️🎾\n\n'
        '\$_linkConvite';
  }

  bool get _timeFoiCriado => _timeCriado != null;
  bool get _estaCompleto  => _timeCriado?.estaCompleto ?? false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _criarTime() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      _erro('Digite o nome do time primeiro!');
      return;
    }
    setState(() => _carregando = true);
    try {
      final time = await TimeService.criar(
        nome: _nomeCtrl.text.trim(),
        descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      setState(() { _timeCriado = time; _carregando = false; });
      _sucesso('Time criado com sucesso!');
    } catch (e) {
      setState(() => _carregando = false);
      _erro(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _regerarConvite() async {
    if (_timeCriado == null) return;
    setState(() => _carregando = true);
    try {
      final novoToken = await TimeService.regerarConvite(_timeCriado!.id);
      setState(() {
        _timeCriado = TimeModel(
          id: _timeCriado!.id,
          nome: _timeCriado!.nome,
          descricao: _timeCriado!.descricao,
          urlConvite: novoToken,
          idJogadorDono: _timeCriado!.idJogadorDono,
          membros: _timeCriado!.membros,
        );
        _carregando = false;
      });
      _sucesso('Novo link gerado!');
    } catch (e) {
      setState(() => _carregando = false);
      _erro(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _copiarLink() {
    Clipboard.setData(ClipboardData(text: _linkConvite));
    _sucesso('Link copiado!');
  }

  Future<void> _enviarWhatsApp() async {
    if (_linkConvite.isEmpty) return;
    final msg = Uri.encodeComponent(
      'Ei! Entre no meu time no BeachUp 🏖️🎾\n$_linkConvite',
    );
    final uri = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _erro('Não foi possível abrir o WhatsApp');
    }
  }

  void _erro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _sucesso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kLaranja));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPri),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF0E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kLaranja, Color(0xFFD0E816)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.groups_rounded,
                          color: kLaranja, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nomeCtrl.text.isEmpty ? 'Meu time' : _nomeCtrl.text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeFoiCriado
                          ? '${_timeCriado!.totalMembros}/2 membros'
                          : '0/2 membros',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14),
                    ),
                    if (_estaCompleto) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('✅ Dupla completa!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (!_timeFoiCriado) ...[
                _label('Nome do time'),
                const SizedBox(height: 8),
                _campo(_nomeCtrl, 'Digite o nome do time', Icons.groups_rounded),
                const SizedBox(height: 16),
                _label('Descrição (opcional)'),
                const SizedBox(height: 8),
                _campo(_descCtrl, 'Ex: Dupla para torneios de beach tennis',
                    Icons.description_rounded),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _carregando ? null : _criarTime,
                    icon: _carregando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.groups_rounded, color: Colors.white),
                    label: Text(
                      _carregando ? 'Criando...' : 'Criar time',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kLaranja,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],

              if (_timeFoiCriado) ...[
                if (_estaCompleto)
                  _bannerCompleto(),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: kTextPri.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link_rounded,
                          color: kTextPri
                              .withValues(alpha: 0.3),
                          size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _estaCompleto
                              ? 'Link desativado — dupla completa'
                              : _linkConvite,
                          style: TextStyle(
                            fontSize: 13,
                            color: _estaCompleto
                                ? kTextPri
                                    .withValues(alpha: 0.3)
                                : kTextPri,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                if (!_estaCompleto) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _copiarLink,
                      icon: const Icon(Icons.copy_rounded,
                          color: kLaranja),
                      label: const Text('Copiar link',
                          style: TextStyle(color: kLaranja)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: kLaranja),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enviarWhatsApp,
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: const Text('Enviar pelo WhatsApp',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _carregando ? null : _regerarConvite,
                      icon: Icon(Icons.refresh_rounded,
                          color: kTextPri
                              .withValues(alpha: 0.4)),
                      label: Text('Gerar novo link',
                          style: TextStyle(
                              color: kTextPri
                                  .withValues(alpha: 0.4),
                              fontSize: 13)),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                if (!_estaCompleto)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: kLaranja
                              .withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_rounded,
                            color: kLaranja, size: 28),
                        const SizedBox(width: 12),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withValues(alpha: 0.7)),
                            children: [
                              const TextSpan(
                                  text: 'Beach Tennis é uma dupla!\nVocê ainda tem '),
                              TextSpan(
                                text:
                                    '${2 - (_timeCriado?.totalMembros ?? 0)} vaga',
                                style: const TextStyle(
                                    color: kLaranja,
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' disponível.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Membros',
                        style: TextStyle(
                            color: Color(0xFFCA5D03),
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0E816),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_timeCriado!.totalMembros}/2',
                          style: const TextStyle(
                              color: kTextPri,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ..._timeCriado!.membros.map(
                  (m) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              m.idJogador == _timeCriado!.idJogadorDono
                                  ? const Color(0xFFD0E816)
                                  : kLaranja,
                          child: Text(m.nomeUsuario[0].toUpperCase(),
                              style: const TextStyle(
                                  color: kTextPri,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.nomeUsuario,
                                  style: const TextStyle(
                                      color: kTextPri,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                m.idJogador == _timeCriado!.idJogadorDono
                                    ? 'Capitão'
                                    : 'Parceiro',
                                style: TextStyle(
                                  color: m.idJogador ==
                                          _timeCriado!.idJogadorDono
                                      ? const Color(0xFFD0E816)
                                      : kTextPri
                                          .withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerCompleto() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2EA043).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2EA043).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF2EA043)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sua dupla está completa! O link de convite foi desativado.',
              style: TextStyle(color: Color(0xFF2EA043), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String txt) => Text(txt,
      style: const TextStyle(
          color: Color(0xFF241514),
          fontSize: 15,
          fontWeight: FontWeight.w600));

  Widget _campo(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: ctrl,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: kTextPri),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: kTextPri.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon,
              color: kTextPri.withValues(alpha: 0.3)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: kLaranja, width: 1.5),
          ),
        ),
      ),
    );
  }
}