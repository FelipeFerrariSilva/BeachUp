import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/provider/auth_provider.dart';
import 'package:flutter_application_1/screen/home/start_screen.dart';
import 'package:flutter_application_1/screen/home/login/recuperar_senha_screen.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _editandoNome  = false;
  bool _editandoEmail = false;
  bool _salvandoNome  = false;
  bool _salvandoEmail = false;
  bool _carregando    = true;
  bool _salvandoFoto  = false;
  String? _fotoUrl;

  final _nomeController  = TextEditingController();
  final _emailController = TextEditingController();

  int?   _idPerfil;
  String _role = '';

  @override
  void initState() { super.initState(); _carregarDados(); }

  @override
  void dispose() { _nomeController.dispose(); _emailController.dispose(); super.dispose(); }

  Future<void> _carregarDados() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final payload = _decodeJwt(token);
      _role = payload['role'] ?? '';
      final endpoint = _role == 'ROLE_EMPRESA'
          ? '${ApiConfig.baseUrl}/empresa/me'
          : '${ApiConfig.baseUrl}/jogador/me';
      final res = await http.get(Uri.parse(endpoint), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200 && mounted) {
        final j = jsonDecode(res.body);
        setState(() {
          _idPerfil = j['id'];
          _nomeController.text = j['usuario']?['nome'] ?? '';
          _emailController.text = j['usuario']?['email'] ?? '';
          _fotoUrl = j['usuario']?['fotoUrl'];
        });
      }
    } catch (e) { debugPrint('Erro ao carregar dados: $e'); }
    finally { if (mounted) setState(() => _carregando = false); }
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) { return {}; }
  }

  Future<void> _salvarNome() async {
    if (_nomeController.text.trim().isEmpty) { _snack('O nome não pode ficar vazio', erro: true); return; }
    setState(() => _salvandoNome = true);
    try {
      await _putPerfil(nome: _nomeController.text.trim());
      if (mounted) { setState(() => _editandoNome = false); _snack('Nome atualizado!'); }
    } catch (e) { _snack(e.toString().replaceFirst('Exception: ', ''), erro: true); }
    finally { if (mounted) setState(() => _salvandoNome = false); }
  }

  Future<void> _salvarEmail() async {
    if (!_emailController.text.contains('@')) { _snack('Email inválido', erro: true); return; }
    setState(() => _salvandoEmail = true);
    try {
      await _putPerfil(email: _emailController.text.trim());
      if (mounted) { setState(() => _editandoEmail = false); _snack('Email atualizado!'); }
    } catch (e) { _snack(e.toString().replaceFirst('Exception: ', ''), erro: true); }
    finally { if (mounted) setState(() => _salvandoEmail = false); }
  }

  Future<void> _putPerfil({String? nome, String? email}) async {
    final token = await AuthService.getToken();
    if (token == null || _idPerfil == null) throw Exception('Não autenticado');
    final endpoint = _role == 'ROLE_EMPRESA'
        ? '${ApiConfig.baseUrl}/empresa/$_idPerfil'
        : '${ApiConfig.baseUrl}/jogador/$_idPerfil';
    final request = http.MultipartRequest('PUT', Uri.parse(endpoint))
      ..headers['Authorization'] = 'Bearer $token';
    final dados = <String, dynamic>{
      'nome': nome ?? _nomeController.text.trim(),
      'email': email ?? _emailController.text.trim(),
    };
    request.files.add(http.MultipartFile.fromString('dados', jsonEncode(dados), contentType: MediaType('application', 'json')));
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      final j = jsonDecode(response.body);
      if (j['accessToken'] != null) await AuthService.salvarToken(j['accessToken'], j['refreshToken']);
      return;
    }
    try {
      final j = jsonDecode(response.body);
      throw Exception(j['message'] ?? j['error'] ?? 'Erro ao salvar');
    } catch (_) { throw Exception('Erro ao salvar (${response.statusCode})'); }
  }

  Future<void> _selecionarFoto() async {
    final foto = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
       maxHeight: 1080,
        );
    if (foto == null || !mounted) return;
    setState(() => _salvandoFoto = true);
    try {
      final token = await AuthService.getToken();
      if (token == null || _idPerfil == null) throw Exception('Não autenticado');
      final bytes = await foto.readAsBytes();
      final ext = foto.path.split('.').last.toLowerCase();
      final base = ApiConfig.baseUrl;
      final id = _idPerfil;
      final endpoint = _role == 'ROLE_EMPRESA'
          ? '$base/empresa/$id'
          : '$base/jogador/$id';
      final request = http.MultipartRequest('PUT', Uri.parse(endpoint))
        ..headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromString(
          'dados',
          jsonEncode({'nome': _nomeController.text.trim(), 'email': _emailController.text.trim()}),
          contentType: MediaType('application', 'json')));
      request.files.add(http.MultipartFile.fromBytes(
          'foto', bytes,
          filename: foto.name,
          contentType: MediaType('image', ext == 'jpg' ? 'jpeg' : ext)));
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        final j = jsonDecode(response.body);
        if (j['accessToken'] != null) {
          await AuthService.salvarToken(j['accessToken'], j['refreshToken']);
        }
        final novaFotoUrl = j['usuario']?['fotoUrl'] ?? j['fotoUrl'];
        if (novaFotoUrl != null && novaFotoUrl.toString().isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_foto_url', novaFotoUrl.toString());
        }
        if (mounted) {
          setState(() => _fotoUrl = novaFotoUrl?.toString());
          _snack('Foto atualizada!');
        }
      } else {
        String msg = 'Erro ${response.statusCode}: ${response.body}';
        throw Exception(msg);
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), erro: true);
    } finally {
      if (mounted) setState(() => _salvandoFoto = false);
    }
  }

  void _confirmarDesativarConta(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Desativar conta'),
        content: const Text('Sua conta ficará inativa até você fazer login novamente. Tem certeza que deseja continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.sair();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => StartScreen()), (r) => false);
            },
            child: const Text('Desativar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: erro ? Colors.red[700] : kLaranja));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: appBg(context),
      appBar: AppBar(
        backgroundColor: appBg(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPri, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Configurações',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: appTextPri(context))),
        actions: [const ProfileAction(), const SizedBox(width: 8)],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: kLaranja))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tituloSecao('CONTA'),
                  const SizedBox(height: 8),
                  _secaoConta(),
                  const SizedBox(height: 20),
                  _tituloSecao('ZONA DE RISCO'),
                  const SizedBox(height: 8),
                  _secaoZonaDeRisco(auth),
                ],
              ),
            ),
    );
  }

  Widget _tituloSecao(String texto) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(texto, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTextSec, letterSpacing: 0.8)),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: appCard(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
    ),
    child: Column(children: children),
  );

  Widget _divisor() => Divider(color: kBorder, height: 1, indent: 20, endIndent: 20);

  Widget _secaoConta() {
    final fotoAbsoluta = _fotoUrl != null && _fotoUrl!.isNotEmpty
        ? (_fotoUrl!.startsWith('http') ? _fotoUrl! : '\${ApiConfig.baseUrl}\$_fotoUrl')
        : null;
    return _card(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: kLaranja.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.photo_camera_outlined, color: kLaranja, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Foto de perfil', style: TextStyle(fontSize: 11, color: kTextSec)),
              const SizedBox(height: 2),
              if (fotoAbsoluta != null)
                ClipOval(child: Image.network(fotoAbsoluta, width: 40, height: 40, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, color: kTextSec)))
              else
                const Text('Nenhuma foto', style: TextStyle(fontSize: 14, color: kTextPri)),
            ]),
          ),
          _salvandoFoto
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kLaranja))
              : TextButton(
                  onPressed: _selecionarFoto,
                  child: const Text('Alterar', style: TextStyle(color: kLaranja, fontSize: 13)),
                ),
        ]),
      ),
      _divisor(),
      _itemEditavel(
        icon: Icons.person_outline,
        label: 'Nome',
        valor: _nomeController.text,
        editando: _editandoNome,
        salvando: _salvandoNome,
        onEditar: () => setState(() => _editandoNome = true),
        onCancelar: () => setState(() => _editandoNome = false),
        onSalvar: _salvarNome,
        campo: TextField(controller: _nomeController, autofocus: true, decoration: _decoracaoCampo('Digite seu nome')),
      ),
      _divisor(),
      _itemEditavel(
        icon: Icons.mail_outline,
        label: 'Email',
        valor: _emailController.text,
        editando: _editandoEmail,
        salvando: _salvandoEmail,
        onEditar: () => setState(() => _editandoEmail = true),
        onCancelar: () => setState(() => _editandoEmail = false),
        onSalvar: _salvarEmail,
        campo: TextField(controller: _emailController, autofocus: true, keyboardType: TextInputType.emailAddress, decoration: _decoracaoCampo('Digite seu email')),
      ),
      _divisor(),
      _itemSenhaBotao(),
    ]);
  }

  Widget _itemEditavel({
    required IconData icon,
    required String label,
    required String valor,
    required bool editando,
    required bool salvando,
    required VoidCallback onEditar,
    required VoidCallback onCancelar,
    required Future<void> Function() onSalvar,
    required Widget campo,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: kLaranja.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: kLaranja, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: editando
                  ? campo
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: const TextStyle(fontSize: 11, color: kTextSec)),
                      const SizedBox(height: 2),
                      Text(valor.isEmpty ? 'Não informado' : valor, style: const TextStyle(fontSize: 14, color: kTextPri)),
                    ]),
            ),
            if (!editando)
              IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: kTextSec), onPressed: onEditar),
          ]),
          if (editando) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: salvando ? null : onCancelar,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: kBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancelar', style: TextStyle(color: kTextSec)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: salvando ? null : onSalvar,
                  style: ElevatedButton.styleFrom(backgroundColor: kLaranja, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: salvando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Salvar', style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _itemSenhaBotao() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecuperarSenhaScreen())),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: kLaranja.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.lock_outline, color: kLaranja, size: 18),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Text('Alterar senha', style: TextStyle(fontSize: 15, color: kTextPri, fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right_rounded, color: kTextSec, size: 20),
        ]),
      ),
    );
  }

  InputDecoration _decoracaoCampo(String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: kOffWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
  );


  Widget _secaoZonaDeRisco(AuthProvider auth) {
    return _card(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => _confirmarDesativarConta(auth),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_off_outlined, size: 18, color: Colors.red),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Desativar conta', style: TextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Sua conta ficará inativa até você fazer login novamente.', style: TextStyle(fontSize: 12, color: kTextSec)),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }
}