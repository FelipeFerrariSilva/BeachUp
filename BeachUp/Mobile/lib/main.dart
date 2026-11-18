import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_1/provider/auth_provider.dart';
import 'package:flutter_application_1/screen/home/abertura_screen.dart';
import 'package:flutter_application_1/screen/jogador/home_screen.dart';
import 'package:flutter_application_1/screen/empresa/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..verificarLogin()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(primary: Color(0xFFFF6B00)),
        scaffoldBackgroundColor: const Color(0xFFFAF8F5),
        useMaterial3: false,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.carregando) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
          );
        }
        if (auth.estaLogado) {
          return auth.isEmpresa
              ? const HomeEmpresaScreen()
              : const HomeJogadorScreen();
        }
        return const AberturaScreen();
      },
    );
  }
}