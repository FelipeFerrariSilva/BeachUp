import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/arena.dart';
import 'package:flutter_application_1/model/quadra.dart';
import 'package:flutter_application_1/service/quadra_service.dart';
import 'package:flutter_application_1/service/horario_service.dart';
import 'package:flutter_application_1/screen/jogador/reserva/checkout_list_screen.dart';
import 'package:flutter_application_1/widget/navbar.dart';

const _laranja = kLaranja;

class QuadrasArenaJogadorScreen extends StatefulWidget {
  final Arena arena;
  const QuadrasArenaJogadorScreen({super.key, required this.arena});

  @override
  State<QuadrasArenaJogadorScreen> createState() =>
      _QuadrasArenaJogadorScreenState();
}

class _QuadrasArenaJogadorScreenState
    extends State<QuadrasArenaJogadorScreen> {
  List<Quadra> _quadras = [];
  List<HorarioFuncionamento> _horarios = [];
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
      final quadras = await QuadraService.getByArena(widget.arena.id);
      List<HorarioFuncionamento> horarios = [];
      try {
        horarios = await HorarioService.listar(widget.arena.id);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _quadras  = quadras;
          _horarios = horarios;
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _erro = 'Não foi possível carregar as informações.'; _loading = false; });
      }
    }
  }

  List<HorarioFuncionamento> get _horariosOrdenados {
    const ordem = ['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'];
    final lista = List<HorarioFuncionamento>.from(_horarios);
    lista.sort((a, b) =>
        ordem.indexOf(a.diaSemana).compareTo(ordem.indexOf(b.diaSemana)));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBg(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _laranja))
          : _erro != null
              ? _buildErro()
              : CustomScrollView(
                  slivers: [
                    _buildSliverHeader(),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoArena(),
                          if (_horarios.isNotEmpty) _buildHorarios(),
                          _buildTituloQuadras(),
                          if (_quadras.isEmpty)
                            _buildSemQuadras()
                          else
                            ..._quadras.map((q) => Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: _CardQuadra(quadra: q, horarios: _horarios),
                                )),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _laranja,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.arena.nome,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.arena.fotoUrl != null && widget.arena.fotoUrl!.isNotEmpty
                ? Image.network(
                    widget.arena.fotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fotoPlaceholder(),
                  )
                : _fotoPlaceholder(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16, bottom: 16,
              right: 16,
              child: Row(children: [
                const Icon(Icons.location_on_rounded,
                    color: _laranja, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.arena.localizacao,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotoPlaceholder() => Container(
        color: const Color(0xFF2A2A2A),
        child: const Icon(Icons.stadium_outlined,
            color: Colors.white24, size: 60),
      );

  Widget _buildInfoArena() {
    final end = widget.arena.endereco;
    if (end == null) return const SizedBox.shrink();

    final partes = <String>[
      if (end.logradouro != null && end.logradouro!.isNotEmpty) end.logradouro!,
      if (end.numero != null && end.numero!.isNotEmpty) end.numero!,
    ];
    final rua = partes.join(', ');
    final bairro = end.bairro ?? '';
    final cidade = end.cidade ?? '';
    final estado = end.estado ?? '';
    final cep = end.cep ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _laranja.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: _laranja, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Endereço',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kTextPri)),
          ]),
          const SizedBox(height: 12),
          if (rua.isNotEmpty) _infoLinha(rua),
          if (bairro.isNotEmpty) _infoLinha(bairro),
          if (cidade.isNotEmpty || estado.isNotEmpty)
            _infoLinha([cidade, estado].where((s) => s.isNotEmpty).join(', ')),
          if (cep.isNotEmpty) _infoLinha('CEP: $cep'),
          if (widget.arena.descricao != null &&
              widget.arena.descricao!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              widget.arena.descricao!,
              style: const TextStyle(fontSize: 13, color: kTextSec),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoLinha(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(texto,
            style: const TextStyle(fontSize: 13, color: kTextSec)),
      );

  Widget _buildHorarios() {
    final ordenados = _horariosOrdenados;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: appCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _laranja.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.access_time_rounded,
                    color: _laranja, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Horários de funcionamento',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kTextPri)),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ...ordenados.asMap().entries.map((entry) {
            final h = entry.value;
            final isLast = entry.key == ordenados.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  child: Row(children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        h.diaSemanaLabel.isNotEmpty
                            ? h.diaSemanaLabel
                            : _labelDia(h.diaSemana),
                        style: const TextStyle(
                            fontSize: 13,
                            color: kTextPri,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _laranja.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${h.horaAbertura} – ${h.horaFechamento}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: _laranja,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
                if (!isLast)
                  const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF0F0F0)),
              ],
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  String _labelDia(String dia) {
    const map = {
      'MONDAY': 'Segunda-feira',
      'TUESDAY': 'Terça-feira',
      'WEDNESDAY': 'Quarta-feira',
      'THURSDAY': 'Quinta-feira',
      'FRIDAY': 'Sexta-feira',
      'SATURDAY': 'Sábado',
      'SUNDAY': 'Domingo',
    };
    return map[dia] ?? dia;
  }

  Widget _buildTituloQuadras() => const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text('Quadras disponíveis',
            style: TextStyle(
                color: _laranja, fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _buildSemQuadras() => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('Esta arena ainda não tem quadras.',
              style: TextStyle(color: kTextPri.withValues(alpha: 0.5)),
              textAlign: TextAlign.center),
        ),
      );

  Widget _buildErro() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

class _CardQuadra extends StatelessWidget {
  final Quadra quadra;
  final List<HorarioFuncionamento> horarios;
  const _CardQuadra({required this.quadra, this.horarios = const []});

  @override
  Widget build(BuildContext context) {
    final temFoto = quadra.fotos.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: appCard(context),
        border: Border.all(color: _laranja),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (temFoto)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(19)),
              child: Image.network(
                quadra.fotos.first,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 140,
                        color: const Color(0xFFF0F0EE),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: _laranja, strokeWidth: 2),
                        ),
                      ),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (!temFoto)
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _laranja.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sports_tennis,
                        color: _laranja, size: 26),
                  ),
                if (!temFoto) const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quadra.nome,
                          style: const TextStyle(
                              color: kTextPri,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.wb_sunny_outlined,
                            size: 13, color: kTextSec),
                        const SizedBox(width: 3),
                        Text(quadra.coberturaLabel,
                            style: const TextStyle(
                                color: kTextSec, fontSize: 12)),
                      ]),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${quadra.valorHora.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: kTextPri,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text('/hora',
                        style: TextStyle(color: kTextSec, fontSize: 11)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutListScreen(
                              quadra: quadra, horarios: horarios),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _laranja,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Reservar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}