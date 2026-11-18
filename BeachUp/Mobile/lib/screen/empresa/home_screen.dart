import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screen/empresa/dashboard/faturamento_screen.dart';
import 'package:flutter_application_1/screen/empresa/arena/arenas_empresa_screen.dart';
import 'package:flutter_application_1/screen/empresa/campeonato/meus_campeonatos_screen.dart';
import 'package:flutter_application_1/screen/empresa/plano/planos_screen.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class HomeEmpresaScreen extends StatefulWidget {
  const HomeEmpresaScreen({super.key});

  @override
  State<HomeEmpresaScreen> createState() => _HomeEmpresaScreenState();
}

class _HomeEmpresaScreenState extends State<HomeEmpresaScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final telas = [
      const FaturamentoScreen(),
      const MinhasArenaScreen(),
      const MeusCampeonatosScreen(),
      const PlanosScreen(),
    ];

    return Scaffold(
      backgroundColor: appBg(context),
      body: IndexedStack(index: _tab, children: telas),
      bottomNavigationBar: _NavbarEmpresa(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _NavbarEmpresa extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _NavbarEmpresa({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(0, Icons.grid_view_rounded, Icons.grid_view_outlined, 'Métricas'),
              _item(1, Icons.location_on_rounded, Icons.location_on_outlined, 'Quadras'),
              _item(2, Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Torneios'),
              _item(3, Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Planos'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData ativo, IconData inativo, String label) {
    final sel = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? kLaranja.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sel ? ativo : inativo,
              color: sel ? kLaranja : kTextSec,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                color: sel ? kLaranja : kTextSec,
              ),
            ),
          ],
        ),
      ),
    );
  }
}