import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/model/CampeonatoDTO.dart';
import 'package:flutter_application_1/screen/jogador/campeonato/Inscricao_Campeonato_Screen.dart';
import 'package:flutter_application_1/screen/jogador/campeonato/chaveamento_screen.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/service/campeonato_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:http/http.dart' as http;

class ListaCampeonatosScreen extends StatefulWidget {
  const ListaCampeonatosScreen({super.key});

  @override
  State<ListaCampeonatosScreen> createState() => _ListaCampeonatosScreenState();
}

class _ListaCampeonatosScreenState extends State<ListaCampeonatosScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;

  bool loadingAbertos = true;
  String? erroAbertos;
  List<CampeonatoDTO> campeonatosAbertos = [];

  bool loadingInscritos = true;
  String? erroInscritos;
  List<CampeonatoDTO> campeonatosInscritos = [];

  bool loadingHistorico = true;
  String? erroHistorico;
  List<CampeonatoDTO> campeonatosHistorico = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _buscarAbertos();
    _buscarInscritosEHistorico();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarAbertos() async {
    setState(() { loadingAbertos = true; erroAbertos = null; });
    try {
      final dados = await CampeonatoService.listarTodos();
      final lista = dados
          .map((e) => CampeonatoDTO.fromJson(e as Map<String, dynamic>))
          .where((c) => c.status == 'INSCRICOES_ABERTAS')
          .toList();
      if (!mounted) return;
      setState(() { campeonatosAbertos = lista; loadingAbertos = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { erroAbertos = 'Não foi possível carregar.'; loadingAbertos = false; });
    }
  }

  Future<void> _buscarInscritosEHistorico() async {
    setState(() {
      loadingInscritos = true; erroInscritos = null;
      loadingHistorico = true; erroHistorico = null;
    });
    try {
      final resultados = await Future.wait([
        CampeonatoService.listarTodos(),
        _lerInscricoesLocais(),
      ]);

      final todos = (resultados[0] as List<dynamic>)
          .map((e) => CampeonatoDTO.fromJson(e as Map<String, dynamic>))
          .toList();

      final idsInscritos = resultados[1] as Set<int>;

      final inscritos = todos
          .where((c) => idsInscritos.contains(c.id) && c.status != 'FINALIZADO')
          .toList();
      final historico = todos
          .where((c) => idsInscritos.contains(c.id) && c.status == 'FINALIZADO')
          .toList();

      if (!mounted) return;
      setState(() {
        campeonatosInscritos = inscritos;
        campeonatosHistorico = historico;
        loadingInscritos = false;
        loadingHistorico = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erroInscritos = 'Não foi possível carregar.';
        erroHistorico = 'Não foi possível carregar.';
        loadingInscritos = false;
        loadingHistorico = false;
      });
    }
  }

  Future<Set<int>> _lerInscricoesLocais() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = prefs.getStringList('inscricoes_campeonato') ?? [];
      return lista.map((s) => int.tryParse(s) ?? -1).toSet();
    } catch (_) {
      return {};
    }
  }


  void _abrir(CampeonatoDTO c) {
    if (c.status == 'INSCRICOES_ABERTAS') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => InscricaoCampeonatoScreen(campeonato: c)));
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) =>
              ChaveamentoScreen(campeonatoId: c.id, nomeCampeonato: c.nome)));
    }
  }

  String _statusLabel(String s) => switch (s) {
        'INSCRICOES_ABERTAS' => 'Inscrições abertas',
        'EM_ANDAMENTO'       => 'Em andamento',
        'FINALIZADO'         => 'Finalizado',
        _                    => s,
      };

  Color _statusCor(String s) => switch (s) {
        'INSCRICOES_ABERTAS' => kLaranja,
        'EM_ANDAMENTO'       => Colors.amber[700]!,
        'FINALIZADO'         => kTextSec,
        _                    => kTextSec,
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Torneios',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: kTextPri,
                        letterSpacing: -0.5)),
                ProfileAction(),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 42,
            decoration: BoxDecoration(
              color: kBorder.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4)
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(3),
              dividerColor: Colors.transparent,
              labelColor: kLaranja,
              unselectedLabelColor: kTextSec,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              tabs: const [
                Tab(text: 'Abertos'),
                Tab(text: 'Inscritos'),
                Tab(text: 'Histórico'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _abaComEstado(
                  loading: loadingAbertos,
                  erro: erroAbertos,
                  lista: campeonatosAbertos,
                  vazioMsg: 'Nenhum torneio com inscrições abertas.',
                  onRetry: _buscarAbertos,
                ),
                _abaComEstado(
                  loading: loadingInscritos,
                  erro: erroInscritos,
                  lista: campeonatosInscritos,
                  vazioMsg: 'Você ainda não está inscrito em nenhum torneio.',
                  onRetry: _buscarInscritosEHistorico,
                ),
                _abaComEstado(
                  loading: loadingHistorico,
                  erro: erroHistorico,
                  lista: campeonatosHistorico,
                  vazioMsg: 'Nenhum torneio encerrado ainda.',
                  onRetry: _buscarInscritosEHistorico,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _abaComEstado({
    required bool loading,
    required String? erro,
    required List<CampeonatoDTO> lista,
    required String vazioMsg,
    required VoidCallback onRetry,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: kLaranja));
    }
    if (erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(erro, style: const TextStyle(color: kTextSec)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kLaranja,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: onRetry,
              child: const Text('Tentar novamente',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    return _lista(lista, vazio: vazioMsg, onRetry: onRetry);
  }

  Widget _lista(List<CampeonatoDTO> lista,
      {String? vazio, required VoidCallback onRetry}) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined, color: kTextSec, size: 48),
            const SizedBox(height: 12),
            Text(vazio ?? 'Nenhum torneio disponível.',
                style: const TextStyle(color: kTextSec),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: kLaranja,
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: lista.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _card(lista[i]),
      ),
    );
  }

  Widget _card(CampeonatoDTO c) {
    final cor = _statusCor(c.status);
    final label = _statusLabel(c.status);
    final aberto = c.status == 'INSCRICOES_ABERTAS';

    return GestureDetector(
      onTap: () => _abrir(c),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: aberto ? kLaranja.withValues(alpha: 0.3) : kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: cor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                if (c.descricao.isNotEmpty)
                  Text(c.descricao,
                      style: TextStyle(
                          color: aberto ? kLaranja : kTextSec,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Text(c.nome,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kTextPri)),
            const SizedBox(height: 8),
            Row(children: [
              _chip(Icons.category_outlined, c.categoria),
              const SizedBox(width: 8),
              _chip(Icons.calendar_today_outlined, c.dataInicio),
              const SizedBox(width: 8),
              _chip(Icons.groups_outlined, '${c.totalInscritos}/16'),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kLaranja,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => _abrir(c),
                child: Text(
                  aberto ? 'Inscrever time' : 'Ver chaveamento',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String txt) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: kOffWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: kTextSec),
            const SizedBox(width: 4),
            Text(txt, style: const TextStyle(color: kTextSec, fontSize: 11)),
          ],
        ),
      );
}