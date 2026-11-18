import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/model/arena.dart';
import 'package:flutter_application_1/service/arena_service.dart';
import 'package:flutter_application_1/service/horario_service.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';

class CriarArenaScreen extends StatefulWidget {
  final Arena? arenaParaEditar;
  const CriarArenaScreen({super.key, this.arenaParaEditar});

  @override
  State<CriarArenaScreen> createState() => _CriarArenaScreenState();
}

class _CriarArenaScreenState extends State<CriarArenaScreen> {
  static const _laranja = kLaranja;
  static const _bg = kOffWhite;

  final _nomeCtrl       = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl     = TextEditingController();
  final _bairroCtrl     = TextEditingController();
  final _cidadeCtrl     = TextEditingController();
  final _estadoCtrl     = TextEditingController();
  final _cepCtrl        = TextEditingController();

  XFile?    _fotoSelecionada;
  Uint8List? _fotoBytes;
  bool _loading     = false;
  bool _buscandoCep = false;
  String? _ultimoCep;

  final Map<String, _HorarioLocal> _horarios = {};

  List<HorarioFuncionamento> _horariosSalvos = [];
  bool _carregandoHorarios = false;

  bool get _editando => widget.arenaParaEditar != null;

  @override
  void initState() {
    super.initState();
    _cepCtrl.addListener(_aoMudarCep);
    if (_editando) {
      final a = widget.arenaParaEditar!;
      _nomeCtrl.text = a.nome;
      _descCtrl.text = a.descricao ?? '';
      final e = a.endereco;
      if (e != null) {
        _logradouroCtrl.text = e.logradouro ?? '';
        _numeroCtrl.text     = e.numero ?? '';
        _bairroCtrl.text     = e.bairro ?? '';
        _cidadeCtrl.text     = e.cidade ?? '';
        _estadoCtrl.text     = e.estado ?? '';
        _cepCtrl.text        = e.cep ?? '';
        _ultimoCep           = e.cep?.replaceAll(RegExp(r'[^0-9]'), '');
      }
      _carregarHorariosExistentes();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nomeCtrl, _descCtrl, _logradouroCtrl, _numeroCtrl,
      _bairroCtrl, _cidadeCtrl, _estadoCtrl, _cepCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }


  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _fotoSelecionada = picked;
        _fotoBytes = bytes;
      });
    }
  }

  void _aoMudarCep() {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length == 8 && cep != _ultimoCep) {
      _ultimoCep = cep;
      _buscarCep(cep);
    }
  }

  Future<void> _buscarCep(String cep) async {
    setState(() => _buscandoCep = true);
    try {
      final res =
          await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['erro'] == true) {
          _snack('CEP não encontrado', erro: true);
        } else {
          setState(() {
            _logradouroCtrl.text = data['logradouro'] ?? '';
            _bairroCtrl.text     = data['bairro'] ?? '';
            _cidadeCtrl.text     = data['localidade'] ?? '';
            _estadoCtrl.text     = data['uf'] ?? '';
          });
        }
      }
    } catch (_) {
      _snack('Sem conexão para buscar o CEP', erro: true);
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }


  Future<void> _carregarHorariosExistentes() async {
    setState(() => _carregandoHorarios = true);
    try {
      final lista = await HorarioService.listar(widget.arenaParaEditar!.id);
      setState(() {
        _horariosSalvos = lista;
        for (final h in lista) {
          _horarios[h.diaSemana] = _HorarioLocal(
            ativo: true,
            abertura: h.horaAbertura,
            fechamento: h.horaFechamento,
            jaSalvo: true,
          );
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _carregandoHorarios = false);
    }
  }

  Future<void> _abrirSeletorHorario(
      String dia, bool isAbertura) async {
    final atual = _horarios[dia];
    TimeOfDay inicial = TimeOfDay(hour: 8, minute: 0);
    if (atual != null) {
      final txt = isAbertura ? atual.abertura : atual.fechamento;
      if (txt.length == 5) {
        final parts = txt.split(':');
        inicial = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 8,
            minute: int.tryParse(parts[1]) ?? 0);
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: inicial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _laranja),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    final hStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    setState(() {
      final h = _horarios[dia] ?? _HorarioLocal();
      _horarios[dia] = _HorarioLocal(
        ativo: h.ativo,
        abertura: isAbertura ? hStr : h.abertura,
        fechamento: isAbertura ? h.fechamento : hStr,
        jaSalvo: h.jaSalvo,
      );
    });
  }

  void _toggleDia(String dia, bool ativo) {
    setState(() {
      final h = _horarios[dia] ?? _HorarioLocal();
      _horarios[dia] = _HorarioLocal(
        ativo: ativo,
        abertura: h.abertura.isEmpty ? '08:00' : h.abertura,
        fechamento: h.fechamento.isEmpty ? '22:00' : h.fechamento,
        jaSalvo: h.jaSalvo,
      );
    });
  }


  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      _snack('Informe o nome da arena', erro: true);
      return;
    }
    if (_logradouroCtrl.text.trim().isEmpty ||
        _cidadeCtrl.text.trim().isEmpty ||
        _estadoCtrl.text.trim().isEmpty ||
        _cepCtrl.text.trim().isEmpty) {
      _snack('Preencha o endereço completo', erro: true);
      return;
    }

    setState(() => _loading = true);
    try {
      Arena arena;
      if (_editando) {
        arena = await ArenaService.editar(
          id: widget.arenaParaEditar!.id,
          nome: _nomeCtrl.text.trim(),
          descricao: _descCtrl.text.trim(),
          logradouro: _logradouroCtrl.text.trim(),
          numero: _numeroCtrl.text.trim(),
          bairro: _bairroCtrl.text.trim(),
          cidade: _cidadeCtrl.text.trim(),
          estado: _estadoCtrl.text.trim(),
          cep: _cepCtrl.text.trim(),
          foto: _fotoSelecionada,
        );
      } else {
        arena = await ArenaService.criar(
          nome: _nomeCtrl.text.trim(),
          descricao: _descCtrl.text.trim(),
          logradouro: _logradouroCtrl.text.trim(),
          numero: _numeroCtrl.text.trim(),
          bairro: _bairroCtrl.text.trim(),
          cidade: _cidadeCtrl.text.trim(),
          estado: _estadoCtrl.text.trim(),
          cep: _cepCtrl.text.trim(),
          foto: _fotoSelecionada,
        );
      }

      // Sincroniza horários com o backend
      await _sincronizarHorarios(arena.id);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), erro: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sincronizarHorarios(int arenaId) async {
    // Remove dias que estavam salvos mas foram desativados
    for (final salvo in _horariosSalvos) {
      final local = _horarios[salvo.diaSemana];
      if (local == null || !local.ativo) {
        try {
          await HorarioService.remover(arenaId, salvo.diaSemana);
        } catch (_) {}
      }
    }

    // Salva / atualiza os dias ativos
    for (final entry in _horarios.entries) {
      if (!entry.value.ativo) continue;
      if (entry.value.abertura.isEmpty || entry.value.fechamento.isEmpty) {
        continue;
      }
      try {
        await HorarioService.salvar(
          arenaId,
          HorarioFuncionamento(
            diaSemana: entry.key,
            diaSemanaLabel: '',
            horaAbertura: entry.value.abertura,
            horaFechamento: entry.value.fechamento,
          ),
        );
      } catch (_) {}
    }
  }

  void _snack(String msg, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: erro ? Colors.red[700] : _laranja,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: kOffWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextPri),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPri, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _editando ? 'Editar Arena' : 'Nova Arena',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kTextPri)),
        actions: [const ProfileAction(), const SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _titulo('Foto da arena'),
            GestureDetector(
              onTap: _selecionarFoto,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _fotoSelecionada != null ? _laranja : Colors.black12,
                    width: _fotoSelecionada != null ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _fotoSelecionada != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_fotoBytes!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: kTextSec,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Trocar',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: Colors.black26, size: 48),
                          const SizedBox(height: 10),
                          const Text('Toque para adicionar uma foto',
                              style: TextStyle(
                                  color: kTextSec, fontSize: 13)),
                          if (_editando &&
                              widget.arenaParaEditar!.fotoUrl != null) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Foto atual será mantida se não selecionar nova',
                              style: TextStyle(
                                  color: Colors.black26, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            _titulo('Informações básicas'),
            _campo(_nomeCtrl, 'Nome da arena', Icons.stadium_outlined),
            const SizedBox(height: 12),
            _campo(_descCtrl, 'Descrição (opcional)',
                Icons.description_outlined,
                maxLines: 3),
            const SizedBox(height: 24),

            _titulo('Endereço'),
            Text(
              'Usado para calcular distância e ordenar nos resultados.',
              style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.45), fontSize: 12),
            ),
            const SizedBox(height: 12),
            _campo(
              _cepCtrl,
              'CEP',
              Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
              suffix: _buscandoCep
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _laranja),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  flex: 3,
                  child: _campo(
                      _logradouroCtrl, 'Logradouro', Icons.route_outlined)),
              const SizedBox(width: 10),
              Expanded(
                  flex: 1, child: _campo(_numeroCtrl, 'Nº', Icons.tag)),
            ]),
            const SizedBox(height: 12),
            _campo(_bairroCtrl, 'Bairro', Icons.location_city_outlined),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  flex: 3,
                  child: _campo(
                      _cidadeCtrl, 'Cidade', Icons.location_on_outlined)),
              const SizedBox(width: 10),
              Expanded(
                  flex: 1,
                  child: _campo(_estadoCtrl, 'UF', Icons.map_outlined)),
            ]),
            const SizedBox(height: 28),

            _titulo('Horários de funcionamento'),
            Text(
              'Defina os dias e horários em que sua arena estará aberta.',
              style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.45), fontSize: 12),
            ),
            const SizedBox(height: 12),

            if (_carregandoHorarios)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                    child: CircularProgressIndicator(color: _laranja)),
              )
            else
              ...diasDaSemana.map((dia) {
                final valor = dia['valor']!;
                final label = dia['label']!;
                final h = _horarios[valor];
                final ativo = h?.ativo ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ativo ? _laranja : Colors.black12,
                      width: ativo ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Linha do dia + toggle
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _toggleDia(valor, !ativo),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: ativo ? _laranja : Colors.black38,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: ativo
                                        ? kTextPri
                                        : Colors.black45,
                                  ),
                                ),
                              ),
                              Switch(
                                value: ativo,
                                onChanged: (v) => _toggleDia(valor, v),
                                activeColor: _laranja,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (ativo) ...[
                        Divider(
                            height: 1,
                            color: _laranja.withValues(alpha: 0.2)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: _botaoHorario(
                                  label: 'Abertura',
                                  hora: h?.abertura.isEmpty ?? true
                                      ? '08:00'
                                      : h!.abertura,
                                  onTap: () =>
                                      _abrirSeletorHorario(valor, true),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('até',
                                    style: TextStyle(
                                        color: kTextSec, fontSize: 13)),
                              ),
                              Expanded(
                                child: _botaoHorario(
                                  label: 'Fechamento',
                                  hora: h?.fechamento.isEmpty ?? true
                                      ? '22:00'
                                      : h!.fechamento,
                                  onTap: () =>
                                      _abrirSeletorHorario(valor, false),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _laranja,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _salvar,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _editando ? 'Salvar alterações' : 'Criar arena',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }


  Widget _titulo(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(label,
            style: const TextStyle(
                color: kTextPri,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      );

  Widget _campo(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: kTextPri),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.3)),
        prefixIcon: Icon(icon, color: _laranja, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _laranja, width: 1.5)),
      ),
    );
  }

  Widget _botaoHorario({
    required String label,
    required String hora,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kOffWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _laranja.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: kTextSec,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: _laranja),
                const SizedBox(width: 4),
                Text(hora,
                    style: const TextStyle(
                        color: kTextPri,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HorarioLocal {
  final bool ativo;
  final String abertura;
  final String fechamento;
  final bool jaSalvo;

  const _HorarioLocal({
    this.ativo = false,
    this.abertura = '',
    this.fechamento = '',
    this.jaSalvo = false,
  });
}