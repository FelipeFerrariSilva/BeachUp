import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/home/cadastro/cadastro_usuario_screen.dart';

AppBar getAppBar({List<Widget>? actions}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    title: Row(children: [Image.asset('assets/images/logo1.png', height: 35)]),
    actions: actions,
  );
}

AppBar getStartScreenAppBar(BuildContext context) {
  return getAppBar(
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ElevatedButton(
          onPressed: () {
            navigatorPush(context, CadastroUsuario());
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Row(
            children: [
              Icon(Icons.account_circle_outlined, color: Colors.black),
              SizedBox(width: 3),
              Text("Cadastrar-se", style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ),
    ],
  );
}

void navigatorPush(BuildContext context, Widget route) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => route));
}
