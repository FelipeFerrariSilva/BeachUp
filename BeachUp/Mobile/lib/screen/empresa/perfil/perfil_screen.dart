import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/provider/auth_provider.dart';
import 'package:flutter_application_1/screen/home/configuracoes_screen.dart';
import 'package:flutter_application_1/screen/home/start_screen.dart';
import 'package:flutter_application_1/service/arena_service.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/model/arena.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';

class PerfilEmpresaScreen extends StatefulWidget {
  const PerfilEmpresaScreen({super.key});

  @override
  State<PerfilEmpresaScreen> createState() => _PerfilEmpresaScreenState();
}

class _PerfilEmpresaScreenState extends State<PerfilEmpresaScreen> {
  String? _fotoUrl;
  List<Arena> suasArenas = [];
  String _nomeEmpresa = '';
  String _cnpj = '';
  String _plano = '';
  bool _carregando = true;

  @override
  void initState() { super.initState(); _carregarDados(); }

  Future<void> _carregarDados() async {
    try {
      final token = await AuthService.getToken();
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/empresa/me'), headers: {'Authorization': 'Bearer $token'}),
        ArenaService.getMinhas(),
      ]);
      final res = responses[0] as http.Response;
      if (res.statusCode == 200 && mounted) {
        final j = jsonDecode(res.body);
        setState(() {
          _cnpj = j['cnpj'] ?? '';
          _plano = j['planoAtual'] ?? '';
          _nomeEmpresa = j['usuario']?['nome'] ?? '';
          _fotoUrl = j['usuario']?['fotoUrl'];
        });
      }
      if (mounted) setState(() => suasArenas = responses[1] as List<Arena>);
    } catch (e) { debugPrint('Erro ao carregar dados empresa: $e'); }
    finally { if (mounted) setState(() => _carregando = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final inicial = _nomeEmpresa.isNotEmpty
        ? _nomeEmpresa[0].toUpperCase()
        : auth.emailUsuario.isNotEmpty ? auth.emailUsuario[0].toUpperCase() : 'E';

    return Scaffold(
      backgroundColor: appBg(context),
      appBar: AppBar(
        backgroundColor: appBg(context),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPri, size: 20),
                onPressed: () => Navigator.pop(context))
            : null,
        // Logo centralizada quando tem back, à esquerda quando não tem
        title: Image.asset('assets/images/logo1.png', height: 34),
        actions: const [
          ProfileAction(),
          SizedBox(width: 12),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: kLaranja))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kLaranja, Color(0xFFFF9240)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appCard(context).withValues(alpha: 0.25),
                          border: Border.all(color: Colors.white, width: 2.5),
                          image: (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(_fotoUrl!.startsWith('http')
                                      ? _fotoUrl!
                                      : '${ApiConfig.baseUrl}$_fotoUrl'),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: (_fotoUrl == null || _fotoUrl!.isEmpty)
                            ? Center(child: Text(inicial, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_nomeEmpresa.isNotEmpty ? _nomeEmpresa : auth.emailUsuario,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(_plano.isNotEmpty ? 'Plano $_plano' : 'Empresa',
                                style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Métricas
                  Row(children: [
                    _metricaCard('${suasArenas.length}', 'Arenas'),
                    const SizedBox(width: 10),
                    _metricaCard(_plano.isNotEmpty ? _plano : 'Free', 'Plano'),
                    const SizedBox(width: 10),
                    _metricaCard('Ativa', 'Status'),
                  ]),
                  const SizedBox(height: 20),

                  _menuCard([
                    _itemMenu(icon: Icons.settings_rounded, label: 'Configurações',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()))),
                    _divisor(),
                    _itemMenu(icon: Icons.badge_outlined, label: 'Dados da empresa',
                        sublabel: _cnpj.isNotEmpty ? _formatarCnpj(_cnpj) : null,
                        onTap: () {}),
                  ]),
                  const SizedBox(height: 12),
                  _menuCard([
                    _itemMenu(icon: Icons.logout_rounded, label: 'Sair', cor: Colors.red,
                        onTap: () => _confirmarSair(context, auth)),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _metricaCard(String valor, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: appCard(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder),
        ),
        child: Column(children: [
          Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kLaranja)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: kTextSec)),
        ]),
      ),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: appCard(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(children: children),
    );
  }

  Widget _itemMenu({required IconData icon, required String label, required VoidCallback onTap, Color? cor, String? sublabel}) {
    final c = cor ?? kTextPri;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: (cor ?? kLaranja).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: cor ?? kLaranja, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c)),
            if (sublabel != null) Text(sublabel, style: const TextStyle(fontSize: 12, color: kTextSec)),
          ])),
          Icon(Icons.chevron_right_rounded, color: c.withValues(alpha: 0.4), size: 20),
        ]),
      ),
    );
  }

  Widget _divisor() => Divider(height: 1, indent: 70, endIndent: 20, color: kBorder);

  void _confirmarSair(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              auth.sair();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => StartScreen()), (_) => false);
            },
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatarCnpj(String cnpj) {
    final c = cnpj.replaceAll(RegExp(r'\D'), '');
    if (c.length != 14) return cnpj;
    return '${c.substring(0,2)}.${c.substring(2,5)}.${c.substring(5,8)}/${c.substring(8,12)}-${c.substring(12)}';
  }
}