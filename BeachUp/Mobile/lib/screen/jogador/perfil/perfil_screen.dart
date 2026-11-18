import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/provider/auth_provider.dart';
import 'package:flutter_application_1/screen/home/configuracoes_screen.dart';
import 'package:flutter_application_1/screen/home/start_screen.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilJogadorScreen extends StatefulWidget {
  const PerfilJogadorScreen({super.key});

  @override
  State<PerfilJogadorScreen> createState() => _PerfilJogadorScreenState();
}

class _PerfilJogadorScreenState extends State<PerfilJogadorScreen> {
  String _nome  = '';
  String _email = '';
  String? _fotoUrl;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/jogador/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final j = jsonDecode(res.body);
        final fotoUrl = j['usuario']?['fotoUrl'] as String?;
        if (fotoUrl != null && fotoUrl.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_foto_url', fotoUrl);
        }
        setState(() {
          _nome    = j['usuario']?['nome'] ?? '';
          _email   = j['usuario']?['email'] ?? '';
          _fotoUrl = fotoUrl;
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final inicial = _nome.isNotEmpty
        ? _nome[0].toUpperCase()
        : _email.isNotEmpty
            ? _email[0].toUpperCase()
            : 'J';

    final fotoAbsoluta = _fotoUrl != null && _fotoUrl!.isNotEmpty
        ? (_fotoUrl!.startsWith('http')
            ? _fotoUrl!
            : '${ApiConfig.baseUrl}$_fotoUrl')
        : null;

    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: AppBar(
        backgroundColor: kOffWhite,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPri, size: 20),
                onPressed: () => Navigator.pop(context))
            : null,
        title: const Text('Perfil',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kTextPri)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                child: Row(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.25),
                        border: Border.all(color: Colors.white, width: 2.5),
                        image: fotoAbsoluta != null
                            ? DecorationImage(
                                image: NetworkImage(fotoAbsoluta),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: fotoAbsoluta == null
                          ? Center(
                              child: Text(inicial,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700)))
                          : null,
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _carregando ? 'Carregando...'
                                : _nome.isNotEmpty ? _nome : _email,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text('Jogador',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _menuCard([
                _itemMenu(
                  icon: Icons.settings_rounded,
                  label: 'Configurações',
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ConfiguracoesScreen()));
                    _carregar();
                  },
                ),
              ]),
              const SizedBox(height: 12),

              _menuCard([
                _itemMenu(
                  icon: Icons.logout_rounded,
                  label: 'Sair',
                  cor: Colors.red,
                  onTap: () => _confirmarSair(context, auth),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
          ],
        ),
        child: Column(children: children),
      );

  Widget _itemMenu({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? cor,
  }) {
    final c = cor ?? kTextPri;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (cor ?? kLaranja).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cor ?? kLaranja, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cor ?? kTextPri))),
          Icon(Icons.chevron_right_rounded,
              color: c.withValues(alpha: 0.4), size: 20),
        ]),
      ),
    );
  }

  void _confirmarSair(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              auth.sair();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => StartScreen()),
                (_) => false,
              );
            },
            child: const Text('Sair',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}