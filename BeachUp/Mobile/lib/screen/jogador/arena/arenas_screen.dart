import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/model/arena.dart';
import 'package:flutter_application_1/model/quadra.dart';
import 'package:flutter_application_1/service/arena_service.dart';
import 'package:flutter_application_1/service/quadra_service.dart';
import 'package:flutter_application_1/screen/jogador/arena/quadras_arena_screen.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class FiltroArena {
  String cobertura;     
  double distanciaMax;
  bool apenasProximas;

  FiltroArena({
    this.cobertura = 'Todas',
    this.distanciaMax = 50,
    this.apenasProximas = false,
  });

  bool get isDefault =>
      cobertura == 'Todas' && distanciaMax == 50 && !apenasProximas;
}

class ArenasJogadorScreen extends StatefulWidget {
  final bool standalone;
  const ArenasJogadorScreen({super.key, this.standalone = false});

  @override
  State<ArenasJogadorScreen> createState() => _ArenasJogadorScreenState();
}

class _ArenasJogadorScreenState extends State<ArenasJogadorScreen> {
  List<Arena> _todas = [];
  Map<int, List<Quadra>> _quadrasPorArena = {};
  List<Arena> _exibidas = [];

  bool _loading = true;
  String? _erro;
  final _buscaCtrl = TextEditingController();
  final _filtro = FiltroArena();

  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaCtrl.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _obterLocalizacao() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    } catch (_) {}
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      List<Arena> arenas;

      if (_filtro.apenasProximas && _userLat != null) {
        arenas = await ArenaService.buscarPorProximidade(
          latitude: _userLat!,
          longitude: _userLng!,
          raioKm: _filtro.distanciaMax,
        );
      } else {
        final futures = await Future.wait([
          ArenaService.getAll(),
          _obterLocalizacao().then((_) => null).catchError((_) => null),
        ]);
        arenas = futures[0] as List<Arena>;

        if (_userLat != null) {
          arenas.sort((a, b) {
            final da = _calcDist(a);
            final db = _calcDist(b);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });
        }
      }

      final Map<int, List<Quadra>> quadrasMap = {};
      await Future.wait(arenas.map((arena) async {
        try {
          quadrasMap[arena.id] = await QuadraService.getByArena(arena.id);
        } catch (_) {
          quadrasMap[arena.id] = [];
        }
      }));

      if (!mounted) return;
      setState(() {
        _todas = arenas;
        _quadrasPorArena = quadrasMap;
        _loading = false;
      });
      _aplicarFiltros();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar as arenas.';
        _loading = false;
      });
    }
  }

  double? _calcDist(Arena a) {
    if (a.distanciaKm != null) return a.distanciaKm;
    if (a.latitude == null || a.longitude == null || _userLat == null) return null;
    return Geolocator.distanceBetween(
          _userLat!, _userLng!, a.latitude!, a.longitude!) /
        1000;
  }

  void _aplicarFiltros() {
    final txt = _buscaCtrl.text.toLowerCase();
    setState(() {
      _exibidas = _todas.where((a) {
        if (txt.isNotEmpty &&
            !a.nome.toLowerCase().contains(txt) &&
            !a.localizacao.toLowerCase().contains(txt)) return false;

        final dist = _calcDist(a);
        if (dist != null && dist > _filtro.distanciaMax) return false;

        if (_filtro.cobertura != 'Todas') {
          final quadras = _quadrasPorArena[a.id] ?? [];
          final querCobertura = _filtro.cobertura == 'Com cobertura';
          final temQuadraCompativel =
              quadras.any((q) => q.temCobertura == querCobertura);
          if (!temQuadraCompativel) return false;
        }

        return true;
      }).toList();
    });
  }

  void _abrirFiltro() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PainelFiltro(
        filtro: _filtro,
        onAplicar: () {
          Navigator.pop(context);
          _carregar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBg(context),
      appBar: CustomAppBarPerfil(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Arenas',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: appTextPri(context),
                          letterSpacing: -0.5)),
                  if (_exibidas.isNotEmpty && !_loading)
                    Text('${_exibidas.length} disponíveis',
                        style: const TextStyle(fontSize: 14, color: kTextSec)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: appCard(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8, offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _buscaCtrl,
                        style: TextStyle(fontSize: 14, color: appTextPri(context)),
                        decoration: InputDecoration(
                          hintText: 'Buscar arena, bairro...',
                          hintStyle: TextStyle(color: appTextSec(context), fontSize: 14),
                          prefixIcon:
                              Icon(Icons.search_rounded, color: appTextSec(context), size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _abrirFiltro,
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: _filtro.isDefault ? appCard(context) : kLaranja,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _filtro.isDefault ? kBorder : kLaranja),
                          ),
                          child: Icon(Icons.tune_rounded,
                              color: _filtro.isDefault ? appTextPri(context) : Colors.white,
                              size: 20),
                        ),
                      ),
                      if (!_filtro.isDefault)
                        Positioned(
                          top: 6, right: 6,
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  _chip('Todas', !_filtro.apenasProximas, () {
                    setState(() => _filtro.apenasProximas = false);
                    _carregar();
                  }),
                  const SizedBox(width: 8),
                  _chip('Próximas', _filtro.apenasProximas, () async {
                    if (_userLat == null) {
                      await _obterLocalizacao();
                      if (_userLat == null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ative a localização para usar este filtro'),
                            backgroundColor: kLaranja,
                          ),
                        );
                        return;
                      }
                    }
                    setState(() => _filtro.apenasProximas = true);
                    _carregar();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 4),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool ativo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? kLaranja : appCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ativo ? kLaranja : appBorder(context)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: ativo ? FontWeight.w600 : FontWeight.w400,
                color: ativo ? Colors.white : appTextSec(context))),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kLaranja));
    }
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: kTextSec, size: 48),
            const SizedBox(height: 12),
            Text(_erro!, style: TextStyle(color: appTextSec(context), fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kLaranja,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: _carregar,
              child: const Text('Tentar novamente',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      );
    }
    if (_exibidas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stadium_outlined, color: kTextSec, size: 48),
            const SizedBox(height: 12),
            Text('Nenhuma arena encontrada.',
                style: TextStyle(color: appTextSec(context), fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: kLaranja,
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _exibidas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final arena = _exibidas[i];
          final dist = _calcDist(arena);
          return _CardArena(
            arena: arena,
            distanciaKm: dist,
          );
        },
      ),
    );
  }
}

class _PainelFiltro extends StatefulWidget {
  final FiltroArena filtro;
  final VoidCallback onAplicar;
  const _PainelFiltro({required this.filtro, required this.onAplicar});

  @override
  State<_PainelFiltro> createState() => _PainelFiltroState();
}

class _PainelFiltroState extends State<_PainelFiltro> {
  late String _cobertura;
  late double _distancia;
  late bool _proximas;

  @override
  void initState() {
    super.initState();
    _cobertura = widget.filtro.cobertura;
    _distancia = widget.filtro.distanciaMax;
    _proximas  = widget.filtro.apenasProximas;
  }

  void _aplicar() {
    widget.filtro.cobertura      = _cobertura;
    widget.filtro.distanciaMax   = _distancia;
    widget.filtro.apenasProximas = _proximas;
    widget.onAplicar();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filtros',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: appTextPri(context))),
              TextButton(
                onPressed: () => setState(() {
                  _cobertura = 'Todas';
                  _distancia = 50;
                  _proximas  = false;
                }),
                child: const Text('Limpar',
                    style: TextStyle(color: kLaranja, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('COBERTURA',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kTextSec,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['Todas', 'Com cobertura', 'Sem cobertura']
                .map((o) => _opcaoChip(
                    o, _cobertura == o, () => setState(() => _cobertura = o)))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DISTÂNCIA MÁXIMA',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kTextSec,
                      letterSpacing: 0.8)),
              Text('${_distancia.toInt()} km',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kLaranja)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kLaranja,
              thumbColor: kLaranja,
              overlayColor: kLaranja.withValues(alpha: 0.15),
              inactiveTrackColor: kBorder,
            ),
            child: Slider(
              value: _distancia,
              min: 1, max: 100, divisions: 20,
              onChanged: (v) => setState(() => _distancia = v),
            ),
          ),
          const SizedBox(height: 16),
          const Text('LOCALIZAÇÃO',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kTextSec,
                  letterSpacing: 0.8)),
          const SizedBox(height: 10),
          _opcaoChip('Arenas próximas', _proximas,
              () => setState(() => _proximas = !_proximas)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kLaranja,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _aplicar,
              child: const Text('Aplicar filtros',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opcaoChip(String label, bool ativo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: ativo ? kLaranja : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ativo ? kLaranja : kBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ativo) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ativo ? Colors.white : kTextPri)),
          ],
        ),
      ),
    );
  }
}

class ArenaFotoWidget extends StatelessWidget {
  final String? fotoUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ArenaFotoWidget({
    super.key,
    required this.fotoUrl,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(12);
    final url = _abs(fotoUrl);
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: br,
        child: Image.network(
          url,
          width: width, height: height,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, p) =>
              p == null ? child : _placeholder(br),
          errorBuilder: (_, __, ___) => _placeholder(br),
        ),
      );
    }
    return _placeholder(br);
  }

  static String _abs(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.baseUrl}$url';
  }

  Widget _placeholder(BorderRadius br) => ClipRRect(
        borderRadius: br,
        child: Container(
          width: width, height: height,
          color: const Color(0xFFF0EDE8),
          child: const Icon(Icons.stadium_outlined, color: kLaranja, size: 28),
        ),
      );
}

class _CardArena extends StatelessWidget {
  final Arena arena;
  final double? distanciaKm;
  const _CardArena({required this.arena, this.distanciaKm});

  @override
  Widget build(BuildContext context) {
    final end = arena.endereco;
    String enderecoCompleto = '';
    if (end != null) {
      final partes = [
        if (end.logradouro != null && end.logradouro!.isNotEmpty) end.logradouro!,
        if (end.numero != null && end.numero!.isNotEmpty) end.numero!,
        if (end.bairro != null && end.bairro!.isNotEmpty) end.bairro!,
      ];
      enderecoCompleto = partes.join(', ');
    }
    final cidadeEstado = arena.localizacao; 

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => QuadrasArenaJogadorScreen(arena: arena)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: appCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: ArenaFotoWidget(
                fotoUrl: arena.fotoUrl,
                width: 96, height: 96,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(arena.nome,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: appTextPri(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),

                    const SizedBox(height: 3),

                    if (enderecoCompleto.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: kTextSec),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            enderecoCompleto,
                            style: const TextStyle(
                                fontSize: 12, color: kTextSec),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),

                    if (cidadeEstado.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          const Icon(Icons.map_outlined,
                              size: 12, color: kTextSec),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              distanciaKm != null
                                  ? '$cidadeEstado · ${distanciaKm!.toStringAsFixed(1)} km'
                                  : cidadeEstado,
                              style: const TextStyle(
                                  fontSize: 12, color: kTextSec),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ),

                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: kLaranja.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Ver quadras',
                          style: TextStyle(
                              color: kLaranja,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}