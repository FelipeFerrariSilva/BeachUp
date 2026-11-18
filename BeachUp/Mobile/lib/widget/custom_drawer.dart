import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/empresa/dashboard/faturamento_screen.dart';
import 'package:flutter_application_1/screen/empresa/plano/planos_screen.dart';
import 'package:flutter_application_1/screen/jogador/home_screen.dart';
import 'package:flutter_application_1/screen/jogador/time/criar_time_jogador_screen.dart';
import 'package:flutter_application_1/screen/jogador/time/meus_times_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/provider/auth_provider.dart';
import 'package:flutter_application_1/screen/jogador/campeonato/Lista_Campeonatos_Screen.dart';
import 'package:flutter_application_1/screen/jogador/reserva/minhas_reservas_screen.dart';
import 'package:flutter_application_1/screen/home/start_screen.dart';
import 'package:flutter_application_1/screen/home/sobre_screen.dart';
import 'package:flutter_application_1/screen/empresa/arena/cadastro_arena_screen.dart';
import 'package:flutter_application_1/screen/empresa/arena/arenas_empresa_screen.dart';
import 'package:flutter_application_1/model/arena.dart';
import 'package:flutter_application_1/service/arena_service.dart';
import 'package:flutter_application_1/screen/empresa/campeonato/criar_campeonato_screen.dart';
import 'package:flutter_application_1/screen/empresa/campeonato/meus_campeonatos_screen.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Drawer(
      backgroundColor: appCard(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Image.asset('assets/images/logo1.png', height: 48),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('BeachUp', style: TextStyle(color: kTextPri, fontSize: 18, fontWeight: FontWeight.w800)),
                    const Text('Beach Tennis Platform', style: TextStyle(color: kTextSec, fontSize: 11)),
                  ]),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: kTextSec, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: kBorder, height: 1),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (!auth.estaLogado) ...[
                    _item(context, Icons.home_outlined, 'Início', const StartScreen()),
                    _item(context, Icons.info_outline, 'Sobre nós', const SobreScreen()),
                  ],
                  if (auth.isJogador) ...[
                    _item(context, Icons.stadium_outlined, 'Encontrar Arenas', const HomeJogadorScreen()),
                    _item(context, Icons.group_add_outlined, 'Criar Time', const CriarTimeJogadorScreen()),
                    _item(context, Icons.groups_outlined, 'Meus Times', const MeusTimesScreen()),
                    _item(context, Icons.emoji_events_outlined, 'Campeonatos', const ListaCampeonatosScreen()),
                    _item(context, Icons.book_online_outlined, 'Minhas Reservas', const MinhasReservasScreen()),
                  ],
                  if (auth.isEmpresa) ...[
                    _item(context, Icons.grid_view_outlined, 'Dashboard', const FaturamentoScreen()),
                    _item(context, Icons.add_business_outlined, 'Criar Arena', const CriarArenaScreen()),
                    _item(context, Icons.stadium_outlined, 'Minhas Arenas', const MinhasArenaScreen(standalone: true)),
                    _itemAsync(context, Icons.emoji_events_outlined, 'Criar Campeonato', () => _irParaCriarCampeonato(context, auth.accessToken)),
                    _item(context, Icons.emoji_events_outlined, 'Meus Campeonatos', const MeusCampeonatosScreen()),
                    _item(context, Icons.workspace_premium_outlined, 'Planos', const PlanosScreen()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, Widget tela) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: kLaranja.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: kLaranja, size: 18),
      ),
      title: Text(title, style: const TextStyle(color: kTextPri, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: kTextSec, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
      },
    );
  }

  Widget _itemAsync(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: kLaranja.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: kLaranja, size: 18),
      ),
      title: Text(title, style: const TextStyle(color: kTextPri, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: kTextSec, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: () { Navigator.pop(context); onTap(); },
    );
  }

  Future<void> _irParaCriarCampeonato(BuildContext context, String token) async {
    List<Arena> arenas = [];
    try { arenas = await ArenaService.getMinhas(); } catch (e) { debugPrint('Erro: $e'); }
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CriarCampeonatoScreen(
        accessToken: token,
        arenas: arenas.map((a) => <String, dynamic>{'id': a.id, 'nome': a.nome}).toList(),
      ),
    ));
  }
}