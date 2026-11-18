import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/home/login/login_screen.dart';
import 'package:flutter_application_1/screen/home/widget/custom_app_bar.dart';
import 'package:flutter_application_1/screen/home/widget/shared_widgets.dart';
import 'package:flutter_application_1/widget/custom_appbar_perfil.dart';
import 'package:flutter_application_1/widget/custom_drawer.dart';
import 'package:flutter_application_1/widget/custom_card.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class SobreScreen extends StatefulWidget {
  const SobreScreen({super.key});

  @override
  State<SobreScreen> createState() => _SobreScreenState();
}

class _SobreScreenState extends State<SobreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: CustomAppBarPerfil(),
      body: ListView(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fundohome.png'),
                fit: BoxFit.fill,
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(height: 15),
                nomeSecao('Sobre nós'),
                Image.asset('assets/images/logo1.png', height: 300),
                tituloSubtitulo(
                  'Conectando jogadores e fortalecendo a comunidade do Beach Tennis',
                  'O BeachUp é uma plataforma criada para simplificar a forma como jogadores de Beach Tennis se conectam, organizam partidas e participam da comunidade. Nosso foco é oferecer uma experiência moderna, prática e acessível para todos os níveis de jogadores.',
                ),
                SizedBox(height: 20),
                CustomCard(
                  child: Column(
                    children: [
                      nomeSecao('O Projeto'),
                      tituloSubtitulo(
                        'Tecnologia aplicada ao esporte de forma simples e eficiente',
                        'O BeachUp nasceu com o objetivo de resolver uma dificuldade comum entre jogadores: encontrar parceiros e organizar partidas de forma rápida.\nA plataforma centraliza essa experiência, permitindo que usuários se conectem, combinem jogos e participem de um ambiente colaborativo voltado ao crescimento da comunidade esportiva.\nMais do que um sistema, o BeachUp é uma iniciativa que une esporte, tecnologia e interação social em um único lugar.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                CustomCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/images/logo1.png', height: 50),
                          const SizedBox(width: 6),
                          Text(
                            'BeachUp',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Plataforma digital focada em organização de partidas, conexão entre jogadores e fortalecimento da comunidade de Beach Tennis.',
                        style: TextStyle(
                          fontSize: 14,
                          color: kTextPri,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25),
                nomeSecao('Nossa Equipe'),
                tituloSubtitulo(
                  'Quem está por trás do BeachUp',
                  'Projeto desenvolvido de forma colaborativa, reunindo conhecimentos em desenvolvimento, design e experiência do usuário.',
                ),
                SizedBox(height: 15),
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(20),
                        child: Image.asset(
                          'assets/images/image2_sobre_screen.png',
                          height: 300,
                        ),
                      ),
                      SizedBox(height: 15),
                      tituloSubtitulo(
                        'Equipe BeachUp',
                        'O BeachUp foi construído por uma equipe dedicada, focada em criar soluções digitais úteis e alinhadas às necessidades reais dos jogadores.\nCada etapa do projeto foi pensada para entregar uma experiência intuitiva, funcional e alinhada com o crescimento do Beach Tennis.\nEste projeto representa não apenas desenvolvimento técnico, mas também colaboração, aprendizado e inovação.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),
                nomeSecao('DESENVOLVEDORES'),
                Row(
                  children: [
                    _cardPessoa(
                      'assets/images/Caio.png',
                      'Caio Bruno Toledo',
                      'Backend Developer',
                    ),

                    SizedBox(width: 10),

                    _cardPessoa(
                      'assets/images/Felipe.png',
                      'Felipe Ferrari da Silva',
                      'Desenvolvedor SQL',
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _cardPessoa(
                        'assets/images/Giulia.png',
                        'Giulia Lempe',
                        'Scrum Master',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _cardPessoa(
                        'assets/images/Malu.png',
                        'Maria Luiza Dias',
                        'UX/Ui Designer',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _cardPessoa(
                        'assets/images/Matheus.png',
                        'Matheus Sokolovski',
                        'Mobile Developer',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _cardPessoa(
                        'assets/images/Renan_ido.png',
                        'Renan Hidemi Tomo Ido',
                        'Mobile Developer',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: _cardPessoa(
                      'assets/images/Renan_pilan.png',
                      'Renan Pilan Neiro',
                      'Frontend Developer',
                    ),
                  ),
                ),
                SizedBox(height: 50),
                _cards(
                  Icons.flag,
                  'Missão',
                  'Facilitar a conexão entre jogadores e incentivar a prática do Beach Tennis através de uma plataforma simples e eficiente.',
                ),
                SizedBox(height: 20),

                _cards(
                  Icons.visibility,
                  "Visão",
                  'Tornar-se uma referência digital na organização e conexão da comunidade de Beach Tennis.',
                ),
                SizedBox(height: 20),
                _cards(
                  Icons.center_focus_strong,
                  'Objetivo',
                  'Proporcionar uma experiência moderna, intuitiva e relevante para jogadores que desejam participar ativamente do esporte.',
                ),
                SizedBox(height: 30),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/logo1.png', height: 56),
                          SizedBox(width: 10),
                          Text(
                            'BeachUp',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Uma plataforma construída com foco em usabilidade, comunidade e inovação no esporte.',
                        style: TextStyle(color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          navigatorPush(context, LoginScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: Text(
                          'Começar agora',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardPessoa(String foto, String nome, String profissao) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),

              child: Image.asset(
                foto,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 12),
            Text(
              nome,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              profissao,
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextPri, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cards(IconData icone, String titulo, String descricao) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                titulo,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            descricao,
            style: TextStyle(color: kTextPri, fontSize: 15, height: 1.5),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}