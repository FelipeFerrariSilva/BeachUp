import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/widget/navbar.dart';

class NotificationItem {
  final String titulo;
  final String subtitulo;
  final DateTime data;
  final IconData icone;
  final Color cor;

  const NotificationItem({
    required this.titulo,
    required this.subtitulo,
    required this.data,
    this.icone = Icons.sports_tennis,
    this.cor = const Color(0xFFFF8000),
  });
}

class NotificacaoService {
  static Future<List<NotificationItem>> buscar() async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reservas/minhas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) return [];

    final lista = jsonDecode(res.body) as List;
    final agora = DateTime.now();
    final notifs = <NotificationItem>[];

    for (final item in lista) {
      try {
        final inicio  = DateTime.parse(item['dataHoraInicio']);
        final status  = (item['status'] ?? '').toString().toUpperCase();
        final quadra  = item['nomeQuadra'] ?? 'Quadra';
        final diff    = inicio.difference(agora);

        if (status == 'CONFIRMADA' && diff.inMinutes > 0 && diff.inHours <= 24) {
          final quando = diff.inHours >= 1
              ? 'em ${diff.inHours}h'
              : 'em ${diff.inMinutes} min';
          notifs.add(NotificationItem(
            titulo: 'Lembrete: $quadra $quando',
            subtitulo: _fmtData(inicio),
            data: inicio,
            icone: Icons.alarm_rounded,
            cor: kLaranja,
          ));
        } else if (status == 'PENDENTE' && inicio.isAfter(agora)) {
          notifs.add(NotificationItem(
            titulo: 'Reserva pendente em $quadra',
            subtitulo: 'Aguardando confirmação · ${_fmtData(inicio)}',
            data: inicio,
            icone: Icons.hourglass_top_rounded,
            cor: Colors.amber,
          ));
        } else if (status == 'CONFIRMADA' &&
            agora.difference(inicio).inHours.abs() <= 2 &&
            inicio.isBefore(agora.add(const Duration(minutes: 10)))) {
          notifs.add(NotificationItem(
            titulo: '✅ Reserva confirmada em $quadra',
            subtitulo: _fmtData(inicio),
            data: inicio,
            icone: Icons.check_circle_rounded,
            cor: Colors.green,
          ));
        }
      } catch (_) {}
    }

    notifs.sort((a, b) => a.data.compareTo(b.data));
    return notifs;
  }

  static String _fmtData(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final h   = d.hour.toString().padLeft(2, '0');
    final m   = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes às $h:$m';
  }
}

class NotificationDrawer extends StatefulWidget {
  final double? width;
  const NotificationDrawer({super.key, this.width});

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> {
  List<NotificationItem> _items = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final items = await NotificacaoService.buscar();
      if (mounted) setState(() { _items = items; _carregando = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = 'Erro ao carregar'; _carregando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: widget.width,
      backgroundColor: kCard,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Notificações',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_items.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kLaranja,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${_items.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: _carregando
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: kLaranja))
                  : _erro != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_rounded,
                                  color: Colors.grey, size: 40),
                              const SizedBox(height: 10),
                              Text(_erro!,
                                  style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  setState(() { _carregando = true; _erro = null; });
                                  _carregar();
                                },
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      : _items.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_off_outlined,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('Nenhuma notificação',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: kLaranja,
                              onRefresh: _carregar,
                              child: ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final n = _items[i];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          n.cor.withValues(alpha: 0.12),
                                      child: Icon(n.icone,
                                          color: n.cor, size: 20),
                                    ),
                                    title: Text(n.titulo,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(n.subtitulo,
                                        style: const TextStyle(fontSize: 12)),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
