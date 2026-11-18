import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/home/start_screen.dart';

class AberturaScreen extends StatefulWidget {
  const AberturaScreen({super.key});

  @override
  State<AberturaScreen> createState() => _AberturaScreenState();
}

class _AberturaScreenState extends State<AberturaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/abertura.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Color(0x99000000),
                Color(0xCC000000),
              ],
              stops: [0.0, 0.45, 0.75, 1.0],
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESERVE SUA',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: 2,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  'QUADRA AGORA!',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: const Color(0xFFE97C23),
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 1.5,
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _SlideToOpen(
                        onSubmit: () async {
                          await Future.delayed(const Duration(milliseconds: 400));

                          if (!context.mounted) return;

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const StartScreen()),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class _SlideToOpen extends StatefulWidget {
  final VoidCallback onSubmit;
  final double height;

  const _SlideToOpen({required this.onSubmit, this.height = 70});

  @override
  State<_SlideToOpen> createState() => _SlideToOpenState();
}

class _SlideToOpenState extends State<_SlideToOpen>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  bool _enviado = false;
  late final AnimationController _voltaController;

  @override
  void initState() {
    super.initState();
    _voltaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() => _dragX = _voltaAnimacao.value);
      });
  }

  late Animation<double> _voltaAnimacao =
      const AlwaysStoppedAnimation(0);

  @override
  void dispose() {
    _voltaController.dispose();
    super.dispose();
  }

  void _voltarParaInicio() {
    _voltaAnimacao = Tween<double>(begin: _dragX, end: 0).animate(
      CurvedAnimation(parent: _voltaController, curve: Curves.easeOut),
    );
    _voltaController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final double botaoTamanho = widget.height - 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double larguraTotal = constraints.maxWidth;
        final double maxDrag = larguraTotal - botaoTamanho - 8;
        final double progresso =
            maxDrag <= 0 ? 0 : (_dragX / maxDrag).clamp(0.0, 1.0);

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: Container(
            height: widget.height,
            width: larguraTotal,
            color: const Color.fromARGB(255, 247, 247, 247),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  left: botaoTamanho + 14,
                  right: 12,
                  child: Center(
                    child: Opacity(
                      opacity: (1 - progresso * 1.4).clamp(0.0, 1.0),
                      child: _enviado
                          ? const Icon(Icons.check_rounded,
                              color: Color(0xFFE97C23))
                          : const Text(
                              'Deslize para começar >>',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                    ),
                  ),
                ),

                Positioned(
                  left: 4 + (maxDrag <= 0 ? 0 : _dragX),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) {
                      if (_enviado) return;
                      _voltaController.stop();
                      setState(() {
                        _dragX = (_dragX + details.delta.dx)
                            .clamp(0.0, maxDrag <= 0 ? 0.0 : maxDrag);
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_enviado) return;
                      if (maxDrag > 0 && _dragX >= maxDrag * 0.78) {
                        setState(() {
                          _enviado = true;
                          _dragX = maxDrag;
                        });
                        widget.onSubmit();
                      } else {
                        _voltarParaInicio();
                      }
                    },
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/bola.png',
                        width: botaoTamanho,
                        height: botaoTamanho,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}