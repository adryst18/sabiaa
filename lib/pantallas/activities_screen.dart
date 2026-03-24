import 'package:flutter/material.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/models/log_entry.dart';
import 'package:sabia/pantallas/home_screen.dart';
import 'package:sabia/pantallas/profile_screen.dart';
import 'package:sabia/pantallas/config_voz_screen.dart';
import 'package:sabia/pantallas/NyCM/vocales.dart';
import 'package:sabia/pantallas/NyCM/hlilbro1.dart';


class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final LogService _logService = LogService();
  final VoiceService _voiceService = VoiceService();
  
  // Variables de estado
  int puntos = 0;
  bool retoCompletado = false;
  int actividades = 0;
  
  // Control de navegación
  int _selectedIndex = 1; // Índice 1 porque es la pantalla de Actividades

  @override
  void initState() {
    super.initState();
    _inicializarServicios();
    _logService.addLog(
      type: LogType.navegacion,
      message: 'Pantalla de actividades cargada',
      details: {'pantalla': 'ActivitiesScreen'},
    );
  }

  Future<void> _inicializarServicios() async {
    await _voiceService.init();
    await _cargarPuntos();
    setState(() {});
  }

  Future<void> _cargarPuntos() async {
    // Aquí se cargarían los puntos desde SharedPreferences
    // Por ahora mantiene el estado local
    setState(() {});
  }

  Future<void> _leerTexto(String texto) async {
    await _voiceService.hablar(texto);
    await _logService.addLog(
      type: LogType.navegacion,
      message: 'Lectura de texto en actividades',
      details: {'texto': texto},
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔊 $texto'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF38b000),
      ),
    );
  }

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0: // Inicio
        await _logService.addLog(
          type: LogType.navegacion,
          message: 'Navegación a HomeScreen',
          details: {'origen': 'ActivitiesScreen', 'destino': 'HomeScreen'},
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1: // Actividades (ya estamos aquí)
        setState(() => _selectedIndex = 1);
        break;
      case 2: // Lecciones
        setState(() => _selectedIndex = 2);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📚 Pantalla de Lecciones (próximamente)'),
            backgroundColor: Color(0xFF38b000),
          ),
        );
        break;
      case 3: // Perfil
        await _logService.addLog(
          type: LogType.navegacion,
          message: 'Navegación a PerfilScreen',
          details: {'origen': 'ActivitiesScreen'},
        );
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConfigVozScreen()),
        );
        
        if (result == true) {
          // Recargar configuración de voz si hubo cambios
          await _voiceService.recargarConfiguracion();
          setState(() {});
        }
        setState(() => _selectedIndex = 1);
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SABIA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
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
                    '$puntos pts',
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
            // Título de bienvenida con bocina
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
                    Icons.school,
                    color: Color(0xFF9252e3),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¡Descubre tu camino al aprendizaje!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF134074),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selecciona una actividad para comenzar',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón de bocina para leer el mensaje de bienvenida
                  GestureDetector(
                    onTap: () => _leerTexto(
                      '¡Descubre tu camino al aprendizaje! Selecciona una actividad para comenzar. NyCM LPA, Lecciones IVEA digitalizadas.'
                    ),
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
            const SizedBox(height: 24),
            
            // Card principal habilitada - NyCM LPA
            _buildActivityCard(
              titulo: "NyCM LPA",
              descripcion: "Lecciones IVEA digitalizadas. Aprende a leer y escribir de forma interactiva y personalizada.",
              imagenAsset: "assets/imagenes/portada.jpg",
              habilitado: true,
              colorBorde: const Color(0xFF38b000),
              
              onTap: () {
                _logService.addLog(
                  type: LogType.navegacion,
                  message: 'Actividad NyCM LPA seleccionada - Navegando a Libro Nivel 1',
                  details: {'actividad': 'NyCM LPA', 'destino': 'HLibro1'},
                );
                
                // Navegar a la pantalla del libro nivel 1
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HLibro1()),
                );
              },
              onRead: () {
                _leerTexto('NyCM LPA. Programa de Alfabetización con apoyo de Inteligencia Artificial. Lecciones IVEA digitalizadas. Aprende a leer y escribir de forma interactiva y personalizada. Contiene lecciones de vocales, sílabas y palabras completas.');
              },
            ),
            // Card deshabilitada - Libro Alfabetizacion
            _buildActivityCard(
              titulo: "Libro Alfabetizacion",
              descripcion: "Material didáctico interactivo para el aprendizaje de la lectoescritura.",
              imagenAsset: "assets/imagenes/portada2.jpg",
              habilitado: false,
              colorBorde: const Color(0xFF9b9b9b),
              onTap: null,
              onRead: () {
                _leerTexto('Libro Alfabetizacion. Material didáctico interactivo para el aprendizaje de la lectoescritura. Próximamente disponible.');
              },
            ),
            
            const SizedBox(height: 16),
            
            // Card deshabilitada - Cuadernillo
            _buildActivityCard(
              titulo: "Cuadernillo",
              descripcion: "Ejercicios prácticos para reforzar el aprendizaje de letras y palabras.",
              imagenAsset: "assets/imagenes/portada3.png",
              habilitado: false,
              colorBorde: const Color(0xFF9b9b9b),
              onTap: null,
              onRead: () {
                _leerTexto('Cuadernillo. Ejercicios prácticos para reforzar el aprendizaje de letras y palabras. Próximamente disponible.');
              },
            ),
            
            const SizedBox(height: 16),
            
            // Card deshabilitada - nycm
            _buildActivityCard(
              titulo: "NyCM",
              descripcion: "Núcleo de Conocimiento Multidisciplinario. Actividades integradas para un aprendizaje completo.",
              imagenAsset: "assets/imagenes/portada4.jpg",
              habilitado: false,
              colorBorde: const Color(0xFF9b9b9b),
              onTap: null,
              onRead: () {
                _leerTexto('NyCM. Núcleo de Conocimiento Multidisciplinario. Actividades integradas para un aprendizaje completo. Próximamente disponible.');
              },
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
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required String titulo,
    required String descripcion,
    required String imagenAsset,
    required bool habilitado,
    required Color colorBorde,
    VoidCallback? onTap,
    required VoidCallback onRead,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorBorde.withOpacity(habilitado ? 0.5 : 0.2),
          width: habilitado ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de portada
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  child: Image.asset(
                    imagenAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF134074).withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Overlay si está deshabilitado
                if (!habilitado)
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9b9b9b),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Próximamente',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: habilitado ? const Color(0xFF134074) : const Color(0xFF9b9b9b),
                          ),
                        ),
                      ),
                      // Botón de bocina para leer
                      GestureDetector(
                        onTap: onRead,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: habilitado 
                                ? const Color(0xFF38b000).withOpacity(0.1)
                                : const Color(0xFF9b9b9b).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up,
                            color: habilitado ? const Color(0xFF38b000) : const Color(0xFF9b9b9b),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 13,
                      color: habilitado ? Colors.grey[600] : const Color(0xFF9b9b9b),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Botón de acción
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: habilitado ? onTap : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: habilitado ? const Color(0xFF38b000) : const Color(0xFF9b9b9b),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: habilitado ? 2 : 0,
                      ),
                      child: Text(
                        habilitado ? 'Comenzar' : 'Próximamente',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}