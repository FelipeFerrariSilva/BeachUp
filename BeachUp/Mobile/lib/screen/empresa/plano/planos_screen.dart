import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/assinatura.dart';
import 'package:flutter_application_1/service/pagamento_service.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

class PlanosScreen extends StatefulWidget {
  const PlanosScreen({super.key});

  @override
  State<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends State<PlanosScreen> {
  Assinatura? _assinatura;
  bool _loadingAssinatura = true;
  String? _loadingUpgrade;

  static const Map<String, int> _ordemPlano = {
    'GRATUITO': 0,
    'BASICO': 1,
    'GOLD': 2,
  };

  @override
  void initState() { super.initState(); _carregarAssinatura(); }

  Future<void> _carregarAssinatura() async {
    try {
      final assinatura = await PagamentoService.minhaAssinatura();
      if (!mounted) return;
      setState(() => _assinatura = assinatura);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingAssinatura = false);
    }
  }

  Future<void> _assinar(String tipo) async {
    setState(() => _loadingUpgrade = tipo);
    try {
      final checkout = await PagamentoService.assinarPlano(tipo);
      if (!mounted) return;
      await launchUrl(
        Uri.parse(checkout.initPoint),
        customTabsOptions: const CustomTabsOptions(shareState: CustomTabsShareState.on, urlBarHidingEnabled: true, showTitle: true),
        safariVCOptions: const SafariViewControllerOptions(barCollapsingEnabled: true),
      );
      if (!mounted) return;
      _carregarAssinatura();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red[700], content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loadingUpgrade = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAssinatura) return const Center(child: CircularProgressIndicator(color: kLaranja));
    final tipoAtual = _assinatura?.tipoPlano;
    final idxAtual = _ordemPlano[tipoAtual] ?? 0;
    final temGold = tipoAtual == 'GOLD';

    return Scaffold(
      backgroundColor: appBg(context),
      appBar: CustomAppBarPerfil(),
      body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Planos',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kTextPri, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Escolha o plano ideal para sua arena.',
                      style: TextStyle(fontSize: 14, color: kTextSec)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                _planoCard(
                  nome: 'GRATUITO',
                  preco: 'R\$ 0',
                  periodo: '/mês',
                  isAtual: tipoAtual == 'GRATUITO',
                  bloqueado: idxAtual > _ordemPlano['GRATUITO']!,
                  temGold: temGold,
                  loading: false,
                  beneficios: const ['1 arena', '2 quadras', 'Reservas básicas', 'Suporte por e-mail'],
                  onPressed: null,
                  destaque: false,
                  labelBotao: 'Continuar grátis',
                  corFundo: kCard,
                  corBotao: kTextPri,
                ),
                const SizedBox(height: 20),
                _planoCard(
                  nome: 'BASICO',
                  preco: 'R\$ 199,90',
                  periodo: '/mês',
                  isAtual: tipoAtual == 'BASICO',
                  bloqueado: idxAtual > _ordemPlano['BASICO']!,
                  temGold: temGold,
                  loading: _loadingUpgrade == 'BASICO',
                  beneficios: const ['Até 3 arenas', 'Quadras ilimitadas', 'Campeonatos ilimitados', 'Métricas avançadas', 'Suporte prioritário'],
                  onPressed: () => _assinar('BASICO'),
                  destaque: true,
                  labelBotao: 'Assinar agora',
                  gradiente: const LinearGradient(
                    colors: [Color(0xFFFAFAFA), Color(0xFFC0C0C0), Color(0xFF8E8E8E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  corBotao: const Color(0xFF2B2B2B),
                  corCheck: const Color(0xFF2B2B2B),
                ),
                const SizedBox(height: 20),
                _planoCard(
                  nome: 'GOLD',
                  preco: 'R\$ 399,90',
                  periodo: '/mês',
                  isAtual: tipoAtual == 'GOLD',
                  bloqueado: false, 
                  temGold: temGold,
                  loading: _loadingUpgrade == 'GOLD',
                  beneficios: const ['Arenas ilimitadas', 'Marca personalizada', 'API de integração', 'Gerente dedicado'],
                  onPressed: () => _assinar('GOLD'),
                  destaque: false,
                  labelBotao: 'Assinar agora',
                  imagemFundo: 'assets/images/planogold.png',
                  overlayEscuro: false,
                  corBorda: const Color(0xFFFFE066),
                  corBotao: Colors.black,
                  corTextoBotao: const Color(0xFFFFD700),
                  corCheck: kLaranja,
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kLaranja.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kLaranja.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: appCard(context), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.shield_outlined, color: kLaranja, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Sem fidelidade', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kTextPri)),
                        Text('Cancele quando quiser. Sem taxas e sem burocracia.', style: TextStyle(fontSize: 12, color: kTextSec)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock_outline_rounded, color: kTextSec, size: 16),
                  const SizedBox(width: 6),
                  const Text('Pagamento 100% seguro via Mercado Pago', style: TextStyle(fontSize: 12, color: kTextSec)),
                ]),
                const SizedBox(height: 20),
              ]),
            ),
          ],
        ),
      ),
    ),
    );
  }


  Widget _planoCard({
    required String nome,
    required String preco,
    required String periodo,
    required bool isAtual,
    required bool bloqueado,
    required bool temGold,
    required bool loading,
    required List<String> beneficios,
    required VoidCallback? onPressed,
    required bool destaque,
    required String labelBotao,
    Color? corFundo,
    Gradient? gradiente,
    String? imagemFundo,
    bool overlayEscuro = false,
    bool textoClaro = false, 
    Color? corBorda,
    Color? corBotao,
    Color? corTextoBotao,
    Color? corCheck,
  }) {
    final corTexto = textoClaro ? Colors.white : kTextPri;
    final corSub = textoClaro ? Colors.white60 : kTextSec;
    final bordaFinal = corBorda ?? (destaque ? kLaranja : (textoClaro ? Colors.transparent : kBorder));
    final botaoBg = corBotao ?? (textoClaro ? kTextPri : kLaranja);
    final botaoFg = corTextoBotao ?? Colors.white;
    final checkColor = corCheck ?? (textoClaro ? Colors.white70 : kLaranja);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: gradiente == null && imagemFundo == null ? (corFundo ?? kCard) : null,
            gradient: gradiente,
            border: Border.all(color: bordaFinal, width: destaque ? 1.8 : 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              children: [
                if (imagemFundo != null)
                  Positioned.fill(
                    child: Image.asset(
                      imagemFundo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                if (imagemFundo != null && overlayEscuro)
                  Positioned.fill(
                    child: Container(color: Colors.black.withValues(alpha: 0.45)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: corTexto)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(preco, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: corTexto)),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(periodo, style: TextStyle(fontSize: 14, color: corSub)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: corTexto.withValues(alpha: 0.15), height: 1),
                      const SizedBox(height: 16),
                      ...beneficios.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Icon(Icons.check_rounded, size: 16, color: checkColor),
                          const SizedBox(width: 10),
                          Text(b, style: TextStyle(fontSize: 14, color: corTexto)),
                        ]),
                      )),
                      const SizedBox(height: 18),
                      _botao(
                        isAtual: isAtual,
                        bloqueado: bloqueado,
                        temGold: temGold,
                        loading: loading,
                        onPressed: onPressed,
                        labelBotao: labelBotao,
                        corTexto: corTexto,
                        botaoBg: botaoBg,
                        botaoFg: botaoFg,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (destaque)
          Positioned(
            top: -12, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: kLaranja, borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.workspace_premium_rounded, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text('POPULAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _botao({
    required bool isAtual,
    required bool bloqueado,
    required bool temGold,
    required bool loading,
    required VoidCallback? onPressed,
    required String labelBotao,
    required Color corTexto,
    required Color botaoBg,
    required Color botaoFg,
  }) {
    if (isAtual) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: corTexto.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Plano atual', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: corTexto)),
        ),
      );
    }

    if (bloqueado && temGold) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: corTexto.withValues(alpha: 0.25)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(Icons.workspace_premium_rounded, size: 16, color: corTexto.withValues(alpha: 0.6)),
          label: Text('Plano Gold assinado',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: corTexto.withValues(alpha: 0.6))),
        ),
      );
    }

    if (bloqueado) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: corTexto.withValues(alpha: 0.25)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Indisponível',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: corTexto.withValues(alpha: 0.6))),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: botaoBg,
          foregroundColor: botaoFg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: botaoFg, strokeWidth: 2))
            : Text(labelBotao, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}