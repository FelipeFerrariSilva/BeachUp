import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/provider/auth_provider.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/service/campeonato_service.dart';
import 'package:flutter_application_1/screen/empresa/campeonato/criar_campeonato_screen.dart';
import 'package:flutter_application_1/service/arena_service.dart';
import 'package:flutter_application_1/model/arena.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';

class MeusCampeonatosScreen extends StatefulWidget {
  const MeusCampeonatosScreen({super.key});

  @override
  State<MeusCampeonatosScreen> createState() => _MeusCampeonatosScreenState();
}

class _MeusCampeonatosScreenState extends State<MeusCampeonatosScreen> {
  List<dynamic> _campeonatos = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() { super.initState(); _carregar(); }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final lista = await CampeonatoService.listarMeus();
      setState(() { _campeonatos = lista; _loading = false; });
    } catch (e) {
      setState(() { _erro = 'Não foi possível carregar seus campeonatos.'; _loading = false; });
    }
  }

  Future<void> _irParaCriarCampeonato(String token) async {
    List<Arena> arenas = [];
    try { arenas = await ArenaService.getMinhas(); } catch (_) {}
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CriarCampeonatoScreen(
        accessToken: token,
        arenas: arenas.map((a) => <String, dynamic>{'id': a.id, 'nome': a.nome}).toList(),
      ),
    )).then((_) => _carregar());
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: appBg(context),
      appBar: CustomAppBarPerfil(),
      body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Text('Meus Campeonatos',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: kTextPri,
                    letterSpacing: -0.5)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: GestureDetector(
              onTap: () => _irParaCriarCampeonato(auth.accessToken),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kLaranja,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Criar Campeonato',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          Text('Defina categoria, datas e premiação',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),

          Expanded(child: _buildConteudo()),
        ],
      ),
    ),
    );
  }

  Widget _buildConteudo() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kLaranja));
    if (_erro != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_rounded, color: kTextSec, size: 48),
        const SizedBox(height: 12),
        Text(_erro!, style: const TextStyle(color: kTextSec)),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kLaranja, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _carregar,
          child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
        ),
      ]));
    }
    if (_campeonatos.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.emoji_events_outlined, color: kTextSec, size: 48),
        const SizedBox(height: 12),
        const Text('Nenhum campeonato criado ainda.', style: TextStyle(color: kTextSec)),
        const SizedBox(height: 4),
        const Text('Crie seu primeiro acima.', style: TextStyle(color: kTextSec, fontSize: 12)),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      color: kLaranja,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: _campeonatos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _CardCampeonato(data: _campeonatos[i], onAtualizar: _carregar),
      ),
    );
  }
}

class _CardCampeonato extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAtualizar;

  const _CardCampeonato({required this.data, required this.onAtualizar});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? '';
    final nome = data['nome'] as String? ?? '-';
    final categoria = data['categoria'] as String? ?? '';
    final totalInscritos = data['totalInscritos'] as int? ?? 0;
    final token = data['tokenInscricao'] as String? ?? '';

    final (statusLabel, statusCor) = switch (status) {
      'INSCRICOES_ABERTAS' => ('Inscrições abertas', kLaranja),
      'INSCRICOES_FECHADAS' => ('Inscrições fechadas', Colors.amber[700]!),
      'EM_ANDAMENTO' => ('Em andamento', Colors.blue),
      'FINALIZADO' => ('Finalizado', kTextSec),
      _ => (status, kTextSec),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status == 'INSCRICOES_ABERTAS' ? kLaranja.withValues(alpha: 0.3) : kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + data
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusCor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusCor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              if (data['dataInicio'] != null)
                Text(data['dataInicio'].toString(),
                    style: const TextStyle(color: kTextSec, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text(nome,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextPri)),
          if (categoria.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(categoria, style: const TextStyle(color: kTextSec, fontSize: 13)),
          ],
          const SizedBox(height: 14),

          // Métricas
          Row(children: [
            _metrica('$totalInscritos', 'Inscritos'),
            const SizedBox(width: 10),
            if (data['arrecadado'] != null)
              _metrica('R\$${data['arrecadado']}', 'Arrecadado'),
            const SizedBox(width: 10),
            if (data['premio'] != null)
              _metrica('${data['premio']}', 'Prêmio'),
          ]),

          if (token.isNotEmpty) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token copiado!'), backgroundColor: kLaranja),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kOffWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key_rounded, size: 14, color: kTextSec),
                    const SizedBox(width: 8),
                    Expanded(child: Text(token,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: kTextPri))),
                    const Icon(Icons.copy_rounded, size: 16, color: kLaranja),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          _BotoesAcao(campeonatoId: data['id'] as int, status: status, onAtualizar: onAtualizar),
        ],
      ),
    );
  }

  Widget _metrica(String valor, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: kOffWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kTextPri)),
            Text(label, style: const TextStyle(fontSize: 11, color: kTextSec)),
          ],
        ),
      ),
    );
  }
}

class _BotoesAcao extends StatefulWidget {
  final int campeonatoId;
  final String status;
  final VoidCallback onAtualizar;
  const _BotoesAcao({required this.campeonatoId, required this.status, required this.onAtualizar});

  @override
  State<_BotoesAcao> createState() => _BotoesAcaoState();
}

class _BotoesAcaoState extends State<_BotoesAcao> {
  bool _carregando = false;

  Future<void> _iniciar() async {
    setState(() => _carregando = true);
    final token = await AuthService.getToken() ?? '';
    final res = await CampeonatoService.iniciar(campeonatoId: widget.campeonatoId, token: token);
    if (!mounted) return;
    setState(() => _carregando = false);
    if (res['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campeonato iniciado!'), backgroundColor: kLaranja));
      widget.onAtualizar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['erro'] ?? 'Erro ao iniciar'), backgroundColor: Colors.red));
    }
  }

  void _verPartidas() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _PartidasScreen(campeonatoId: widget.campeonatoId)))
        .then((_) => widget.onAtualizar());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (widget.status == 'EM_ANDAMENTO' || widget.status == 'FINALIZADO')
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _verPartidas,
              icon: const Icon(Icons.sports_score_rounded, size: 18, color: kLaranja),
              label: const Text('Ver partidas', style: TextStyle(color: kLaranja, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: kLaranja),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        if (widget.status == 'EM_ANDAMENTO') const SizedBox(width: 8),
        if (widget.status == 'INSCRICOES_ABERTAS' || widget.status == 'INSCRICOES_FECHADAS')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _carregando ? null : _iniciar,
              icon: _carregando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              label: Text(_carregando ? 'Iniciando...' : 'Iniciar campeonato',
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: kLaranja,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        if (widget.status == 'FINALIZADO') ...[
          const SizedBox(width: 8),
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
          const SizedBox(width: 4),
          const Text('Encerrado', style: TextStyle(color: kTextSec, fontSize: 14)),
        ],
      ],
    );
  }
}

class _PartidasScreen extends StatefulWidget {
  final int campeonatoId;
  const _PartidasScreen({required this.campeonatoId});

  @override
  State<_PartidasScreen> createState() => _PartidasScreenState();
}

class _PartidasScreenState extends State<_PartidasScreen> {
  List<dynamic> _partidas = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() { super.initState(); _carregar(); }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final partidas = await CampeonatoService.listarPartidas(widget.campeonatoId);
      setState(() { _partidas = partidas; _loading = false; });
    } catch (e) {
      setState(() { _erro = 'Erro ao carregar partidas.'; _loading = false; });
    }
  }

  Map<String, List<dynamic>> get _porFase {
    final map = <String, List<dynamic>>{};
    for (final p in _partidas) {
      final fase = p['fase'] as String? ?? 'Fase';
      map.putIfAbsent(fase, () => []).add(p);
    }
    return map;
  }

  int get _finalizadas => _partidas.where((p) => p['status'] == 'FINALIZADA').length;
  int get _aguardando => _partidas.where((p) => p['status'] == 'AGUARDANDO').length;

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
        title: const Text('Partidas',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kTextPri)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: kTextPri), onPressed: _carregar),
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
              : _partidas.isEmpty
                  ? const Center(child: Text('Nenhuma partida encontrada.', style: TextStyle(color: kTextSec)))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: Row(children: [
                            _metricaTopo('${_partidas.length}', 'Total'),
                            const SizedBox(width: 10),
                            _metricaTopo('$_finalizadas', 'Finalizadas'),
                            const SizedBox(width: 10),
                            _metricaTopo('$_aguardando', 'Aguardando'),
                          ]),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _carregar,
                            color: kLaranja,
                            child: ListView(
                              padding: const EdgeInsets.all(20),
                              children: _porFase.entries.map((entry) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10, top: 4),
                                    child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kTextPri)),
                                  ),
                                  ...entry.value.map((p) => _CardPartida(partida: p, onResultadoRegistrado: _carregar)),
                                  const SizedBox(height: 8),
                                ],
                              )).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _metricaTopo(String valor, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: appCard(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Column(children: [
          Text(valor, style: const TextStyle(color: kTextPri, fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: const TextStyle(color: kTextSec, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _CardPartida extends StatelessWidget {
  final Map<String, dynamic> partida;
  final VoidCallback onResultadoRegistrado;
  const _CardPartida({required this.partida, required this.onResultadoRegistrado});

  bool get _finalizada => partida['status'] == 'FINALIZADA';

  void _registrarResultado(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: appCard(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: _ModalResultado(partida: partida, onSalvo: () { Navigator.pop(context); onResultadoRegistrado(); }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeCasa = partida['nomeTimeCasa'] as String? ?? '-';
    final timeVisitante = partida['nomeTimeVisitante'] as String? ?? '-';
    final placarCasa = partida['placarTimeCasa'];
    final placarVisitante = partida['placarTimeVisitante'];
    final idVencedor = partida['idTimeVencedor'];
    final idCasa = partida['idTimeCasa'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: Text(timeCasa, textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                    color: (idVencedor != null && idVencedor == idCasa) ? kLaranja : kTextPri))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _finalizada ? kOffWhite : kLaranja.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _finalizada && placarCasa != null ? '$placarCasa × $placarVisitante' : 'vs',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17,
                    color: _finalizada ? kTextPri : kLaranja),
              ),
            ),
            Expanded(child: Text(timeVisitante, textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                    color: (idVencedor != null && idVencedor != idCasa) ? kLaranja : kTextPri))),
          ]),
          if (!_finalizada) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _registrarResultado(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kLaranja),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Registrar resultado', style: TextStyle(color: kLaranja, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModalResultado extends StatefulWidget {
  final Map<String, dynamic> partida;
  final VoidCallback onSalvo;
  const _ModalResultado({required this.partida, required this.onSalvo});

  @override
  State<_ModalResultado> createState() => _ModalResultadoState();
}

class _ModalResultadoState extends State<_ModalResultado> {
  final _casaCtrl = TextEditingController();
  final _visitanteCtrl = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() { _casaCtrl.dispose(); _visitanteCtrl.dispose(); super.dispose(); }

  Future<void> _salvar() async {
    final casa = int.tryParse(_casaCtrl.text.trim());
    final visitante = int.tryParse(_visitanteCtrl.text.trim());
    if (casa == null || visitante == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe os placares corretamente'), backgroundColor: Colors.red));
      return;
    }
    if (casa == visitante) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não pode haver empate em eliminatória'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _salvando = true);
    final token = await AuthService.getToken() ?? '';
    final res = await CampeonatoService.registrarResultado(
        partidaId: widget.partida['id'] as int, placarTimeCasa: casa, placarTimeVisitante: visitante, token: token);
    if (!mounted) return;
    setState(() => _salvando = false);
    if (res['sucesso'] == true) {
      widget.onSalvo();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['erro'] ?? 'Erro ao salvar'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeCasa = widget.partida['nomeTimeCasa'] as String? ?? '-';
    final timeVisitante = widget.partida['nomeTimeVisitante'] as String? ?? '-';
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Registrar Resultado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextPri)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Column(children: [
              Text(timeCasa, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextPri)),
              const SizedBox(height: 8),
              TextField(controller: _casaCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kTextPri),
                decoration: InputDecoration(filled: true, fillColor: kOffWhite, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
            ])),
            const Padding(padding: EdgeInsets.only(top: 24), child: Padding(padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('×', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kTextSec)))),
            Expanded(child: Column(children: [
              Text(timeVisitante, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextPri)),
              const SizedBox(height: 8),
              TextField(controller: _visitanteCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kTextPri),
                decoration: InputDecoration(filled: true, fillColor: kOffWhite, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
            ])),
          ]),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              style: ElevatedButton.styleFrom(backgroundColor: kLaranja, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _salvando
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('Confirmar resultado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
            ),
          ),
        ],
      ),
    );
  }
}