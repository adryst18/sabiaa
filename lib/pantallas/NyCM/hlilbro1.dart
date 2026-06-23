
import 'package:flutter/material.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/pantallas/home_screen.dart';
import 'package:sabia/pantallas/activities_screen.dart';

import 'package:sabia/pantallas/NyCM/vocales.dart';
import 'package:sabia/pantallas/NyCM/travoa.dart';
import 'package:sabia/pantallas/NyCM/travoami.dart';
import 'package:sabia/pantallas/NyCM/travoe.dart';
import 'package:sabia/pantallas/NyCM/travoemi.dart';
import 'package:sabia/pantallas/NyCM/travoi.dart';
import 'package:sabia/pantallas/NyCM/travoimi.dart';
import 'package:sabia/pantallas/NyCM/travoo.dart';
import 'package:sabia/pantallas/NyCM/travoomi.dart';
import 'package:sabia/pantallas/NyCM/travou.dart';
import 'package:sabia/pantallas/NyCM/travoumi.dart';

class HLibro1 extends StatefulWidget {
  const HLibro1({super.key});

  @override
  State<HLibro1> createState() => _HLibro1State();
}

class _HLibro1State extends State<HLibro1> {
  final VoiceService _voiceService = VoiceService();
  final LogService _logService = LogService();

  int nivel = 1;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _voiceService.init();
  }

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
        );
        break;
      default:
        setState(() => _selectedIndex = index);
    }
  }

  Widget filaVocal({
    required String mayuscula,
    required String minuscula,
    required Color colorFuerte,
    required Color colorSuave,
    required Widget pantallaMay,
    required Widget pantallaMin,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => pantallaMay),
                );
              },
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  color: colorFuerte,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    mayuscula,
                    style: const TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => pantallaMin),
                );
              },
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  color: colorSuave,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    minuscula,
                    style: const TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF134074),
        title: const Text('Libro Nivel 1'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VocalesScreen()),
              );
            },
            child: Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF9252E3),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text(
                  'VOCALES',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          filaVocal(
            mayuscula: 'A',
            minuscula: 'a',
            colorFuerte: const Color(0xFFE53935),
            colorSuave: const Color(0xFFFF6B6B),
            pantallaMay: const TrazoAScreen(),
            pantallaMin: const TrazoAMinusculaScreen(),
          ),

          filaVocal(
            mayuscula: 'E',
            minuscula: 'e',
            colorFuerte: const Color(0xFF1E88E5),
            colorSuave: const Color(0xFF64B5F6),
            pantallaMay: const TrazoEScreen(),
            pantallaMin: const TrazoEMinusculaScreen(),
          ),

          filaVocal(
            mayuscula: 'I',
            minuscula: 'i',
            colorFuerte: const Color(0xFF00ACC1),
            colorSuave: const Color(0xFF4DD0E1),
            pantallaMay: const TrazoIMayusculaScreen(),
            pantallaMin: const TrazoIMinusculaScreen(),
          ),

          filaVocal(
            mayuscula: 'O',
            minuscula: 'o',
            colorFuerte: const Color(0xFFFBC02D),
            colorSuave: const Color(0xFFFFE082),
            pantallaMay: const TrazoOMayusculaScreen(),
            pantallaMin: const TrazoOMinusculaScreen(),
          ),

          filaVocal(
            mayuscula: 'U',
            minuscula: 'u',
            colorFuerte: const Color(0xFF26A69A),
            colorSuave: const Color(0xFF80CBC4),
            pantallaMay: const TrazoUMayusculaScreen(),
            pantallaMin: const TrazoUMinusculaScreen(),
          ),

          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 40),
                SizedBox(height: 8),
                Text(
                  'ABC',
                  style: TextStyle(
                    fontSize: 70,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text('Próximamente'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: 'Actividades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Lecciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_voice),
            label: 'Voz',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.detener();
    super.dispose();
  }
}
