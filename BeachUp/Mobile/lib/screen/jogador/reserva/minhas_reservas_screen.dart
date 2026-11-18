import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/reserva.dart';
import 'package:flutter_application_1/service/reserva_service.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:flutter_application_1/widget/custom_drawer.dart';
import 'package:flutter_application_1/widget/navbar.dart';

enum StatusReserva { pendente, confirmada, cancelada }

class MinhasReservasScreen extends StatefulWidget {
  const MinhasReservasScreen({super.key});

  @override
  State<MinhasReservasScreen> createState() => _MinhasReservasScreenState();
}

class _MinhasReservasScreenState extends State<MinhasReservasScreen> {
  late Future<List<Reserva>>
  _futureReservas;

  @override
  void initState() {

    super.initState();
    _futureReservas = ReservaService.minhasReservas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBg(context),
      appBar: CustomAppBarPerfil(),
      body: FutureBuilder<List<Reserva>>(
        future: _futureReservas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: kLaranja),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar reservas: ${snapshot.error}'),
            );
          }

          final reservas = snapshot.data ?? [];

          if (reservas.isEmpty) {
            return Center(child: Text('Você ainda não tem reservas'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final reserva = reservas[index]; 
              return _buildCardReserva(reserva); 
            },
          );
        },
      ),
    );
  }

  Widget _buildCardReserva(Reserva reserva) {
    Color corStatus;
    String textoStatus;

    if (reserva.isConfirmada) {
      corStatus = Color(0xFF2EA043);
      textoStatus = 'Confirmada';
    } else if (reserva.isPendente) {
      corStatus = Color(0xFFFF8C00);
      textoStatus = 'Pendente';
    } else {
      corStatus = Color(0xFFDC3545);
      textoStatus = 'Cancelada';
    }

    final agora = DateTime.now();
    final limiteParaCancelar = reserva.dataHoraInicio.subtract(
      Duration(hours: 24),
    ); 

    final podeCancel =
        agora.isBefore(limiteParaCancelar) &&
        !reserva
            .isCancelada;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reserva.isCancelada
            ? appCard(context).withValues(alpha: 0.6)
            : appCard(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kLaranja.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_tennis_rounded,
                  color: kLaranja,
                ),
              ),

              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reserva.nomeQuadra,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: appTextPri(context),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _formatarDataHora(
                        reserva.dataHoraInicio,
                        reserva.dataHoraFim,
                      ),

                      style: TextStyle(
                        fontSize: 12,
                        color: appTextSec(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: corStatus.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  textoStatus,
                  style: TextStyle(
                    color: corStatus,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 28, color: appBorder(context)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'R\$ ${reserva.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',

                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: appTextPri(context),
                    ),
                  ),
                  Text(
                    'Valor total',
                    style: TextStyle(
                      fontSize: 10,
                      color: appTextSec(context),
                    ),
                  ),
                ],
              ),
              if (!reserva.isCancelada)
                if (podeCancel)
                  TextButton(
                    onPressed: () => _confirmarCancelamento(reserva),

                    style: TextButton.styleFrom(
                      backgroundColor: Color(
                        0xFFDC3545,
                      ).withValues(alpha: 0.08),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancelar reserva',
                      style: TextStyle(
                        color: Color(0xFFDC3545),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: appBorder(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Fora do prazo',
                      style: TextStyle(
                        color: appTextSec(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatarDataHora(DateTime inicio, DateTime fim) {
    final dia = inicio.day.toString().padLeft(2, '0');
    final mes = _nomeMes(inicio.month);
    final horaInicio =
        '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
    final horaFim =
        '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}';
    return '$dia de $mes • $horaInicio - $horaFim';
  }

  String _nomeMes(int mes) {
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return meses[mes - 1];
  }

  Future<void> _confirmarCancelamento(Reserva reserva) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Cancelar reserva',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tem certeza que deseja cancelar a reserva na ${reserva.nomeQuadra}? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Voltar',
              style: TextStyle(
                color: appTextSec(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sim, cancelar',
              style: TextStyle(
                color: Color(0xFFDC3545),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      await ReservaService.cancelar(reserva.id);

      setState(() {
        _futureReservas = ReservaService.minhasReservas();
      });

      if (mounted) { 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserva cancelada com sucesso!'),
            backgroundColor: Color(0xFF2EA043),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
      }
    }
  }
}