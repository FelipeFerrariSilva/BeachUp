import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/model/time.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/service/time_service.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DetalheTimeScreen extends StatefulWidget {
  final TimeModel time;
  const DetalheTimeScreen({super.key, required this.time});

  @override
  State<DetalheTimeScreen> createState() => _DetalheTimeScreenState();
}

class _DetalheTimeScreenState extends State<DetalheTimeScreen> {
  late TimeModel _time;
  bool _carregando = false;

  String? _minhaFotoUrl;
  int? _meuId;

  final Map<int, String?> _fotosMembros = {};

  @override
  void initState() {
    super.initState();
    _time = widget.time;
    _carregarMeusDados();
    _carregarFotosMembros();
  }

  Future<void> _carregarFotosMembros() async {
    final token = await AuthService.getToken();
    for (final m in _time.membros) {
      if (m.status.toUpperCase() != 'ACEITO') continue;
      if (_fotosMembros.containsKey(m.idJogador)) continue;
      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/jogador/${m.idJogador}'),
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        );
        if (res.statusCode == 200) {
          final j = jsonDecode(res.body);
          final fotoUrl = j['usuario']?['fotoUrl'] as String?;
          if (mounted) {
            setState(() {
              _fotosMembros[m.idJogador] = (fotoUrl != null && fotoUrl.isNotEmpty)
                  ? (fotoUrl.startsWith('http') ? fotoUrl : ApiConfig.baseUrl + fotoUrl)
                  : null;
            });
          }
        }
      } catch (_) {
      }
    }
  }

  Future<void> _carregarMeusDados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await AuthService.getToken();
      if (token != null) {
        final res = await http.get(
          Uri.parse(ApiConfig.baseUrl + '/jogador/me'),
          headers: {'Authorization': 'Bearer ' + token},
        );
        if (res.statusCode == 200) {
          final j = jsonDecode(res.body);
          final fotoUrl = j['usuario']?['fotoUrl'] as String?;
          if (mounted) {
            setState(() {
              _meuId = j['id'] as int?;
              if (fotoUrl != null && fotoUrl.isNotEmpty) {
                _minhaFotoUrl = fotoUrl.startsWith('http')
                    ? fotoUrl
                    : ApiConfig.baseUrl + fotoUrl;
                prefs.setString('user_foto_url', fotoUrl);
              } else {
                final cached = prefs.getString('user_foto_url');
                if (cached != null && cached.isNotEmpty) {
                  _minhaFotoUrl = cached.startsWith('http')
                      ? cached
                      : ApiConfig.baseUrl + cached;
                }
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  bool get _estaCompleto => _time.estaCompleto;

  String get _linkConvite {
    if (_time.urlConvite == null || _time.urlConvite!.isEmpty) return '';
    return 'https://www.beachup.com.br/aceitar-convite/${_time.urlConvite}';
  }

  String get _mensagemConvite =>
      'Ei! Entra no meu time *${_time.nome}* no BeachUp 🏖️🎾\n\n$_linkConvite';

  Future<void> _regerarLink() async {
    setState(() => _carregando = true);
    try {
      final novoToken = await TimeService.regerarConvite(_time.id);
      if (!mounted) return;
      setState(() {
        _time = TimeModel(
          id: _time.id,
          nome: _time.nome,
          descricao: _time.descricao,
          urlConvite: novoToken,
          idJogadorDono: _time.idJogadorDono,
          membros: _time.membros,
        );
        _carregando = false;
      });
      _snack('Novo link gerado!');
    } catch (_) {
      setState(() => _carregando = false);
      _snack('Erro ao gerar novo link', erro: true);
    }
  }

  void _copiarLink() {
    if (_linkConvite.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _linkConvite));
    _snack('Link copiado!');
  }

  Future<void> _enviarWhatsApp() async {
    if (_linkConvite.isEmpty) return;
    final msg = Uri.encodeComponent(_mensagemConvite);
    final uri = Uri.parse('https://wa.me/?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('Não foi possível abrir o WhatsApp', erro: true);
    }
  }

  void _snack(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? Colors.red : kLaranja,
    ));
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.groups_rounded,
                          color: kLaranja, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(_time.nome,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    if (_time.descricao != null &&
                        _time.descricao!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_time.descricao!,
                            style: TextStyle(
                                color: Colors.white
                                    .withValues(alpha: 0.8),
                                fontSize: 13)),
                      ),
                    const SizedBox(height: 4),
                    Text('${_time.totalMembros}/2 membros',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14)),
                    if (_estaCompleto) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(alpha: 0.25),
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

              const SizedBox(height: 20),

              if (_estaCompleto)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EA043).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF2EA043)
                            .withValues(alpha: 0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF2EA043)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sua dupla está completa! O link de convite foi desativado.',
                        style: TextStyle(
                            color: Color(0xFF2EA043), fontSize: 13),
                      ),
                    ),
                  ]),
                ),

              if (!_estaCompleto && _linkConvite.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: kTextPri.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.link_rounded,
                        color: kTextPri.withValues(alpha: 0.3),
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _linkConvite,
                        style: const TextStyle(
                            fontSize: 13, color: kTextPri),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _copiarLink,
                    icon: const Icon(Icons.copy_rounded,
                        color: kLaranja),
                    label: const Text('Copiar link',
                        style: TextStyle(color: kLaranja)),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
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
                    icon: const Icon(Icons.share_rounded,
                        color: Colors.white),
                    label: const Text('Enviar pelo WhatsApp',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                Center(
                  child: TextButton.icon(
                    onPressed: _carregando ? null : _regerarLink,
                    icon: Icon(Icons.refresh_rounded,
                        color: kTextPri.withValues(alpha: 0.4),
                        size: 16),
                    label: Text('Gerar novo link',
                        style: TextStyle(
                            color: kTextPri.withValues(alpha: 0.4),
                            fontSize: 13)),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: kLaranja.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.groups_rounded,
                        color: kLaranja, size: 28),
                    const SizedBox(width: 12),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 13,
                            color:
                                Colors.black.withValues(alpha: 0.7)),
                        children: [
                          const TextSpan(
                              text:
                                  'Beach Tennis é uma dupla!\nVocê ainda tem '),
                          TextSpan(
                            text:
                                '${2 - _time.totalMembros} vaga',
                            style: const TextStyle(
                                color: kLaranja,
                                fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' disponível.'),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],

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
                    child: Text('${_time.totalMembros}/2',
                        style: const TextStyle(
                            color: kTextPri,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ..._time.membros
                  .where((m) =>
                      m.status.toUpperCase() == 'ACEITO')
                  .map((m) {
                final ehDono = m.idJogador == _time.idJogadorDono;
                final eMeu = m.idJogador == _meuId;
                final fotoMembro = eMeu
                    ? (_minhaFotoUrl ?? _fotosMembros[m.idJogador])
                    : _fotosMembros[m.idJogador];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: ehDono
                          ? const Color(0xFFD0E816)
                          : kLaranja,
                      backgroundImage: fotoMembro != null
                          ? NetworkImage(fotoMembro)
                          : null,
                      child: fotoMembro == null
                          ? Text(
                              m.nomeUsuario.isNotEmpty
                                  ? m.nomeUsuario[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: kTextPri,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(m.nomeUsuario,
                              style: const TextStyle(
                                  color: kTextPri,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            ehDono ? 'Capitão' : 'Parceiro',
                            style: TextStyle(
                              color: ehDono
                                  ? const Color(0xFFD0E816)
                                  : kTextPri.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                );
              }),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}