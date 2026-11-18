import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/model/quadra.dart';
import 'package:flutter_application_1/service/quadra_service.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';

class CadastroQuadraScreen extends StatefulWidget {
  final int arenaId;
  final Quadra? quadraParaEditar;

  const CadastroQuadraScreen({
    super.key,
    required this.arenaId,
    this.quadraParaEditar,
  });

  @override
  State<CadastroQuadraScreen> createState() => _CadastroQuadraScreenState();
}

class _CadastroQuadraScreenState extends State<CadastroQuadraScreen> {
  static const _laranja = kLaranja;
  static const _bg = kOffWhite;
  static const _cardBg = Colors.white;
  static const _inputBg = Color(0xFFF0F0EE);
  static const _border = Color(0xFFE0E0DE);
  static const _textPri = kTextPri;
  static const _textSec = kTextSec;
  static const _textMut = Color(0xFFBBBBBB);

  final _nomeCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  String _tipoCobertura = 'DESCOBERTA';
  final List<XFile> _novasFotos = [];
  final List<Uint8List> _novasFotosBytes = [];
  bool _loading = false;

  bool get _editando => widget.quadraParaEditar != null;

  List<String> get _fotosExistentes =>
      _editando ? (widget.quadraParaEditar!.fotos) : [];

  @override
  void initState() {
    super.initState();
    if (_editando) {
      final q = widget.quadraParaEditar!;
      _nomeCtrl.text = q.nome;
      _valorCtrl.text = q.valorHora.toStringAsFixed(2);
      _tipoCobertura = q.tipoCobertura ?? 'DESCOBERTA';
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _adicionarFotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85, limit: 5);
    if (picked.isNotEmpty) {
      final bytes = await Future.wait(picked.map((x) => x.readAsBytes()));
      setState(() {
        _novasFotos.addAll(picked);
        _novasFotosBytes.addAll(bytes);
      });
    }
  }

  void _removerNovaFoto(int index) {
    setState(() {
      _novasFotos.removeAt(index);
      _novasFotosBytes.removeAt(index);
    });
  }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) {
      _snack('Informe o nome da quadra', erro: true);
      return;
    }

    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.').trim());
    if (valor == null || valor <= 0) {
      _snack('Informe um valor/hora válido', erro: true);
      return;
    }

    setState(() => _loading = true);
    try {
      Quadra quadra;
      if (_editando) {
        quadra = await QuadraService.editar(
          id: widget.quadraParaEditar!.id,
          nome: nome,
          tipoCobertura: _tipoCobertura,
          valorHora: valor,
        );
      } else {
        quadra = await QuadraService.criar(
          arenaId: widget.arenaId,
          nome: nome,
          tipoCobertura: _tipoCobertura,
          valorHora: valor,
        );
      }

      if (_novasFotos.isNotEmpty) {
        await QuadraService.adicionarFotos(
          quadraId: quadra.id,
          fotos: _novasFotos,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), erro: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: erro ? Colors.red[700] : _laranja,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
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
        title: Text(_editando ? 'Editar Quadra' : 'Cadastrar Quadra',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kTextPri)),
        actions: [const ProfileAction(), const SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              'Informações básicas',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Nome da quadra'),
                  _campo('Ex: Quadra Central', _nomeCtrl),
                  const SizedBox(height: 16),
                  _label('Valor por hora'),
                  _campo(
                    '0,00',
                    _valorCtrl,
                    teclado: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefix: 'R\$ ',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _card(
              'Tipo de cobertura',
              Row(
                children: [
                  _opcaoCobertura(
                    'DESCOBERTA',
                    'Sem cobertura',
                    Icons.wb_sunny_outlined,
                  ),
                  const SizedBox(width: 8),
                  _opcaoCobertura(
                    'COBERTA',
                    'Com cobertura',
                    Icons.roofing_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _card(
              'Fotos da quadra',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_fotosExistentes.isNotEmpty) ...[
                    const Text(
                      'Fotos atuais',
                      style: TextStyle(fontSize: 12, color: _textSec),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _fotosExistentes.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _fotosExistentes[i],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 80,
                              height: 80,
                              color: _inputBg,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: _textMut,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (_novasFotos.isNotEmpty) ...[
                    const Text(
                      'Novas fotos',
                      style: TextStyle(fontSize: 12, color: _textSec),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _novasFotos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _novasFotosBytes[i],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removerNovaFoto(i),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  GestureDetector(
                    onTap: _adicionarFotos,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _novasFotos.isNotEmpty ? _laranja : _border,
                          width: _novasFotos.isNotEmpty ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: _novasFotos.isNotEmpty ? _laranja : _textSec,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _novasFotos.isEmpty
                                ? 'Adicionar fotos da galeria'
                                : 'Adicionar mais fotos',
                            style: TextStyle(
                              color: _novasFotos.isNotEmpty
                                  ? _laranja
                                  : _textSec,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!_editando)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _laranja.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _laranja.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: _laranja, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Após o cadastro, sua quadra entrará em revisão (até 24h) antes de ser publicada.',
                        style: TextStyle(
                          color: _textSec,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSec,
                      side: const BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOffWhite,
                      foregroundColor: kTextPri,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _editando ? 'Salvar alterações' : 'Criar quadra',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _textSec,
      ),
    ),
  );

  Widget _campo(
    String hint,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType? teclado,
    String? prefix,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: teclado,
      style: const TextStyle(color: _textPri, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        prefixStyle: const TextStyle(color: _textPri, fontSize: 14),
        hintStyle: const TextStyle(color: _textMut, fontSize: 14),
        filled: true,
        fillColor: _inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _laranja, width: 1.5),
        ),
      ),
    );
  }

  Widget _card(String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border, width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textPri,
          ),
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );

  Widget _opcaoCobertura(String valor, String label, IconData icon) {
    final sel = _tipoCobertura == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipoCobertura = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? _laranja : _inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? _laranja : _border),
          ),
          child: Column(
            children: [
              Icon(icon, color: sel ? Colors.white : _textSec, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: sel ? Colors.white : _textSec,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}