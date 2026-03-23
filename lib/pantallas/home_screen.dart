import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabia/pantallas/config_voz_screen.dart';
import 'package:sabia/pantallas/activities_screen.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/models/log_entry.dart';
import 'package:sabia/pantallas/dashboard_screen.dart';

void main() {
  runApp(const SabiaApp());
}

class SabiaApp extends StatelessWidget {
  const SabiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sabia - Sistema de Alfabetización Basado en IA',
      theme: ThemeData(
        primaryColor: const Color(0xFF0D3B66),
        scaffoldBackgroundColor: const Color(0xFFF5FAFF),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

/// ==================== SECCIÓN: PANTALLA PRINCIPAL ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variables de estado
  int puntos = 0;
  bool retoCompletado = false;
  int actividades = 0;
  
  // Variables para el reto interactivo
  String _palabraActual = "GATO";
  List<bool> _letrasSeleccionadas = [];
  List<bool> _vocalesIndices = [];
  bool _haSeleccionado = false;
  
  // Lista de palabras para diferentes retos
  final List<String> _palabras = [
    "GATO",
    "PERRO",
    "RATON",
    "CASA",
    "MESA",
    "SOL",
    "LUNA",
    "AGUA",
    "FOCA",
    "OSO",
  ];
  
  // Servicio de voz compartido
  final VoiceService _voiceService = VoiceService();
  
  // Servicio de logs
  final LogService _logService = LogService();
  
  // Control de navegación
  int _selectedIndex = 0;
  
  // Variable para controlar el doble back para salir
  DateTime? _lastPressed;

  @override
  void initState() {
    super.initState();
    _inicializarServicios();
    _inicializarReto();
  }

  Future<void> _inicializarServicios() async {
    await _voiceService.init();
    
    _logService.addLog(
      type: LogType.navegacion,
      message: 'Pantalla principal cargada',
      details: {'pantalla': 'HomeScreen'},
    );
  }

  void _inicializarReto() {
    _letrasSeleccionadas = List<bool>.filled(_palabraActual.length, false);
    _vocalesIndices = _palabraActual.split('').asMap().entries.map((entry) {
      return _esVocal(entry.value);
    }).toList();
    _haSeleccionado = false;
  }

  bool _esVocal(String letra) {
    const vocales = ['A', 'E', 'I', 'O', 'U', 'Á', 'É', 'Í', 'Ó', 'Ú'];
    return vocales.contains(letra.toUpperCase());
  }

  void _toggleLetra(int index) {
    setState(() {
      _letrasSeleccionadas[index] = !_letrasSeleccionadas[index];
      _haSeleccionado = _letrasSeleccionadas.any((seleccionada) => seleccionada);
    });
  }

  void _verificarReto() async {
    bool esCorrecto = true;
    for (int i = 0; i < _letrasSeleccionadas.length; i++) {
      if (_vocalesIndices[i] != _letrasSeleccionadas[i]) {
        esCorrecto = false;
        break;
      }
    }

    if (esCorrecto) {
      int puntosAnteriores = puntos;
      setState(() {
        retoCompletado = true;
        puntos += 2;
        // El reto NO afecta el progreso de actividades
      });
      
      await _logService.addLog(
        type: LogType.retoCompletado,
        message: 'Reto del día completado correctamente',
        details: {
          'palabra': _palabraActual,
          'puntos_ganados': 2,
          'puntos_totales': puntos,
          'puntos_anteriores': puntosAnteriores,
        },
      );
      
      await _voiceService.hablar('¡Excelente! Has completado el reto correctamente. +2 puntos.');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.celebration, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🎉 ¡Correcto! Has ganado 2 puntos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else {
      await _logService.addLog(
        type: LogType.error,
        message: 'Intento fallido en reto',
        details: {
          'palabra': _palabraActual,
          'seleccion': _letrasSeleccionadas.toString(),
          'vocales_correctas': _vocalesIndices.toString(),
        },
      );
      
      await _voiceService.hablar('Incorrecto, vuelve a intentarlo');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡Incorrecto!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Vuelve a intentarlo',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        
        setState(() {
          _letrasSeleccionadas = List<bool>.filled(_palabraActual.length, false);
          _haSeleccionado = false;
        });
      }
    }
  }

  void _rotarPalabra() {
    if (retoCompletado) return;
    
    final indexActual = _palabras.indexOf(_palabraActual);
    final nuevoIndex = (indexActual + 1) % _palabras.length;
    
    setState(() {
      _palabraActual = _palabras[nuevoIndex];
      _letrasSeleccionadas = List<bool>.filled(_palabraActual.length, false);
      _vocalesIndices = _palabraActual.split('').asMap().entries.map((entry) {
        return _esVocal(entry.value);
      }).toList();
      _haSeleccionado = false;
    });
    
    _voiceService.hablar('Nueva palabra: $_palabraActual. Selecciona todas las vocales.');
    
    _logService.addLog(
      type: LogType.navegacion,
      message: 'Palabra del reto cambiada',
      details: {'palabra_anterior': _palabras[indexActual], 'palabra_nueva': _palabraActual},
    );
  }

  @override
  void dispose() {
    _voiceService.detener();
    super.dispose();
  }

  Future<void> leerTexto(String texto) async {
    await _voiceService.hablar(texto);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔊 $texto'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF0D3B66),
        ),
      );
    }
  }

  Future<void> _onItemTapped(int index) async {
    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        await _logService.addLog(
          type: LogType.navegacion,
          message: 'Navegación a Actividades',
          details: {'origen': 'HomeScreen'},
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
        );
        break;
      case 2:
        setState(() => _selectedIndex = 2);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📚 Pantalla de Lecciones (próximamente)'),
            backgroundColor: Color(0xFF0D3B66),
          ),
        );
        break;
      case 3:
        await _logService.addLog(
          type: LogType.navegacion,
          message: 'Navegación a Configuración de Voz',
          details: {'origen': 'HomeScreen'},
        );
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConfigVozScreen()),
        );
        
        if (result == true) {
          await _voiceService.recargarConfiguracion();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Configuración de voz actualizada'),
                backgroundColor: Color(0xFF0D3B66),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        setState(() => _selectedIndex = 0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastPressed == null || now.difference(_lastPressed!) > const Duration(seconds: 2)) {
          _lastPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presiona una vez más para salir'),
              backgroundColor: Color(0xFF0D3B66),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        
        await _logService.addLog(
          type: LogType.navegacion,
          message: 'Usuario cerró la aplicación',
          details: {'puntos_totales': puntos, 'reto_completado': retoCompletado},
        );
        
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FAFF),
        
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
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              _buildRetoCard(),
              const SizedBox(height: 16),
              _buildProgresoCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),

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
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final fechaActual = _getFechaFormateada();
    final mensajeBienvenida = 'Bienvenido de nuevo. Hoy es $fechaActual. '
        'Continúa tu progreso de aprendizaje. Cada día es una nueva oportunidad para crecer.';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Bienvenido de nuevo!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF134074),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fechaActual,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Continúa tu progreso de aprendizaje. Cada día es una nueva oportunidad para crecer.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => leerTexto(mensajeBienvenida),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF134074),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volume_up,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD180), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: retoCompletado
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF5E1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    '¡Reto completado! +2 puntos',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF134074),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Reto del Día',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF134074),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => leerTexto('Selecciona todas las vocales en la palabra $_palabraActual. Toca cada letra que sea vocal.'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.volume_up,
                            color: Colors.orange, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona todas las vocales de la palabra:',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gana 2 puntos',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_palabraActual.length, (index) {
                            final letra = _palabraActual[index];
                            final isVocal = _vocalesIndices[index];
                            final isSelected = _letrasSeleccionadas[index];
                            
                            final screenWidth = MediaQuery.of(context).size.width;
                            final baseWidth = (screenWidth - 80) / _palabraActual.length;
                            final boxSize = baseWidth.clamp(55.0, 75.0);
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => _toggleLetra(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: boxSize,
                                  height: boxSize,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isVocal ? Colors.green : Colors.red.shade300)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isVocal ? Colors.green.shade700 : Colors.red.shade700)
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: (isVocal ? Colors.green : Colors.red).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      letra,
                                      style: TextStyle(
                                        fontSize: boxSize * 0.4,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.grey.shade800,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Color(0xFF134074)),
                            const SizedBox(width: 8),
                            Text(
                              'Las vocales son: A, E, I, O, U',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _rotarPalabra,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Cambiar palabra'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF134074),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: Color(0xFF134074)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        onPressed: _haSeleccionado ? _verificarReto : null,
                        child: const Text(
                          'Completar Reto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildProgresoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF134074), size: 20),
              SizedBox(width: 8),
              Text(
                'Tu Progreso de Hoy',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF134074),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actividades completadas',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                '$actividades / 5',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF134074),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: actividades / 5,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38b000)),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => leerTexto(
                'Has completado $actividades de 5 actividades. Sigue así para alcanzar tu meta diaria.'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Leer progreso',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(Icons.volume_up, color: Colors.grey[400], size: 16),
              ],
            ),
          ),
          
          // Botón para Dashboard
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF38b000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.dashboard, color: Color(0xFF38b000)),
              title: const Text(
                'Ver bitácora de actividades',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF134074),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF134074)),
              onTap: () async {
                await _logService.addLog(
                  type: LogType.navegacion,
                  message: 'Navegación a Dashboard',
                  details: {'origen': 'HomeScreen'},
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getFechaFormateada() {
    final now = DateTime.now();
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final days = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];
    
    return '${days[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]} de ${now.year}';
  }
}