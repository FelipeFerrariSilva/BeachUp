import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/auth_provider.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/service/campeonato_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';

class ChaveamentoScreen extends StatefulWidget {
  final int campeonatoId;
  final String nomeCampeonato;

  const ChaveamentoScreen({
    super.key,
    required this.campeonatoId,
    required this.nomeCampeonato,
  });

  @override
  State<ChaveamentoScreen> createState() => _ChaveamentoScreenState();
}

class _ChaveamentoScreenState extends State<ChaveamentoScreen> {
  bool _carregando = true;
  bool _iniciandoCampeonato = false;

  List<Map<String, dynamic>> _partidas = [];
  List<String> _fases = [];
  int _faseSelecionada = 0;

  @override
  void initState() {
    super.initState();
    _carregarPartidas();
  }

  Future<void> _carregarPartidas() async {
    setState(() => _carregando = true);

    try {
      final partidasCruas = await CampeonatoService.listarPartidas(
        widget.campeonatoId,
      );

      if (!mounted) return;

      final partidas = partidasCruas
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();

      final fasesOrdenadas = <String>[];
      for (final p in partidas) {
        final fase = p['fase']?.toString() ?? '';
        if (fase.isNotEmpty && !fasesOrdenadas.contains(fase)) {
          fasesOrdenadas.add(fase);
        }
      }

      setState(() {
        _partidas = partidas;
        _fases = fasesOrdenadas;
        _faseSelecionada = _fases.isEmpty ? 0 : _fases.length - 1;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _partidas = [];
        _fases = [];
        _carregando = false;
      });
    }
  }

  Future<void> _iniciarCampeonato() async {
    setState(() => _iniciandoCampeonato = true);

    final token = await AuthService.getToken();
    final resultado = await CampeonatoService.iniciar(
      campeonatoId: widget.campeonatoId,
      token: token ?? '',
    );

    if (!mounted) return;
    setState(() => _iniciandoCampeonato = false);

    if (resultado['sucesso'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['erro'] ?? 'Erro ao iniciar campeonato'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _carregarPartidas();
  }

  Future<void> _abrirRegistrarResultado(Map<String, dynamic> partida) async {
    final placarCasaController = TextEditingController();
    final placarVisitanteController = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Registrar resultado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        partida['nomeTimeCasa']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: placarCasaController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: kOffWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'x',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        partida['nomeTimeVisitante']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: placarVisitanteController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: kOffWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final placarCasa = int.tryParse(placarCasaController.text);
    final placarVisitante = int.tryParse(placarVisitanteController.text);

    if (placarCasa == null || placarVisitante == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe os dois placares')));
      return;
    }

    final token = await AuthService.getToken();
    final resultado = await CampeonatoService.registrarResultado(
      partidaId: partida['id'] as int,
      placarTimeCasa: placarCasa,
      placarTimeVisitante: placarVisitante,
      token: token ?? '',
    );

    if (!mounted) return;

    if (resultado['sucesso'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['erro'] ?? 'Erro ao registrar resultado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resultado registrado com sucesso!')),
    );
    await _carregarPartidas();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: appBg(context),
      appBar: AppBar(
        backgroundColor: kCard,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextPri),
        title: Text(
          widget.nomeCampeonato,
          style: const TextStyle(color: kTextPri, fontSize: 16),
        ),
        actions: [const ProfileAction(), const SizedBox(width: 8)],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _partidas.isEmpty
          ? _estadoSemPartidas(auth)
          : _conteudoChaveamento(auth),
    );
  }

  Widget _estadoSemPartidas(AuthProvider auth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'O chaveamento ainda não foi gerado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              auth.isEmpresa
                  ? 'Quando as inscrições estiverem completas, inicie o campeonato para gerar os confrontos.'
                  : 'Aguarde a empresa organizadora iniciar o campeonato.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (auth.isEmpresa) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _iniciandoCampeonato ? null : _iniciarCampeonato,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _iniciandoCampeonato
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Gerar chaveamento',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _conteudoChaveamento(AuthProvider auth) {
    final partidasDaFase = _partidas
        .where((p) => p['fase']?.toString() == _fases[_faseSelecionada])
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: List.generate(_fases.length, (i) {
              final ativo = i == _faseSelecionada;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _faseSelecionada = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: ativo ? Colors.orange : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ativo ? Colors.orange : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      _fases[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                        color: ativo ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: partidasDaFase.length,
            itemBuilder: (context, index) {
              return _cardPartida(partidasDaFase[index], auth);
            },
          ),
        ),
      ],
    );
  }

  Widget _cardPartida(Map<String, dynamic> partida, AuthProvider auth) {
    final idTimeCasa = partida['idTimeCasa'] as int?;
    final idTimeVisitante = partida['idTimeVisitante'] as int?;
    final idTimeVencedor = partida['idTimeVencedor'] as int?;
    final placarTimeCasa = partida['placarTimeCasa'] as int?;
    final placarTimeVisitante = partida['placarTimeVisitante'] as int?;
    final status = partida['status']?.toString() ?? 'AGUARDANDO';
    final finalizada = status == 'FINALIZADA';

    final temTimes = idTimeCasa != null && idTimeVisitante != null;
    final prontaParaJogar = temTimes && !finalizada;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appCard(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Opacity(
        opacity: temTimes ? 1.0 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaTime(
              nome: partida['nomeTimeCasa']?.toString() ?? 'A definir',
              placar: placarTimeCasa,
              venceu: idTimeVencedor != null && idTimeVencedor == idTimeCasa,
            ),
            const SizedBox(height: 6),
            _linhaTime(
              nome: partida['nomeTimeVisitante']?.toString() ?? 'A definir',
              placar: placarTimeVisitante,
              venceu:
                  idTimeVencedor != null && idTimeVencedor == idTimeVisitante,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  finalizada
                      ? 'Finalizada'
                      : (temTimes
                            ? 'Aguardando jogo'
                            : 'Aguardando fase anterior'),
                  style: TextStyle(
                    fontSize: 11,
                    color: finalizada
                        ? Colors.grey
                        : (temTimes ? Colors.orange : Colors.grey),
                  ),
                ),
                if (auth.isEmpresa && prontaParaJogar)
                  TextButton(
                    onPressed: () => _abrirRegistrarResultado(partida),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text(
                      'Registrar resultado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
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

  Widget _linhaTime({
    required String nome,
    required int? placar,
    required bool venceu,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          nome,
          style: TextStyle(
            fontSize: 14,
            fontWeight: venceu ? FontWeight.bold : FontWeight.normal,
            color: venceu ? Colors.black : Colors.black87,
          ),
        ),
        Text(
          placar?.toString() ?? '—',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: venceu ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }
}