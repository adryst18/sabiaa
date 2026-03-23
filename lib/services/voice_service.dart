import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de voz disponibles
enum TipoVoz {
  femenina1,
  femenina2,
  masculina1,
  masculina2,
  infantil,
  ia
}

/// Servicio de voz compartido para toda la aplicación
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  
  TipoVoz _tipoActual = TipoVoz.femenina1;
  double _velocidadActual = 0.5;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(_velocidadActual);
    await _cargarPreferenciaVoz();
    _isInitialized = true;
  }

  Future<void> _cargarPreferenciaVoz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tipoGuardado = prefs.getInt('selected_voice_type');
      
      if (tipoGuardado != null && tipoGuardado >= 0 && tipoGuardado < TipoVoz.values.length) {
        _tipoActual = TipoVoz.values[tipoGuardado];
      }
      
      _velocidadActual = prefs.getDouble('selected_voice_speed') ?? 0.5;
      await _aplicarConfiguracionVoz();
    } catch (e) {
      // Usamos print en lugar de debugPrint
      print('Error al cargar preferencia de voz: $e');
    }
  }

  Future<void> _aplicarConfiguracionVoz() async {
    try {
      switch (_tipoActual) {
        case TipoVoz.femenina1:
          await _flutterTts.setLanguage('es-ES');
          await _flutterTts.setPitch(1.0);
          break;
        case TipoVoz.femenina2:
          await _flutterTts.setLanguage('es-MX');
          await _flutterTts.setPitch(1.1);
          break;
        case TipoVoz.masculina1:
          await _flutterTts.setLanguage('es-ES');
          await _flutterTts.setPitch(0.9);
          break;
        case TipoVoz.masculina2:
          await _flutterTts.setLanguage('es-ES');
          await _flutterTts.setPitch(0.7);
          break;
        case TipoVoz.infantil:
          await _flutterTts.setLanguage('es-ES');
          await _flutterTts.setPitch(1.5);
          break;
        case TipoVoz.ia:
          await _flutterTts.setLanguage('es-ES');
          await _flutterTts.setPitch(1.2);
          break;
      }
      await _flutterTts.setSpeechRate(_velocidadActual);
    } catch (e) {
      print('Error al aplicar configuración de voz: $e');
    }
  }

  Future<void> hablar(String texto) async {
    try {
      await _flutterTts.speak(texto);
    } catch (e) {
      print('Error al usar TTS: $e');
    }
  }

  Future<void> detener() async {
    await _flutterTts.stop();
  }
  
  Future<void> recargarConfiguracion() async {
    await _cargarPreferenciaVoz();
  }
  
  TipoVoz get tipoActual => _tipoActual;
  double get velocidadActual => _velocidadActual;
}