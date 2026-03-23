import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/models/log_entry.dart';

class ConfigVozScreen extends StatefulWidget {
  const ConfigVozScreen({super.key});

  @override
  State<ConfigVozScreen> createState() => _ConfigVozScreenState();
}

class _ConfigVozScreenState extends State<ConfigVozScreen> {
  final VoiceService _voiceService = VoiceService();
  final LogService _logService = LogService();
  
  TipoVoz _tipoActual = TipoVoz.femenina1;
  double _velocidadActual = 0.5;
  bool _isLoading = true;
  bool _isSpeaking = false;
  
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
    
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    
    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      print('Error TTS: $msg');
    });
  }

  Future<void> _cargarConfiguracion() async {
    await _voiceService.init();
    setState(() {
      _tipoActual = _voiceService.tipoActual;
      _velocidadActual = _voiceService.velocidadActual;
      _isLoading = false;
    });
  }

  Future<void> _guardarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_voice_type', _tipoActual.index);
    await prefs.setDouble('selected_voice_speed', _velocidadActual);
    await _voiceService.recargarConfiguracion();
  }

  Future<void> _probarVoz() async {
    String texto = _getTextoPrueba();
    await _flutterTts.setLanguage(_getLocale());
    await _flutterTts.setPitch(_getPitch());
    await _flutterTts.setSpeechRate(_velocidadActual);
    await _flutterTts.speak(texto);
    
    await _logService.addLog(
      type: LogType.navegacion,
      message: 'Prueba de voz',
      details: {'voz': _getNombreVoz(), 'velocidad': _velocidadActual},
    );
  }

  String _getTextoPrueba() {
    switch (_tipoActual) {
      case TipoVoz.femenina1:
        return 'Hola, soy tu asistente femenina. ¿En qué puedo ayudarte?';
      case TipoVoz.femenina2:
        return 'Hola, soy la voz latina. Todo bien, ¿y tú?';
      case TipoVoz.masculina1:
        return 'Hola, soy tu asistente masculino. Estoy aquí para ayudarte.';
      case TipoVoz.masculina2:
        return 'Hola, soy la voz profunda. Bienvenido a Sabia.';
      case TipoVoz.infantil:
        return '¡Hola amiguito! Vamos a aprender jugando.';
      case TipoVoz.ia:
        return 'Sistema de aprendizaje inteligente activado. Preparando lecciones.';
    }
  }

  String _getNombreVoz() {
    switch (_tipoActual) {
      case TipoVoz.femenina1:
        return 'Femenina 1 (Español)';
      case TipoVoz.femenina2:
        return 'Femenina 2 (Latina)';
      case TipoVoz.masculina1:
        return 'Masculina 1 (Español)';
      case TipoVoz.masculina2:
        return 'Masculina 2 (Profundo)';
      case TipoVoz.infantil:
        return 'Voz Infantil';
      case TipoVoz.ia:
        return 'Voz IA (Neutra)';
    }
  }

  String _getNombreVozCorto(TipoVoz tipo) {
    switch (tipo) {
      case TipoVoz.femenina1:
        return 'Femenina 1';
      case TipoVoz.femenina2:
        return 'Femenina 2';
      case TipoVoz.masculina1:
        return 'Masculina 1';
      case TipoVoz.masculina2:
        return 'Masculina 2';
      case TipoVoz.infantil:
        return 'Infantil';
      case TipoVoz.ia:
        return 'IA';
    }
  }

  IconData _getIconForTipo(TipoVoz tipo) {
    switch (tipo) {
      case TipoVoz.femenina1:
      case TipoVoz.femenina2:
        return Icons.female;
      case TipoVoz.masculina1:
      case TipoVoz.masculina2:
        return Icons.male;
      case TipoVoz.infantil:
        return Icons.child_care;
      case TipoVoz.ia:
        return Icons.smart_toy;
    }
  }

  String _getLocale() {
    switch (_tipoActual) {
      case TipoVoz.femenina2:
        return 'es-MX';
      default:
        return 'es-ES';
    }
  }

  double _getPitch() {
    switch (_tipoActual) {
      case TipoVoz.femenina1:
        return 1.0;
      case TipoVoz.femenina2:
        return 1.1;
      case TipoVoz.masculina1:
        return 0.9;
      case TipoVoz.masculina2:
        return 0.7;
      case TipoVoz.infantil:
        return 1.5;
      case TipoVoz.ia:
        return 1.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF134074),
        elevation: 2,
        title: const Text(
          'Configuración de Voz',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38b000)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Tarjeta de información
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9252e3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.volume_up, color: Color(0xFF9252e3), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selecciona tu voz preferida',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF134074),
                                ),
                              ),
                              Text(
                                'La voz seleccionada se usará en toda la aplicación',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Grid de opciones de voz
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: TipoVoz.values.map((tipo) {
                      final isSelected = _tipoActual == tipo;
                      final color = isSelected ? const Color(0xFF38b000) : const Color(0xFF9b9b9b);
                      
                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            _tipoActual = tipo;
                          });
                          await _guardarConfiguracion();
                          await _probarVoz();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF38b000).withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF38b000) : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getIconForTipo(tipo),
                                color: color,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getNombreVozCorto(tipo),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF38b000) : const Color(0xFF134074),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (isSelected)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38b000),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'ACTUAL',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Control de velocidad
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.speed, color: Color(0xFF38b000), size: 24),
                            const SizedBox(width: 10),
                            const Text(
                              'Velocidad de lectura',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF134074),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38b000).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${(_velocidadActual * 100).toInt()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF38b000),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: _velocidadActual,
                          min: 0.3,
                          max: 1.0,
                          divisions: 7,
                          activeColor: const Color(0xFF38b000),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (value) async {
                            setState(() {
                              _velocidadActual = value;
                            });
                            await _guardarConfiguracion();
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Lento', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            Text('Normal', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            Text('Rápido', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón de prueba
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _probarVoz,
                      icon: _isSpeaking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow, color: Colors.white),
                      label: Text(
                        _isSpeaking ? 'Reproduciendo...' : 'Probar voz',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38b000),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFF9b9b9b)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'La configuración de voz se guarda automáticamente y se aplica en toda la aplicación.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
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

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}