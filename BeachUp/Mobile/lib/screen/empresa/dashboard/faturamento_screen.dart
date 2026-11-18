import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/metricas_empresa.dart';
import 'package:flutter_application_1/service/metricas_service.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:flutter_application_1/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class FaturamentoScreen extends StatefulWidget {
  const FaturamentoScreen({super.key});

  @override
  State<FaturamentoScreen> createState() => _FaturamentoScreenState();
}

class _FaturamentoScreenState extends State<FaturamentoScreen> {
  late Future<MetricasEmpresa> _futureMetricas;

  @override
  void initState() {
    super.initState();
    _futureMetricas = MetricasService.obterMetricasEmpresa();
  }

  Future<void> _recarregar() async {
    setState(() {
      _futureMetricas = MetricasService.obterMetricasEmpresa();
    });
    await _futureMetricas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBg(context),
      appBar: CustomAppBarPerfil(),
      body: SafeArea(
      child: FutureBuilder<MetricasEmpresa>(
        future: _futureMetricas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kLaranja));
          }
          if (snapshot.hasError) {
            return _buildErro();
          }
          final metricas = snapshot.data!;
          return RefreshIndicator(
            color: kLaranja,
            onRefresh: _recarregar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Text('Painel',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: kTextPri,
                            letterSpacing: -0.5)),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kLaranja, Color(0xFFFF9240)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('FATURAMENTO DO MÊS',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          Text(
                            _formatarMoeda(metricas.faturamentoMesAtual),
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.trending_up_rounded,
                                color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _formatarMoeda(metricas.faturamentoTotal) + ' total acumulado',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ]),
                          const SizedBox(height: 20),
                          Row(children: [
                            _metricaCard('${metricas.totalReservas}', 'Reservas'),
                            const SizedBox(width: 10),
                            _metricaCard('${metricas.reservasHoje}', 'Hoje'),
                            const SizedBox(width: 10),
                            _metricaCard(
                                _formatarMoeda(metricas.ticketMedio).replaceAll('R\$ ', 'R\$'),
                                'Ticket médio'),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Próximas reservas',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: kTextPri)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kLaranja.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${metricas.reservasHoje} hoje',
                            style: const TextStyle(
                                color: kLaranja,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildReservasCard(metricas),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: const Text('Ocupação por horário',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kTextPri)),
                  ),
                  _buildGraficoMensal(metricas.faturamentoUltimos6Meses),

                  if (metricas.topQuadras.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: const Text('Quadras mais reservadas',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kTextPri)),
                    ),
                    _buildTopQuadras(metricas.topQuadras),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _metricaCard(String valor, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: appCard(context).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valor,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildReservasCard(MetricasEmpresa metricas) {
    final reservas = [
      if (metricas.reservasConfirmadas > 0)
        {'nome': 'Confirmadas', 'qtd': metricas.reservasConfirmadas},
      if (metricas.reservasPendentes > 0)
        {'nome': 'Pendentes', 'qtd': metricas.reservasPendentes},
      if (metricas.reservasCanceladas > 0)
        {'nome': 'Canceladas', 'qtd': metricas.reservasCanceladas},
    ];

    if (reservas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: appCard(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder),
          ),
          child: const Center(
            child: Text('Nenhuma reserva por enquanto.',
                style: TextStyle(color: kTextSec)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: reservas.map((r) {
          final nome = r['nome'] as String;
          final qtd = r['qtd'] as int;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appCard(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kLaranja.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_rounded,
                      color: kLaranja, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kTextPri)),
                      Text('$qtd reservas',
                          style: const TextStyle(
                              fontSize: 12, color: kTextSec)),
                    ],
                  ),
                ),
                Text(
                  '$qtd',
                  style: const TextStyle(
                      color: kLaranja,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGraficoMensal(List<FaturamentoMensal> dados) {
    if (dados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: appCard(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder),
          ),
          child: const Center(
            child: Text('Sem dados ainda.',
                style: TextStyle(color: kTextSec)),
          ),
        ),
      );
    }

    final maxValor = dados.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    const double barraLargura = 44.0;
    final double graficoLargura = dados.length * barraLargura;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: appCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: graficoLargura,
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dados.map((d) {
                final alturaRelativa =
                    maxValor > 0 ? (d.total / maxValor) : 0.0;
                return SizedBox(
                  width: barraLargura,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatarValorCurto(d.total),
                          style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: kTextSec),
                        ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: 90 * alturaRelativa,
                          decoration: BoxDecoration(
                            color: kLaranja,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(d.mesNome,
                            style: const TextStyle(
                                fontSize: 9, color: kTextSec)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopQuadras(List<QuadraRanking> quadras) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: appCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
          ],
        ),
        child: Column(
          children: quadras.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: i == quadras.length - 1 ? 0 : 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kLaranja.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kLaranja)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(q.nomeQuadra,
                        style: const TextStyle(fontSize: 13, color: kTextPri),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${q.totalReservas} reservas',
                      style: const TextStyle(fontSize: 12, color: kTextSec)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: kTextSec, size: 48),
          const SizedBox(height: 12),
          const Text('Não foi possível carregar.',
              style: TextStyle(color: kTextSec)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _recarregar,
            style: ElevatedButton.styleFrom(
              backgroundColor: kLaranja,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatarMoeda(double valor) =>
      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatarValorCurto(double valor) {
    if (valor >= 1000) return 'R\$${(valor / 1000).toStringAsFixed(1)}k';
    return 'R\$${valor.toInt()}';
  }
}