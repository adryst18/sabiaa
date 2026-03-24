import 'package:flutter/material.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/models/log_entry.dart';
import 'package:sabia/pantallas/home_screen.dart';
import 'package:sabia/pantallas/activities_screen.dart';
import 'package:sabia/pantallas/NyCM/vocales.dart';
import 'package:sabia/pantallas/NyCM/travoa.dart';

class HLibro1 extends StatefulWidget {
  const HLibro1({super.key});

  @override
  State<HLibro1> createState() => _HLibro1State();
}

class _HLibro1State extends State<HLibro1> {
  final VoiceService _voiceService = VoiceService();
  final LogService _logService = LogService();
  
  // Variables de estado
  int nivel = 1;
  int _selectedIndex = 2; // Índice 2 porque es la pantalla de Lecciones
  
  // Lista de lecciones del libro - SOLO LAS DOS QUE EXISTEN
  final List<Map<String, dynamic>> _lecciones = [
    {
      'titulo': 'Lección 1: Las Vocales',
      'descripcion': 'Aprende a identificar y pronunciar las 5 vocales: A, E, I, O, U',
      'icono': Icons.volume_up,
      'color': const Color(0xFF38b000),
      'habilitado': true,
      'ruta': 'vocales',
      'textoLectura': 'Lección 1: Las Vocales. Aprende a identificar y pronunciar las 5 vocales: A, E, I, O, U. En esta lección practicarás la pronunciación y el reconocimiento de cada vocal.'
    },
    {
      'titulo': 'Lección 2: Trazo de la Vocal A',
      'descripcion': 'Practica el trazo correcto de la letra A mayúscula y minúscula',
      'icono': Icons.edit,
      'color': const Color(0xFF9252e3),
      'habilitado': true,
      'ruta': 'trazo_a',
      'textoLectura': 'Lección 2: Trazo de la Vocal A. Practica el trazo correcto de la letra A mayúscula y minúscula. Sigue las indicaciones para aprender a escribir la letra A correctamente.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _logService.addLog(
      type: LogType.navegacion,
      message: 'Pantalla de Libro Nivel 1 cargada',
      details: {'pantalla': 'HLibro1'},
    );
  }

  Future<void> _leerTexto(String texto) async {
    await _voiceService.hablar(texto);
    await _logService.addLog(
      type: LogType.navegacion,
      message: 'Lectura de texto en libro nivel 1',
      details: {'texto': texto.substring(0, texto.length > 50 ? 50 : texto.length)},
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔊 $texto'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF38b000),
      ),
    );
  }

  void _navegarALeccion(Map<String, dynamic> leccion) {
    switch (leccion['ruta']) {
      case 'vocales':
        _logService.addLog(
          type: LogType.navegacion,
          message: 'Navegando a lección de vocales',
          details: {'leccion': leccion['titulo']},
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VocalesScreen()),
        );
        break;
      case 'trazo_a':
        _logService.addLog(
          type: LogType.navegacion,
          message: 'Navegando a trazo de letra A',
          details: {'leccion': leccion['titulo']},
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrazoAScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📚 ${leccion['titulo']} - Próximamente disponible'),
            backgroundColor: const Color(0xFF9b9b9b),
          ),
        );
    }
  }

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0: // Inicio
        await _logService.addLog(
          type: LogType.navegacion,
          message: 'Navegación a HomeScreen desde Libro Nivel 1',
          details: {'origen': 'HLibro1'},
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1: // Actividades
        await _logService.addLog(
          type: LogType.navegacion,
          message: 'Navegación a ActivitiesScreen desde Libro Nivel 1',
          details: {'origen': 'HLibro1'},
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
        );
        break;
      case 2: // Lecciones (ya estamos aquí)
        setState(() => _selectedIndex = 2);
        break;
      case 3: // Configurar Voz
        setState(() => _selectedIndex = 3);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Configuración de voz (próximamente)'),
            backgroundColor: Color(0xFF38b000),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      
      // Header igual que home_screen
      appBar: AppBar(
        backgroundColor: const Color(0xFF134074),
        elevation: 2,
        automaticallyImplyLeading: false,
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
            const Spacer(),
            // Contador de nivel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Nivel $nivel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del libro
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF9252e3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF9252e3).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book,
                    color: Color(0xFF9252e3),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Libro - Nivel 1',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF134074),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lecciones de alfabetización',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _leerTexto('Libro Nivel 1. Contiene las lecciones básicas de alfabetización: vocales y trazo de la letra A. Comienza con la Lección 1: Las Vocales.'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38b000).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volume_up,
                        color: Color(0xFF38b000),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Subtítulo con progreso
            Row(
              children: [
                const Icon(
                  Icons.timeline,
                  size: 20,
                  color: Color(0xFF38b000),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tu progreso en este nivel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38b000).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '0/${_lecciones.length} completadas',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF38b000),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Lista de lecciones
            ..._lecciones.asMap().entries.map((entry) {
              final index = entry.key;
              final leccion = entry.value;
              final isHabilitado = leccion['habilitado'] == true;
              final color = leccion['color'];
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isHabilitado ? color.withOpacity(0.3) : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isHabilitado ? () => _navegarALeccion(leccion) : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Número de lección
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isHabilitado 
                                  ? color.withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isHabilitado ? color : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Información de la lección
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  leccion['titulo'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isHabilitado ? const Color(0xFF134074) : Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  leccion['descripcion'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isHabilitado ? Colors.grey[600] : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Iconos de acción
                          if (isHabilitado)
                            Row(
                              children: [
                                // Botón de bocina
                                GestureDetector(
                                  onTap: () => _leerTexto(leccion['textoLectura']),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.volume_up,
                                      color: color,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Icono de navegación
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: color,
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Próximo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 20),
            
            // Mensaje de finalización
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF38b000).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Completa estas lecciones para desbloquear más contenido',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Barra de navegación inferior
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF38b000),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
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
              label: 'Configurar Voz',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.detener();
    super.dispose();
  }
}