import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/quadra.dart';
import 'package:flutter_application_1/model/reserva.dart';
import 'package:flutter_application_1/service/reserva_service.dart';
import 'package:flutter_application_1/service/pagamento_service.dart';
import 'package:flutter_application_1/service/horario_service.dart';
import 'package:flutter_application_1/screen/jogador/reserva/minhas_reservas_screen.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

class CheckoutListScreen extends StatefulWidget {
  final Quadra quadra;
  final List<HorarioFuncionamento> horarios;

  const CheckoutListScreen({
    super.key,
    required this.quadra,
    this.horarios = const [],
  });

  @override
  State<CheckoutListScreen> createState() => _CheckoutListScreenState();
}

class _CheckoutListScreenState extends State<CheckoutListScreen> {
  DateTime _diaSelecionado = DateTime.now();
  String? _horaInicioSel;
  String? _horaFimSel;
  bool _loadingReserva = false;

  HorarioFuncionamento? get _horarioDia {
    if (widget.horarios.isEmpty) return null;
    const map = {
      DateTime.monday:    'MONDAY',
      DateTime.tuesday:   'TUESDAY',
      DateTime.wednesday: 'WEDNESDAY',
      DateTime.thursday:  'THURSDAY',
      DateTime.friday:    'FRIDAY',
      DateTime.saturday:  'SATURDAY',
      DateTime.sunday:    'SUNDAY',
    };
    final diaSemana = map[_diaSelecionado.weekday];
    try {
      return widget.horarios.firstWhere((h) => h.diaSemana == diaSemana);
    } catch (_) {
      return null;
    }
  }

  List<String> get _horariosDisponiveis {
    final h = _horarioDia;
    if (h == null) {
      return _gerarSlots('08:00', '22:00');
    }
    if (h.horaAbertura.isEmpty || h.horaFechamento.isEmpty) return [];
    return _gerarSlots(h.horaAbertura, h.horaFechamento);
  }

  List<String> _gerarSlots(String abertura, String fechamento) {
    final slots = <String>[];
    int h = int.parse(abertura.split(':')[0]);
    final hFim = int.parse(fechamento.split(':')[0]);
    while (h < hFim) {
      slots.add('${h.toString().padLeft(2, '0')}:00');
      h++;
    }
    return slots;
  }

  List<String> get _horariosFim {
    if (_horaInicioSel == null) return [];
    final todos = _horariosDisponiveis;
    final idx = todos.indexOf(_horaInicioSel!);
    if (idx < 0) return [];
    return todos.sublist(idx + 1);
  }

  double get _totalAPagar {
    if (_horaInicioSel == null || _horaFimSel == null) return 0;
    final hIni = int.parse(_horaInicioSel!.split(':')[0]);
    final hFim = int.parse(_horaFimSel!.split(':')[0]);
    final horas = (hFim - hIni).toDouble();
    return widget.quadra.valorHora * horas;
  }

  String _formatarData(DateTime d) {
    const meses = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    const diasSemana = ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'];
    return '${diasSemana[d.weekday % 7]}, ${d.day} ${meses[d.month - 1]}';
  }

  Future<void> _escolherDia() async {
    final hoje = DateTime.now();
    DateTime tempDia = _diaSelecionado;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final primeiroDia = DateTime(tempDia.year, tempDia.month, 1);
          final diasNoMes   = DateUtils.getDaysInMonth(tempDia.year, tempDia.month);
          final offset      = primeiroDia.weekday % 7;
          const nomesMes = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho',
                            'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: kTextPri),
                      onPressed: () {
                        final prev = DateTime(tempDia.year, tempDia.month - 1, 1);
                        if (!prev.isBefore(DateTime(hoje.year, hoje.month, 1))) {
                          setLocal(() => tempDia = DateTime(prev.year, prev.month,
                            tempDia.day.clamp(1, DateUtils.getDaysInMonth(prev.year, prev.month))));
                        }
                      },
                    ),
                    Text('${nomesMes[tempDia.month - 1]} ${tempDia.year}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPri)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: kTextPri),
                      onPressed: () {
                        final next = DateTime(tempDia.year, tempDia.month + 1, 1);
                        if (next.isBefore(hoje.add(const Duration(days: 365)))) {
                          setLocal(() => tempDia = DateTime(next.year, next.month,
                            tempDia.day.clamp(1, DateUtils.getDaysInMonth(next.year, next.month))));
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'].map((d) =>
                    Expanded(child: Center(child: Text(d,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSec))))
                  ).toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1),
                  itemCount: offset + diasNoMes,
                  itemBuilder: (_, i) {
                    if (i < offset) return const SizedBox();
                    final dia = DateTime(tempDia.year, tempDia.month, i - offset + 1);
                    final passado = dia.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
                    final sel = dia.day == tempDia.day && dia.month == tempDia.month && dia.year == tempDia.year;
                    final ehHoje = dia.day == hoje.day && dia.month == hoje.month && dia.year == hoje.year;
                    return GestureDetector(
                      onTap: passado ? null : () => setLocal(() => tempDia = dia),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: sel ? kLaranja : Colors.transparent,
                          shape: BoxShape.circle,
                          border: ehHoje && !sel ? Border.all(color: kLaranja, width: 1.5) : null,
                        ),
                        child: Center(child: Text(dia.day.toString(),
                          style: TextStyle(fontSize: 14,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                            color: passado ? kBorder : sel ? Colors.white : kTextPri))),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, tempDia),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kLaranja, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Confirmar',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (picked != null) {
      setState(() {
        _diaSelecionado = picked;
        _horaInicioSel = null;
        _horaFimSel = null;
      });
    }
  }

  Future<void> _confirmarReserva() async {
    if (_horaInicioSel == null || _horaFimSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o horário de início e término'),
          backgroundColor: kLaranja,
        ),
      );
      return;
    }

    setState(() => _loadingReserva = true);
    try {
      final hIni = int.parse(_horaInicioSel!.split(':')[0]);
      final hFim = int.parse(_horaFimSel!.split(':')[0]);
      final inicio = DateTime(_diaSelecionado.year, _diaSelecionado.month,
          _diaSelecionado.day, hIni, 0);
      final fim = DateTime(_diaSelecionado.year, _diaSelecionado.month,
          _diaSelecionado.day, hFim, 0);

      final reserva = await ReservaService.criar(
        quadraId: widget.quadra.id,
        dataHoraInicio: inicio,
        dataHoraFim: fim,
      );

      if (!mounted) return;

      final checkout = await PagamentoService.iniciarPagamentoReserva(reserva.id);

      if (!mounted) return;

      await launchUrl(
        Uri.parse(checkout.initPoint),
        customTabsOptions: const CustomTabsOptions(
          shareState: CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,
        ),
        safariVCOptions: const SafariViewControllerOptions(barCollapsingEnabled: true),
      );

      if (mounted) {
        setState(() {
          _horaInicioSel = null;
          _horaFimSel = null;
        });
      }

      if (mounted) {
        await _verificarPagamento(reserva.id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red[700],
        content: Text(e.toString().replaceFirst('Exception: ', '')),
      ));
    } finally {
      if (mounted) setState(() => _loadingReserva = false);
    }
  }

  Future<void> _verificarPagamento(int reservaId) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DialogoVerificandoPagamento(),
    );

    Reserva? atual;
    for (int tentativa = 0; tentativa < 6; tentativa++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        atual = await ReservaService.buscarPorId(reservaId);
        if (atual.isConfirmada || atual.isCancelada) break;
      } catch (_) {
      }
    }

    if (!mounted) return;
    Navigator.pop(context); 

    if (atual != null && atual.isConfirmada) {
      _mostrarResultadoPagamento(
        sucesso: true,
        titulo: 'Reserva confirmada!',
        mensagem: 'Seu pagamento foi aprovado e a reserva está garantida.',
      );
    } else if (atual != null && atual.isCancelada) {
      _mostrarResultadoPagamento(
        sucesso: false,
        titulo: 'Reserva cancelada',
        mensagem: 'Não foi possível confirmar o pagamento e a reserva foi cancelada.',
      );
    } else {
      _mostrarResultadoPagamento(
        sucesso: null,
        titulo: 'Aguardando confirmação',
        mensagem:
            'Ainda não recebemos a confirmação do pagamento. Isso pode levar alguns instantes — '
            'confira o status em "Minhas reservas" daqui a pouco.',
      );
    }
  }

  void _mostrarResultadoPagamento({
    required bool? sucesso,
    required String titulo,
    required String mensagem,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(
            sucesso == true
                ? Icons.check_circle_rounded
                : sucesso == false
                    ? Icons.cancel_rounded
                    : Icons.hourglass_top_rounded,
            color: sucesso == true
                ? Colors.green
                : sucesso == false
                    ? Colors.red
                    : kLaranja,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(titulo, style: const TextStyle(fontSize: 16))),
        ]),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar aqui'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kLaranja,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MinhasReservasScreen()),
              );
            },
            child: const Text('Ver minhas reservas',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = _horariosDisponiveis;
    final slotsInicio = slots;
    final slotsFim = _horariosFim;
    final horarioDia = _horarioDia;

    return Scaffold(
      backgroundColor: kOffWhite,
      body: Stack(
        children: [
          Column(children: [
            SizedBox(
              height: 260,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.quadra.fotos.isNotEmpty
                      ? Image.network(widget.quadra.fotos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]))
                      : Image.asset('assets/images/beach_tela_inicial.png', fit: BoxFit.cover),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox()),
          ]),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reserve',
                        style: TextStyle(color: Colors.white70, fontSize: 14,
                            fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                    Text(widget.quadra.nome.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 28,
                            fontWeight: FontWeight.w900, letterSpacing: 1)),
                    if (widget.quadra.coberturaLabel.isNotEmpty)
                      Text(widget.quadra.coberturaLabel,
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: kOffWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        _secaoTitulo(Icons.calendar_today_outlined, 'Escolha o dia'),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _escolherDia,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: kCard, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(children: [
                              const Icon(Icons.event_rounded, color: kLaranja, size: 20),
                              const SizedBox(width: 12),
                              Text(_formatarData(_diaSelecionado),
                                  style: const TextStyle(fontSize: 15,
                                      fontWeight: FontWeight.w600, color: kTextPri)),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded, color: kTextSec, size: 20),
                            ]),
                          ),
                        ),

                        if (horarioDia != null) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: kTextSec),
                            const SizedBox(width: 6),
                            Text(
                              'Arena aberta das ${horarioDia.horaAbertura} às ${horarioDia.horaFechamento}',
                              style: const TextStyle(fontSize: 12, color: kTextSec),
                            ),
                          ]),
                        ] else if (widget.horarios.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                            const SizedBox(width: 6),
                            const Text('Arena fechada neste dia',
                                style: TextStyle(fontSize: 12, color: Colors.orange)),
                          ]),
                        ],

                        const SizedBox(height: 24),

                        _secaoTitulo(Icons.access_time_rounded, 'Horário de início'),
                        const SizedBox(height: 10),
                        if (slots.isEmpty)
                          _aviso('Sem horários disponíveis para este dia')
                        else
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: slotsInicio.map((h) {
                              final sel = _horaInicioSel == h;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _horaInicioSel = h;
                                  _horaFimSel = null;
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel ? kLaranja : kCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: sel ? kLaranja : kBorder),
                                  ),
                                  child: Text(h,
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600,
                                          color: sel ? Colors.white : kTextPri)),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),

                        _secaoTitulo(Icons.flag_rounded, 'Horário de término'),
                        const SizedBox(height: 10),
                        if (_horaInicioSel == null)
                          _aviso('Selecione primeiro o horário de início')
                        else if (slotsFim.isEmpty)
                          _aviso('Nenhum horário de término disponível')
                        else
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: slotsFim.map((h) {
                              final sel = _horaFimSel == h;
                              final hIni = int.parse(_horaInicioSel!.split(':')[0]);
                              final hF   = int.parse(h.split(':')[0]);
                              final dur  = hF - hIni;
                              return GestureDetector(
                                onTap: () => setState(() => _horaFimSel = h),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel ? kLaranja : kCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: sel ? kLaranja : kBorder),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(h,
                                          style: TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w600,
                                              color: sel ? Colors.white : kTextPri)),
                                      Text('${dur}h',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: sel ? Colors.white70 : kTextSec)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        if (_horaInicioSel != null && _horaFimSel != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kLaranja.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kLaranja.withValues(alpha: 0.2)),
                            ),
                            child: Column(children: [
                              _linhaResumo('Data', _formatarData(_diaSelecionado)),
                              const SizedBox(height: 8),
                              _linhaResumo('Início', _horaInicioSel!),
                              const SizedBox(height: 8),
                              _linhaResumo('Término', _horaFimSel!),
                              const SizedBox(height: 8),
                              _linhaResumo('Duração',
                                  '${int.parse(_horaFimSel!.split(':')[0]) - int.parse(_horaInicioSel!.split(':')[0])}h'),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total',
                          style: TextStyle(fontSize: 13, color: kTextSec)),
                      Text(
                        _horaInicioSel != null && _horaFimSel != null
                            ? 'R\$ ${_totalAPagar.toStringAsFixed(2)}'
                            : 'R\$ --',
                        style: const TextStyle(fontSize: 26,
                            fontWeight: FontWeight.w800, color: kTextPri),
                      ),
                      Text('R\$ ${widget.quadra.valorHora.toStringAsFixed(2)}/hora',
                          style: const TextStyle(fontSize: 12, color: kTextSec)),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_loadingReserva ||
                              _horaInicioSel == null || _horaFimSel == null)
                          ? null
                          : _confirmarReserva,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLaranja,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: kLaranja.withValues(alpha: 0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                      ),
                      child: _loadingReserva
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Row(children: [
                              Icon(Icons.payment_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Reservar',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secaoTitulo(IconData icon, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(icon, size: 16, color: kTextSec),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: kTextPri)),
        ]),
      );

  Widget _aviso(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: kTextSec),
          const SizedBox(width: 8),
          Text(msg, style: const TextStyle(fontSize: 13, color: kTextSec)),
        ]),
      );

  Widget _linhaResumo(String label, String valor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: kTextSec)),
          Text(valor,
              style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: kTextPri)),
        ],
      );
}

class _DialogoVerificandoPagamento extends StatelessWidget {
  const _DialogoVerificandoPagamento();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: kLaranja),
            SizedBox(height: 16),
            Text('Verificando pagamento...',
                style: TextStyle(fontWeight: FontWeight.w600, color: kTextPri)),
            SizedBox(height: 6),
            Text('Aguarde um instante',
                style: TextStyle(fontSize: 12, color: kTextSec)),
          ],
        ),
      ),
    );
  }
}