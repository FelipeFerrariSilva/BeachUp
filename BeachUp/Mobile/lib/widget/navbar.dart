import 'package:flutter/material.dart';

const Color kLaranja  = Color(0xFFFF6B00);
const Color kOffWhite = Color(0xFFFAF8F5);
const Color kCard     = Colors.white;
const Color kTextPri  = Color(0xFF1A1A1A);
const Color kTextSec  = Color(0xFF888888);
const Color kBorder   = Color(0xFFEDEDED);

Color appBg(BuildContext context)       => kOffWhite;
Color appCard(BuildContext context)     => Colors.white;
Color appBorder(BuildContext context)   => kBorder;
Color appTextPri(BuildContext context)  => kTextPri;
Color appTextSec(BuildContext context)  => kTextSec;

class Navbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Navbar({super.key, required this.currentIndex, required this.onTap});

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
              _item(context, 0, Icons.home_rounded,          Icons.home_outlined,          'Início'),
              _item(context, 1, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Reservas'),
              _item(context, 2, Icons.groups_rounded,         Icons.groups_outlined,         'Times'),
              _item(context, 3, Icons.emoji_events_rounded,   Icons.emoji_events_outlined,   'Campeonatos'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, IconData ativo, IconData inativo, String label) {
    final sel = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? kLaranja.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sel ? ativo : inativo, color: sel ? kLaranja : kTextSec, size: 24),
            const SizedBox(height: 4),
            Text(label,
              style: TextStyle(
                fontSize: 10,
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