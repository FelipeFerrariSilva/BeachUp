import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/campeonato_service.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class CriarCampeonatoScreen extends StatefulWidget {
  final String accessToken;
  final List<Map<String, dynamic>> arenas;

  const CriarCampeonatoScreen({
    super.key,
    required this.accessToken,
    required this.arenas,
  });

  @override
  State<CriarCampeonatoScreen> createState() => _CriarCampeonatoScreenState();
}

class _CriarCampeonatoScreenState extends State<CriarCampeonatoScreen> {
  final _nomeController      = TextEditingController();
  final _descricaoController = TextEditingController();
  final _regrasController    = TextEditingController();

  String? _categoriaSelecionada;
  Map<String, dynamic>? _arenaSelecionada;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _nomeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _regrasController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData({required bool isInicio}) async {
    final inicial = isInicio
        ? DateTime.now()
        : (_dataInicio ?? DateTime.now()).add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: kLaranja),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
          if (_dataFim != null && _dataFim!.isBefore(picked)) _dataFim = null;
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  Future<void> _criarCampeonato() async {
    if (_nomeController.text.trim().isEmpty) {
      _mostrarErro('Digite o nome do campeonato'); return;
    }
    if (_arenaSelecionada == null) {
      _mostrarErro('Selecione uma arena'); return;
    }
    if (_dataInicio == null) {
      _mostrarErro('Selecione a data de início'); return;
    }

    setState(() => _carregando = true);

    final resultado = await CampeonatoService.criar(
      nome: _nomeController.text.trim(),
      descricao: _descricaoController.text.trim(),
      categoria: _categoriaSelecionada ?? '',
      dataInicio: _formatarParaApi(_dataInicio!),
      dataFim: _dataFim != null
          ? _formatarParaApi(_dataFim!)
          : _formatarParaApi(_dataInicio!),
      arenaId: _arenaSelecionada!['id'] as int,
      token: widget.accessToken,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (resultado['sucesso'] == true) {
      _mostrarSucesso(resultado['dados']);
    } else {
      _mostrarErro(resultado['erro'] ?? 'Erro ao criar campeonato');
    }
  }

  String _formatarParaApi(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatarExibicao(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _mostrarSucesso(Map<String, dynamic> dados) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kLaranja.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.emoji_events_rounded, color: kLaranja, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Campeonato criado!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextPri)),
            const SizedBox(height: 8),
            const Text(
              'Compartilhe o token abaixo com os times para que possam se inscrever.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSec, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kOffWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(children: [
                const Text('Token de inscrição',
                    style: TextStyle(color: kTextSec, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  dados['tokenInscricao'] ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: kTextPri),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kLaranja,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Concluir',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: Stack(
              children: [
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/imagem.campeonato.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.65)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 28, left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('CRIAR',
                          style: TextStyle(color: Colors.white70, fontSize: 16,
                              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      Text('CAMPEONATO',
                          style: TextStyle(color: Colors.white, fontSize: 28,
                              fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                      SizedBox(height: 4),
                      Text('Organize sua competição e gerencie as inscrições.',
                          style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _previewCard(),
                  const SizedBox(height: 20),

                  _label('Nome do Campeonato *'),
                  const SizedBox(height: 8),
                  _campo(controller: _nomeController, hint: 'Ex: Copa BeachUp 2026',
                      icone: Icons.emoji_events_outlined, maxLength: 50),
                  const SizedBox(height: 14),

                  _label('Descrição'),
                  const SizedBox(height: 8),
                  _campo(controller: _descricaoController,
                      hint: 'Descreva o campeonato...', icone: Icons.description_outlined,
                      maxLines: 3, maxLength: 60),
                  const SizedBox(height: 14),

                  _label('Categoria'),
                  const SizedBox(height: 8),
                  _seletorCategoria(),
                  const SizedBox(height: 14),

                  _label('Arena *'),
                  const SizedBox(height: 8),
                  _dropdownArenas(),
                  const SizedBox(height: 14),

                  _label('Data de início *'),
                  const SizedBox(height: 8),
                  _seletorData(
                    data: _dataInicio,
                    hint: 'Selecione a data de início',
                    onTap: () => _selecionarData(isInicio: true),
                  ),
                  const SizedBox(height: 14),

                  _label('Data de fim'),
                  const SizedBox(height: 8),
                  _seletorData(
                    data: _dataFim,
                    hint: 'Selecione a data de fim',
                    onTap: _dataInicio == null ? null : () => _selecionarData(isInicio: false),
                  ),
                  const SizedBox(height: 14),

                  _label('Formato'),
                  const SizedBox(height: 8),
                  _formatoCard(),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _carregando ? null : _criarCampeonato,
                      icon: _carregando
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Icon(Icons.emoji_events_rounded, color: Colors.white),
                      label: Text(
                        _carregando ? 'Criando...' : 'Criar Campeonato',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLaranja,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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


  Widget _previewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF9240)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _categoriaSelecionada ?? 'Eliminatória',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _nomeController.text.isEmpty ? 'Nome do campeonato' : _nomeController.text,
            style: TextStyle(
              color: _nomeController.text.isEmpty
                  ? Colors.white60 : Colors.white,
              fontSize: 18, fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _arenaSelecionada != null
                ? _arenaSelecionada!['nome'] : 'Nenhuma arena selecionada',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (_dataInicio != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _dataFim != null
                    ? '${_formatarExibicao(_dataInicio!)} → ${_formatarExibicao(_dataFim!)}'
                    : _formatarExibicao(_dataInicio!),
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dropdownArenas() {
    if (widget.arenas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kOffWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: const Text('Nenhuma arena cadastrada',
            style: TextStyle(color: kTextSec)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _arenaSelecionada,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kTextSec),
          hint: const Text('Selecione uma arena', style: TextStyle(color: kTextSec)),
          items: widget.arenas
              .map((arena) => DropdownMenuItem(
                    value: arena,
                    child: Text(arena['nome'],
                        style: const TextStyle(color: kTextPri)),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _arenaSelecionada = value),
        ),
      ),
    );
  }

  Widget _seletorData({
    required DateTime? data,
    required String hint,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: disabled ? kBorder.withValues(alpha: 0.4) : kOffWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          Icon(Icons.calendar_month_rounded,
              color: data != null ? kLaranja : kTextSec, size: 20),
          const SizedBox(width: 12),
          Text(
            data != null ? _formatarExibicao(data) : hint,
            style: TextStyle(
              color: data != null ? kTextPri : kTextSec,
              fontSize: 14,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _formatoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: kLaranja.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.account_tree_rounded, color: kLaranja, size: 20),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Eliminatória simples',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPri)),
            Text('8 ou 16 times · Formato padrão BeachUp',
                style: TextStyle(fontSize: 12, color: kTextSec)),
          ],
        ),
      ]),
    );
  }

  Widget _seletorCategoria() {
    const categorias = ['Masculino', 'Feminino', 'Misto'];
    return Row(
      children: categorias.map((cat) {
        final sel = _categoriaSelecionada == cat;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: cat != categorias.last ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _categoriaSelecionada = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: sel ? kLaranja : kOffWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? kLaranja : kBorder),
                ),
                child: Text(
                  cat,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : kTextSec,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: kTextSec));
  }

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 14, color: kTextPri),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kTextSec, fontSize: 14),
        counterText: '',
        prefixIcon: maxLines > 1
            ? Align(
                widthFactor: 1.0,
                heightFactor: 1.0,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Icon(icone, color: kTextSec),
                ),
              )
            : Icon(icone, color: kTextSec),
        prefixIconConstraints: maxLines > 1
            ? const BoxConstraints(minWidth: 48, minHeight: 48)
            : null,
        filled: true,
        fillColor: kOffWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kLaranja, width: 1.5),
        ),
      ),
    );
  }
}