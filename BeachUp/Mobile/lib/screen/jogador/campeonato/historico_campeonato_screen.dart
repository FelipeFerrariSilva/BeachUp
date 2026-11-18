import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/historico_campeonato.dart';
import 'package:flutter_application_1/service/historico_campeonato.service.dart';
import 'package:flutter_application_1/widget/custom_drawer.dart';

import 'package:flutter_application_1/provider/auth_provider.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/widget/navbar.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HistoricoCampeonatosScreen(),
      ),
    ),
  );
}

class HistoricoCampeonatosScreen extends StatefulWidget {
  const HistoricoCampeonatosScreen({super.key});

  @override
  State<HistoricoCampeonatosScreen> createState() =>
      _HistoricoCampeonatosScreenState();
}

class _HistoricoCampeonatosScreenState
    extends State<HistoricoCampeonatosScreen> {
  final service = HistoricoCampeonatoService();

  late Future<List<HistoricoCampeonatoModel>> _future;

  bool mostrarProximos = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _future = service.getHistoricoCampeonatos();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ATIVO':
        return Colors.green;
      case 'PENDENTE':
        return Colors.orange;
      case 'CANCELADO':
      case 'RECUSADO':
        return Colors.red;
      case 'FINALIZADO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  List<HistoricoCampeonatoModel> _filtrar(
    List<HistoricoCampeonatoModel> lista,
  ) {
    final now = DateTime.now();

    return lista.where((item) {
      final status = item.status.toUpperCase();

      DateTime? data;
      if (item.dataCampeonato != null) {
        try {
          data = DateTime.parse(item.dataCampeonato!);
        } catch (_) {}
      }

      final isFinalizado =
          status == 'FINALIZADO' || (data != null && data.isBefore(now));

      if (mostrarProximos) {
        return !isFinalizado;
      } else {
        return isFinalizado;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = kLaranja;

    return Scaffold(
      appBar: CustomAppBarPerfil(),
      backgroundColor: appBg(context),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white),
                      SizedBox(width: 6),
                      Text("Voltar", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      "Histórico de Campeonatos",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Text(
                  "Acompanhe suas inscrições e torneios",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => mostrarProximos = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: mostrarProximos ? primaryColor : Colors.white,
                        border: Border.all(color: primaryColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "Próximos",
                          style: TextStyle(
                            color: mostrarProximos
                                ? Colors.white
                                : primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => mostrarProximos = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !mostrarProximos ? primaryColor : Colors.white,
                        border: Border.all(color: primaryColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "Finalizados",
                          style: TextStyle(
                            color: !mostrarProximos
                                ? Colors.white
                                : primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: FutureBuilder<List<HistoricoCampeonatoModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Erro ao carregar"),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _carregar,
                          child: const Text("Tentar novamente"),
                        ),
                      ],
                    ),
                  );
                }

                final lista = snapshot.data ?? [];
                final filtrada = _filtrar(lista);

                if (filtrada.isEmpty) {
                  return Center(
                    child: Text(
                      mostrarProximos
                          ? "Nenhum campeonato próximo encontrado."
                          : "Nenhum campeonato finalizado encontrado.",
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtrada.length,
                  itemBuilder: (context, index) {
                    final item = filtrada[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: appCard(context),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nomeCampeonato,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text("Time: ${item.nomeTime}"),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Text("Status: "),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    item.status,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.status,
                                  style: TextStyle(
                                    color: _getStatusColor(item.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (item.dataInscricao != null) ...[
                            const SizedBox(height: 8),
                            Text("Inscrição: ${item.dataInscricao}"),
                          ],

                          if (item.dataCampeonato != null) ...[
                            const SizedBox(height: 6),
                            Text("Data: ${item.dataCampeonato}"),
                          ],

                          if (item.taxaInscricao != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              "Taxa: R\$ ${item.taxaInscricao!.toStringAsFixed(2)}",
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}