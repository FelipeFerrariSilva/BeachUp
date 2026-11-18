import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/time.dart';
import 'package:flutter_application_1/screen/jogador/time/criar_time_jogador_screen.dart';
import 'package:flutter_application_1/service/time_service.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:flutter_application_1/screen/jogador/time/detalhe_time_screen.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class MeusTimesScreen extends StatefulWidget {
  const MeusTimesScreen({super.key});

  @override
  State<MeusTimesScreen> createState() => _MeusTimesScreenState();
}

class _MeusTimesScreenState extends State<MeusTimesScreen> {
  static const _laranja = kLaranja;

  final _timeService = TimeService();
  bool _loading = true;
  String? _erro;
  List<TimeModel> _times = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final lista = await _timeService.getTimes();
      if (mounted) setState(() { _times = lista; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = 'Erro ao carregar os times.'; _loading = false; });
    }
  }

  Future<void> _irParaCriarTime() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CriarTimeJogadorScreen()),
    );
    _carregar();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: CustomAppBarPerfil(),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _botoesRodape(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _laranja));
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 12),
            Text(_erro!, style: const TextStyle(color: kTextSec)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _laranja),
              onPressed: _carregar,
              child: const Text('Tentar novamente',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_times.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Você ainda não possui times.',
                style: TextStyle(color: kTextSec)),
            const SizedBox(height: 6),
            const Text('Crie um time ou entre com um código!',
                style: TextStyle(color: kTextSec, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _laranja,
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: _times.length,
        itemBuilder: (_, i) => _card(_times[i]),
      ),
    );
  }

  Widget _card(TimeModel time) {
    final completo = time.estaCompleto;
    final cor = completo ? Colors.green : _laranja;
    final statusLabel = completo ? 'Completo' : 'Aberto';
    final membrosAceitos = time.membros
        .where((m) => m.status.toUpperCase() == 'ACEITO')
        .toList();

    return GestureDetector(
      onTap: () async {
        final excluido = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => DetalheTimeScreen(time: time)),
        );
        if (excluido == true) _carregar();
      },
      child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _laranja.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.groups_rounded, color: _laranja, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(time.nome,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: cor, fontWeight: FontWeight.w600, fontSize: 11)),
                    ),
                  ]),
                  if (time.descricao != null && time.descricao!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(time.descricao!,
                        style: const TextStyle(color: kTextSec, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 14, color: kTextSec),
                    const SizedBox(width: 4),
                    Text('${membrosAceitos.length}/2 membros',
                        style: const TextStyle(fontSize: 12, color: kTextSec)),
                    if (membrosAceitos.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          membrosAceitos.map((m) => m.nomeUsuario).join(', '),
                          style: const TextStyle(fontSize: 12, color: kTextSec),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _botoesRodape() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _irParaCriarTime,
          icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
          label: const Text('Novo time',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _laranja,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}