import 'package:flutter/material.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/models/log_entry.dart';

class VocalesScreen extends StatefulWidget {
  const VocalesScreen({super.key});

  @override
  State<VocalesScreen> createState() => _VocalesScreenState();
}

class _VocalesScreenState extends State<VocalesScreen> {
  final VoiceService _voiceService = VoiceService();
  final LogService _logService = LogService();

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _logService.addLog(
      type: LogType.navegacion,
      message: 'Pantalla de vocales cargada',
      details: {'pantalla': 'VocalesScreen'},
    );
  }

  Future<void> _reproducirVocal(String letra) async {
    await _voiceService.hablar(letra);
    await _logService.addLog(
      type: LogType.navegacion,
      message: 'Vocal reproducida',
      details: {'vocal': letra},
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔊 $letra'),
        duration: const Duration(milliseconds: 500),
        backgroundColor: const Color(0xFF38b000),
      ),
    );
  }

  Future<void> _reproducirLasVocales() async {
    await _voiceService.hablar('Las vocales');
    await _logService.addLog(
      type: LogType.navegacion,
      message: 'Frase "Las vocales" reproducida',
      details: {},
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔊 Las vocales'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF38b000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      
      appBar: AppBar(
        backgroundColor: const Color(0xFF134074),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _logService.addLog(
              type: LogType.navegacion,
              message: 'Regreso a ActivitiesScreen desde VocalesScreen',
              details: {},
            );
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/imagenes/logo.jpeg',
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Color(0xFF134074),
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SABIA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Sistema de Alfabetización Basado en Inteligencia Artificial',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      body: Stack(
        children: [
          // Fondo decorativo
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFF5F5F5),
                  const Color(0xFFE8F0FE),
                ],
              ),
            ),
          ),
          
          // Círculos decorativos de fondo
          ..._buildBackgroundCircles(),
          
          // Botón "Las vocales" en la parte superior
          Positioned(
            top: 20.0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _reproducirLasVocales,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9252e3),
                    borderRadius: BorderRadius.circular(40.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9252e3).withOpacity(0.3),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'LAS VOCALES',
                    style: TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Letras sueltas - MÁS GRANDES Y MÁS GRUESAS
          
          // a - verde grande
          Positioned(
            top: 100.0,
            left: 25.0,
            child: GestureDetector(
              onTap: () => _reproducirVocal('a'),
              child: Text(
                'a',
                style: const TextStyle(
                  fontSize: 95.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF38b000),
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 6,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // o - azul grande
          Positioned(
            top: 80.0,
            right: 35.0,
            child: GestureDetector(
              onTap: () => _reproducirVocal('o'),
              child: const Text(
                'o',
                style: TextStyle(
                  fontSize: 100.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF134074),
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 6,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // o - morado
          Positioned(
            top: 210.0,
            left: 15.0,
            child: GestureDetector(
              onTap: () => _reproducirVocal('o'),
              child: const Text(
                'o',
                style: TextStyle(
                  fontSize: 90.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9252e3),
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 6,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // A - rojo coral
          Positioned(
            top: 150.0,
            right: 40.0,
            child: GestureDetector(
              onTap: () => _reproducirVocal('A'),
              child: const Text(
                'A',
                style: TextStyle(
                  fontSize: 105.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF6B6B),
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 6,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // e - turquesa
          Positioned(
            top: 260.0,
            left: 55.0,
            child: GestureDetector(
              onTap: () => _reproducirVocal('e'),
              child: const Text(
                'e',
                style: TextStyle(
                  fontSize: 85.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4ECDC4),
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 6,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // u - amarillo
          Positioned(
            top: 240.0,
            right: 25.0,
            child: GestureDetector(
              onTap: () => _reproducirVocal('u'),
              child: const Text(
                'u',
                style: TextStyle(
                  fontSize: 92.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFE66D),
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 6,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // U - verde
          Positioned(
            top: 360.0,
            left: 35.0,
            child: GestureDetector(
              onTap: () => _reproducirVocal('U'),
              child: const Text(
                'U',
                style: TextStyle(
                  fontSize: 88.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF38b000),
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 6,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // E - azul
          Positioned(
            top: 400.0,
            right: 55.0,
            child: GestureDetector(
              onTap: () => _reproducirVocal('E'),
              child: const Text(
                'E',
                style: TextStyle(
                  fontSize: 98.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF134074),
                  shadows: [
                    Shadow(
                      offset: Offset(3, 3),
                      blurRadius: 6,
                      color: Colors.black12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Decoración adicional
          ..._buildDecorations(),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundCircles() {
    return [
      Positioned(
        top: -30.0,
        left: -30.0,
        child: Container(
          width: 150.0,
          height: 150.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF38b000).withOpacity(0.05),
          ),
        ),
      ),
      Positioned(
        bottom: -50.0,
        right: -50.0,
        child: Container(
          width: 200.0,
          height: 200.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF9252e3).withOpacity(0.05),
          ),
        ),
      ),
      Positioned(
        top: 200.0,
        right: 80.0,
        child: Container(
          width: 80.0,
          height: 80.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF134074).withOpacity(0.03),
          ),
        ),
      ),
      Positioned(
        bottom: 150.0,
        left: 40.0,
        child: Container(
          width: 100.0,
          height: 100.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFE66D).withOpacity(0.1),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildDecorations() {
    final List<Map<String, dynamic>> decorations = [
      {'top': 120.0, 'left': 15.0, 'size': 5.0},
      {'top': 180.0, 'left': 25.0, 'size': 4.0},
      {'top': 250.0, 'left': 10.0, 'size': 6.0},
      {'top': 350.0, 'left': 20.0, 'size': 4.0},
      {'top': 450.0, 'left': 15.0, 'size': 5.0},
      {'top': 500.0, 'left': 35.0, 'size': 4.0},
      {'top': 130.0, 'right': 20.0, 'size': 5.0},
      {'top': 210.0, 'right': 15.0, 'size': 4.0},
      {'top': 290.0, 'right': 25.0, 'size': 6.0},
      {'top': 380.0, 'right': 30.0, 'size': 4.0},
      {'top': 470.0, 'right': 20.0, 'size': 5.0},
    ];
    
    return decorations.map((dec) {
      return Positioned(
        top: dec['top'] as double,
        left: dec.containsKey('left') ? dec['left'] as double : null,
        right: dec.containsKey('right') ? dec['right'] as double : null,
        child: Container(
          width: dec['size'] as double,
          height: dec['size'] as double,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF9b9b9b).withOpacity(0.3),
          ),
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _voiceService.detener();
    super.dispose();
  }
}