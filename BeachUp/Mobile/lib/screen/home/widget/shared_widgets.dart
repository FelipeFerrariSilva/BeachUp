import 'package:flutter/material.dart';
import 'package:flutter_application_1/widget/navbar.dart';

// método reutilizável que cria o badge laranja de nome de seção
Widget nomeSecao(String nomeSecao) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.orange,
          border: Border.all(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          nomeSecao,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      SizedBox(height: 20),
    ],
  );
}

// método reutilizável que cria título em laranja e subtítulo em preto
Widget tituloSubtitulo(String titulo, String subtitulo) {
  return Column(
    children: [
      Text(
        titulo,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.normal,
          color: Colors.orange,
        ),
      ),
      SizedBox(height: 4),
      Text(
        subtitulo,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: kTextPri,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 15),
    ],
  );
}
