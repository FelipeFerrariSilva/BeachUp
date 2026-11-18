import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:flutter_application_1/model/CampeonatoDTO.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:http/http.dart' as http;

class InscricaoCampeonatoScreen extends StatefulWidget {
  final CampeonatoDTO campeonato;

  const InscricaoCampeonatoScreen({super.key, required this.campeonato});

  @override
  State<InscricaoCampeonatoScreen> createState() =>
      _InscricaoCampeonatoScreenState();
}

class TimeDTO {
  final int id;
  final String nome;
  final int membrosAceitos;

  TimeDTO({required this.id, required this.nome, required this.membrosAceitos});

  factory TimeDTO.fromJson(Map<String, dynamic> json) {
    final membros = (json['membros'] as List? ?? []);
    final aceitos = membros
        .where((m) => (m['status'] ?? '').toString().toUpperCase() == 'ACEITO')
        .length;
    return TimeDTO(
      id: json['id'],
      nome: json['nome'],
      membrosAceitos: aceitos,
    );
  }
}

class _InscricaoCampeonatoScreenState
    extends State<InscricaoCampeonatoScreen> {
  bool loadingTimes = true;
  bool inscrevendo = false;
  TimeDTO? timeSelecionado;
  List<TimeDTO> meusTimes = [];

  @override
  void initState() {
    super.initState();
    _buscarMeusTimes();
  }

  Future<void> _buscarMeusTimes() async {
    setState(() => loadingTimes = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() { meusTimes = []; loadingTimes = false; });
        return;
      }

      int? idJogador;
      final meRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/jogador/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (meRes.statusCode == 200) {
        idJogador = jsonDecode(meRes.body)['id'] as int?;
      }

      final timesRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/times'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (timesRes.statusCode != 200) {
        setState(() { meusTimes = []; loadingTimes = false; });
        return;
      }

      final lista = jsonDecode(timesRes.body) as List;
      final todos = lista.map((e) => TimeDTO.fromJson(e)).toList();

      List<TimeDTO> meus = todos;
      if (idJogador != null) {
        meus = todos.where((t) {
          final raw = lista.firstWhere((e) => e['id'] == t.id,
              orElse: () => <String, dynamic>{});
          final membros = (raw['membros'] as List? ?? []);
          final ehDono = raw['idJogadorDono'] == idJogador;
          final ehMembro = membros.any((m) =>
              m['idJogador'] == idJogador &&
              (m['status'] ?? '').toString().toUpperCase() == 'ACEITO');
          return ehDono || ehMembro;
        }).toList();
      }

      setState(() { meusTimes = meus; loadingTimes = false; });
    } catch (e) {
      setState(() { meusTimes = []; loadingTimes = false; });
    }
  }

  Future<void> _inscrever() async {
    if (timeSelecionado == null) { _snack('Selecione seu time'); return; }
    if (timeSelecionado!.membrosAceitos < 2) {
      _snack('Seu time precisa ter 2 jogadores aceitos'); return;
    }

    setState(() => inscrevendo = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _snack('Sessão expirada. Faça login novamente.');
        setState(() => inscrevendo = false);
        return;
      }

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/campeonatos/inscrever'
          '/${widget.campeonato.tokenInscricao}'
          '/time/${timeSelecionado!.id}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      setState(() => inscrevendo = false);
      if (!mounted) return;

      if (response.statusCode == 200) {
        _mostrarSucesso();
      } else {
        final body = jsonDecode(response.body);
        final msg = body['message'] ?? body['erro'] ?? 'Erro ao inscrever time';
        _snack(msg.toString());
      }
    } catch (e) {
      setState(() => inscrevendo = false);
      _snack('Sem conexão com o servidor');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        content: Text(msg, style: const TextStyle(color: kTextPri)),
      ),
    );
  }

  void _mostrarSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration:
                    const BoxDecoration(color: kLaranja, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Inscrição confirmada!',
                style: TextStyle(
                    color: kTextPri,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${timeSelecionado!.nome}\n${widget.campeonato.nome}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextSec, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLaranja,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text(
                    'Ir para início',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPri),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: kOffWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: const [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inscrição',
                          style: TextStyle(
                              color: kTextSec, fontSize: 14, letterSpacing: 1)),
                      Text('CAMPEONATO',
                          style: TextStyle(
                              color: kLaranja,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kLaranja),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.emoji_events,
                                color: kLaranja, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(widget.campeonato.nome,
                                  style: const TextStyle(
                                      color: kTextPri,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          _infoRow(Icons.bar_chart, widget.campeonato.categoria),
                          const SizedBox(height: 6),
                          _infoRow(Icons.calendar_today,
                              '${widget.campeonato.dataInicio} → ${widget.campeonato.dataFim}'),
                          const SizedBox(height: 6),
                          _infoRow(Icons.group,
                              '${widget.campeonato.totalInscritos}/16 duplas inscritas'),
                          if (widget.campeonato.descricao.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _infoRow(
                                Icons.description, widget.campeonato.descricao),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _sectionLabel(Icons.group_outlined, 'Selecione seu time'),
                    const SizedBox(height: 12),

                    if (loadingTimes)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child:
                              CircularProgressIndicator(color: kLaranja),
                        ),
                      )
                    else if (meusTimes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: const Color(0xFFE5E5E0)),
                        ),
                        child: Column(children: [
                          const Icon(Icons.group_off,
                              color: kTextSec, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Você não tem nenhum time cadastrado.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kTextSec),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Criar um time',
                                style: TextStyle(color: kLaranja)),
                          ),
                        ]),
                      )
                    else
                      ...meusTimes.map((time) {
                        final isSelected = timeSelecionado?.id == time.id;
                        final temMembros = time.membrosAceitos >= 2;
                        return GestureDetector(
                          onTap: temMembros
                              ? () => setState(() => timeSelecionado = time)
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? kLaranja
                                    : const Color(0xFFE5E5E0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? kLaranja
                                      : const Color(0xFFE5E5E0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.group,
                                    color: isSelected
                                        ? Colors.white
                                        : kTextSec,
                                    size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(time.nome,
                                        style: TextStyle(
                                            color: temMembros
                                                ? kTextPri
                                                : kTextSec,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      temMembros
                                          ? '${time.membrosAceitos} jogadores'
                                          : 'Precisa de 2 jogadores aceitos',
                                      style: TextStyle(
                                          color: temMembros
                                              ? kTextSec
                                              : Colors.red.shade400,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? kLaranja
                                        : const Color(0xFFE5E5E0),
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? kLaranja
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 12, color: Colors.white)
                                    : null,
                              ),
                            ]),
                          ),
                        );
                      }),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kLaranja,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: inscrevendo ? null : _inscrever,
                        child: inscrevendo
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('Confirmar inscrição',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String label) => Row(children: [
        Icon(icon, size: 14, color: kTextSec),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: kTextSec, fontSize: 12)),
      ]);

  Widget _infoRow(IconData icon, String texto) => Row(children: [
        Icon(icon, size: 14, color: kTextSec),
        const SizedBox(width: 8),
        Expanded(
            child: Text(texto,
                style: const TextStyle(color: kTextSec, fontSize: 13))),
      ]);
}