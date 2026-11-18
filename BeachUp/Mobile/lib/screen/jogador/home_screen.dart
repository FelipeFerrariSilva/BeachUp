import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screen/jogador/arena/arenas_screen.dart';
import 'package:flutter_application_1/screen/jogador/campeonato/Lista_Campeonatos_Screen.dart';
import 'package:flutter_application_1/screen/jogador/perfil/perfil_screen.dart';
import 'package:flutter_application_1/screen/jogador/reserva/minhas_reservas_screen.dart';
import 'package:flutter_application_1/screen/jogador/time/meus_times_screen.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class HomeJogadorScreen extends StatefulWidget {
  final int initialTab;
  const HomeJogadorScreen({super.key, this.initialTab = 0});

  @override
  State<HomeJogadorScreen> createState() => _HomeJogadorScreenState();
}

class _HomeJogadorScreenState extends State<HomeJogadorScreen> {
  late int _tab;

  final _telas = const [
    ArenasJogadorScreen(),       
    MinhasReservasScreen(),     
    MeusTimesScreen(),          
    ListaCampeonatosScreen(),    
    PerfilJogadorScreen(),      
  ];

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: kOffWhite,
      body: IndexedStack(index: _tab, children: _telas),
      bottomNavigationBar: Navbar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}