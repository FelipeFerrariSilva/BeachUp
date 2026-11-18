import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/auth_provider.dart';
import 'package:flutter_application_1/screen/home/configuracoes_screen.dart';
import 'package:flutter_application_1/screen/home/cadastro/cadastro_usuario_screen.dart';
import 'package:flutter_application_1/screen/empresa/perfil/perfil_screen.dart';
import 'package:flutter_application_1/screen/home/start_screen.dart';
import 'package:flutter_application_1/screen/jogador/perfil/perfil_screen.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/screen/jogador/home_screen.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class CustomAppBarPerfil extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final List<Widget>? extraActions;
  final dynamic fotoBytes; 

  const CustomAppBarPerfil({super.key, this.scaffoldKey, this.extraActions, this.fotoBytes});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return AppBar(
      backgroundColor: appBg(context),
      elevation: 0,
      automaticallyImplyLeading: false,
      iconTheme: const IconThemeData(color: kTextPri),
      title: Image.asset('assets/images/logo1.png', height: 36),
      actions: [
        if (extraActions != null) ...extraActions!,
        if (!auth.estaLogado)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CadastroUsuario())),
              style: ElevatedButton.styleFrom(
                backgroundColor: kLaranja,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Cadastre-se',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          )
        else
          _AvatarAction(fotoBytes: fotoBytes),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AvatarAction extends StatelessWidget {
  final dynamic fotoBytes;
  const _AvatarAction({this.fotoBytes});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: _ProfilePopup(auth: auth, fotoBytes: fotoBytes),
    );
  }
}

class ProfileAction extends StatelessWidget {
  final dynamic fotoBytes;
  const ProfileAction({super.key, this.fotoBytes});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return _ProfilePopup(auth: auth, fotoBytes: fotoBytes);
  }
}

class _ProfilePopup extends StatefulWidget {
  final AuthProvider auth;
  final dynamic fotoBytes;
  const _ProfilePopup({required this.auth, this.fotoBytes});

  @override
  State<_ProfilePopup> createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<_ProfilePopup> {
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _carregarFoto();
  }

  Future<void> _carregarFoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('user_foto_url');
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() => _fotoUrl = cached);
      }

      final token = await AuthService.getToken();
      if (token == null) return;
      final endpoint = widget.auth.isEmpresa ? '/empresa/me' : '/jogador/me';
      final url = Uri.parse(ApiConfig.baseUrl + endpoint);
      final res = await http.get(url,
          headers: {'Authorization': 'Bearer ' + token});
      if (res.statusCode == 200 && mounted) {
        final j = jsonDecode(res.body);
        final fotoUrl = j['usuario']?['fotoUrl'] as String?;
        if (fotoUrl != null && fotoUrl.isNotEmpty) {
          await prefs.setString('user_foto_url', fotoUrl);
          if (mounted) setState(() => _fotoUrl = fotoUrl);
        } else {
          await prefs.remove('user_foto_url');
          if (mounted) setState(() => _fotoUrl = null);
        }
      }
    } catch (_) {}
  }

  String? get _fotoAbsoluta {
    if (_fotoUrl == null || _fotoUrl!.isEmpty) return null;
    if (_fotoUrl!.startsWith('http')) return _fotoUrl;
    return ApiConfig.baseUrl + _fotoUrl!;
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    return PopupMenuButton(
      offset: const Offset(0, 48),
      color: appCard(context),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: BorderSide(color: appBorder(context))),
      elevation: 4,
      itemBuilder: (context) => <PopupMenuEntry>[
        PopupMenuItem(
          enabled: false,
          child: Text(auth.emailUsuario,
              style: const TextStyle(fontSize: 12, color: kTextSec, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            final tela = auth.isEmpresa
                ? const PerfilEmpresaScreen()
                : PerfilJogadorScreen();
            Future.microtask(
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => tela)));
          },
          child: const _MenuItem(icon: Icons.person_outline, label: 'Meu Perfil'),
        ),
        PopupMenuItem(
          onTap: () => Future.microtask(() => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()))),
          child: const _MenuItem(icon: Icons.settings_outlined, label: 'Configurações'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            auth.sair();
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const StartScreen()), (route) => false);
          },
          child: const _MenuItem(icon: Icons.logout, label: 'Sair', cor: Colors.red),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kLaranja,
          shape: BoxShape.circle,
          border: Border.all(color: kLaranja.withValues(alpha: 0.3), width: 2),
          image: _fotoAbsoluta != null
              ? DecorationImage(image: NetworkImage(_fotoAbsoluta!), fit: BoxFit.cover)
              : null,
        ),
        alignment: Alignment.center,
        child: _fotoAbsoluta == null
            ? Text(
                auth.emailUsuario.isNotEmpty ? auth.emailUsuario[0].toUpperCase() : 'U',
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              )
            : null,
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? cor;
  const _MenuItem({required this.icon, required this.label, this.cor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: cor ?? kTextSec),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(fontSize: 14, color: cor ?? kTextPri)),
    ]);
  }
}