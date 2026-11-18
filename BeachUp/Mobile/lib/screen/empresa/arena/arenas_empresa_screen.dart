import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/model/arena.dart';
import 'package:flutter_application_1/service/arena_service.dart';
import 'package:flutter_application_1/service/quadra_service.dart';
import 'package:flutter_application_1/service/pagamento_service.dart';
import 'package:flutter_application_1/screen/empresa/arena/cadastro_arena_screen.dart';
import 'package:flutter_application_1/screen/empresa/arena/cadastro_quadra_screen.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

String _fotoAbsoluta(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '${ApiConfig.baseUrl}$url';
}

class MinhasArenaScreen extends StatefulWidget {
  final bool standalone;
  const MinhasArenaScreen({super.key, this.standalone = false});

  @override
  State<MinhasArenaScreen> createState() => _MinhasArenaScreenState();
}

class _MinhasArenaScreenState extends State<MinhasArenaScreen> {
  List<Arena> _arenas = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final arenas = await ArenaService.getMinhas();
      setState(() { _arenas = arenas; _loading = false; });
    } catch (_) {
      setState(() { _erro = 'Não foi possível carregar suas arenas.'; _loading = false; });
    }
  }

  Future<void> _iniciarNovaArena() async {
    final continuar = await _mostrarDialogoMercadoPago();
    if (continuar != true) return;
    final criou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CriarArenaScreen()),
    );
    if (criou == true) _carregar();
  }

  Future<bool?> _mostrarDialogoMercadoPago() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          bool conectando = false;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [
              Icon(Icons.account_balance_wallet_outlined, color: kLaranja),
              SizedBox(width: 10),
              Expanded(child: Text('Conecte o Mercado Pago', style: TextStyle(fontSize: 16))),
            ]),
            content: const Text(
              'Para receber os pagamentos das reservas feitas nesta arena, sua empresa '
              'precisa estar conectada a uma conta do Mercado Pago.\n\n'
              'Você pode conectar agora ou continuar e conectar depois — mas as reservas '
              'só poderão ser pagas após a conexão ser concluída.',
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              Row(children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kLaranja,
                    side: const BorderSide(color: kLaranja),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: conectando
                      ? null
                      : () async {
                          setLocal(() => conectando = true);
                          await _conectarMercadoPago();
                          setLocal(() => conectando = false);
                        },
                  child: conectando
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kLaranja))
                      : const Text('Conectar agora'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLaranja,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Continuar', style: TextStyle(color: Colors.white)),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Future<void> _conectarMercadoPago() async {
    try {
      final url = await PagamentoService.obterUrlConexaoMercadoPago();
      if (!mounted) return;
      await launchUrl(
        Uri.parse(url),
        customTabsOptions: const CustomTabsOptions(
          shareState: CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,
        ),
        safariVCOptions: const SafariViewControllerOptions(barCollapsingEnabled: true),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red[700],
        content: Text(e.toString().replaceFirst('Exception: ', '')),
      ));
    }
  }

  Future<void> _excluirArena(Arena arena) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir arena'),
        content: Text('Tem certeza que deseja excluir "${arena.nome}"?\nTodas as quadras serão removidas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ArenaService.excluir(arena.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arena excluída'), backgroundColor: kLaranja),
      );
      _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBg(context),
      appBar: const CustomAppBarPerfil(),
      body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quadras',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: kTextPri,
                        letterSpacing: -0.5)),
                GestureDetector(
                  onTap: _iniciarNovaArena,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: kLaranja,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Nova arena',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildConteudo()),
        ],
      ),
    ),
    );
  }

  Widget _buildConteudo() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kLaranja));
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: kTextSec, size: 48),
            const SizedBox(height: 12),
            Text(_erro!, style: const TextStyle(color: kTextSec)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kLaranja, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _carregar,
              child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_arenas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stadium_outlined, color: kTextSec, size: 48),
            const SizedBox(height: 12),
            const Text('Nenhuma arena cadastrada.', style: TextStyle(color: kTextSec)),
            const SizedBox(height: 4),
            const Text('Toque em "Nova arena" para começar.',
                style: TextStyle(color: kTextSec, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      color: kLaranja,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _arenas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _CardArena(
          arena: _arenas[i],
          onGerenciar: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => QuadrasArenaEmpresaScreen(arena: _arenas[i])));
            _carregar();
          },
          onEditar: () async {
            final editou = await Navigator.push<bool>(context,
                MaterialPageRoute(builder: (_) => CriarArenaScreen(arenaParaEditar: _arenas[i])));
            if (editou == true) _carregar();
          },
          onExcluir: () => _excluirArena(_arenas[i]),
        ),
      ),
    );
  }
}

class _CardArena extends StatelessWidget {
  final Arena arena;
  final VoidCallback onGerenciar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _CardArena({required this.arena, required this.onGerenciar, required this.onEditar, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: kLaranja.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.stadium_outlined, color: kLaranja, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(arena.nome,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: kTextPri)),
              ),
              PopupMenuButton<String>(
                color: appCard(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                icon: const Icon(Icons.more_vert, color: kTextSec),
                onSelected: (v) {
                  if (v == 'editar') onEditar();
                  if (v == 'excluir') onExcluir();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit_outlined, color: kLaranja, size: 18), const SizedBox(width: 10), const Text('Editar arena')])),
                  PopupMenuItem(value: 'excluir', child: Row(children: [const Icon(Icons.delete_outline, color: Colors.red, size: 18), const SizedBox(width: 10), const Text('Excluir', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          if (arena.localizacao.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 13, color: kTextSec),
              const SizedBox(width: 4),
              Text(arena.localizacao, style: const TextStyle(color: kTextSec, fontSize: 12)),
            ]),
          ],
          if (arena.descricao != null && arena.descricao!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(arena.descricao!, style: const TextStyle(color: kTextSec, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kLaranja,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: onGerenciar,
              child: const Text('Gerenciar quadras',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class QuadrasArenaEmpresaScreen extends StatefulWidget {
  final Arena arena;
  const QuadrasArenaEmpresaScreen({super.key, required this.arena});

  @override
  State<QuadrasArenaEmpresaScreen> createState() => _QuadrasArenaEmpresaScreenState();
}

class _QuadrasArenaEmpresaScreenState extends State<QuadrasArenaEmpresaScreen> {
  List<dynamic> _quadras = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() { super.initState(); _carregar(); }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final quadras = await QuadraService.getByArena(widget.arena.id);
      setState(() { _quadras = quadras; _loading = false; });
    } catch (_) {
      setState(() { _erro = 'Não foi possível carregar as quadras.'; _loading = false; });
    }
  }

  Future<void> _excluirQuadra(dynamic quadra) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir quadra'),
        content: Text('Tem certeza que deseja excluir "${quadra.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await QuadraService.excluir(quadra.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quadra excluída'), backgroundColor: kLaranja));
      _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBg(context),
      appBar: AppBar(
        backgroundColor: appBg(context),
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextPri),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPri, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.arena.nome,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kTextPri)),
        actions: [
          const ProfileAction(),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () async {
              final criou = await Navigator.push<bool>(context,
                  MaterialPageRoute(builder: (_) => CadastroQuadraScreen(arenaId: widget.arena.id)));
              if (criou == true) _carregar();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: kLaranja, borderRadius: BorderRadius.circular(12)),
              child: const Text('+ Quadra', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kLaranja))
          : _erro != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_erro!, style: const TextStyle(color: kTextSec)),
                  const SizedBox(height: 12),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: kLaranja, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _carregar, child: const Text('Tentar novamente', style: TextStyle(color: Colors.white))),
                ]))
              : _quadras.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.sports_tennis, color: kTextSec, size: 48),
                      const SizedBox(height: 12),
                      const Text('Nenhuma quadra cadastrada.', style: TextStyle(color: kTextSec)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      color: kLaranja,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                        itemCount: _quadras.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _CardQuadra(
                          quadra: _quadras[i],
                          onEditar: () async {
                            final editou = await Navigator.push<bool>(context,
                                MaterialPageRoute(builder: (_) => CadastroQuadraScreen(arenaId: widget.arena.id, quadraParaEditar: _quadras[i])));
                            if (editou == true) _carregar();
                          },
                          onExcluir: () => _excluirQuadra(_quadras[i]),
                        ),
                      ),
                    ),
    );
  }
}

class _CardQuadra extends StatelessWidget {
  final dynamic quadra;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _CardQuadra({required this.quadra, required this.onEditar, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: kLaranja.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.sports_tennis, color: kLaranja, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quadra.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPri)),
                const SizedBox(height: 3),
                Text(quadra.coberturaLabel, style: const TextStyle(color: kTextSec, fontSize: 12)),
              ],
            ),
          ),
          Text('R\$ ${quadra.valorHora.toStringAsFixed(2)}/h',
              style: TextStyle(color: kLaranja, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            color: appCard(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            icon: const Icon(Icons.more_vert, color: kTextSec, size: 20),
            onSelected: (v) {
              if (v == 'editar') onEditar();
              if (v == 'excluir') onExcluir();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'editar', child: Row(children: [const Icon(Icons.edit_outlined, color: kLaranja, size: 18), const SizedBox(width: 10), const Text('Editar')])),
              PopupMenuItem(value: 'excluir', child: Row(children: [const Icon(Icons.delete_outline, color: Colors.red, size: 18), const SizedBox(width: 10), const Text('Excluir', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
    );
  }
}