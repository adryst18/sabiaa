import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/pantallas/NyCM/hlilbro1.dart';
import 'package:sabia/pantallas/NyCM/travou.dart';

class TomateAnimado {
  final Offset posicion;
  TomateAnimado({required this.posicion});
}

class TrazoOMinusculaScreen extends StatefulWidget {
  const TrazoOMinusculaScreen({super.key});
  @override
  State<TrazoOMinusculaScreen> createState() => _TrazoOMinusculaScreenState();
}

class _TrazoOMinusculaScreenState extends State<TrazoOMinusculaScreen> with TickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<List<Offset>> _trazos = [];
  List<Offset> _trazoActual = [];
  List<TomateAnimado> _huerto = [];
  double _precision = 0.0; double _sumaP = 0.0; int _m = 0;
  late AnimationController _blink;
  final List<Offset> _puntos = [];
  List<bool> _cubiertos = [];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _generarReferencias();
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _voiceService.hablar('¡Ahora la o minúscula! Traza este pequeño círculo.');
  }

  void _generarReferencias() {
    _puntos.clear();
    for (double a = 0; a <= 2 * math.pi; a += 0.25) {
      double x = 165 + 60 * math.cos(a);
      double y = 240 + 60 * math.sin(a);
      _puntos.add(Offset(x, y));
    }
    _cubiertos = List.filled(_puntos.length, false);
  }

  @override
  void dispose() { _blink.dispose(); _audioPlayer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(backgroundColor: const Color(0xFF134074), title: const Text('SABIA - Letra o minúscula', style: TextStyle(color: Colors.white))),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 330, height: 440,
                decoration: BoxDecoration(color: const Color(0xFF99d98c), borderRadius: BorderRadius.circular(32)),
                child: GestureDetector(
                  onPanStart: (d) {
                    _audioPlayer.setReleaseMode(ReleaseMode.loop);
                    _audioPlayer.play(AssetSource('sounds/tractor.mp3')).catchError((_){});
                    setState(() { _trazoActual = [d.localPosition]; });
                  },
                  onPanUpdate: (d) {
                    if (_trazoActual.isEmpty) return;
                    setState(() {
                      _trazoActual.add(d.localPosition);
                      double minDist = double.infinity;
                      for (var p in _puntos) {
                        double dist = (d.localPosition - p).distance;
                        if (dist < minDist) minDist = dist;
                      }
                      double pm = minDist <= 10.0 ? 100.0 : (minDist <= 32.0 ? 100.0 * (1.0 - ((minDist - 10.0) / 22.0)) : 0.0);
                      _sumaP += pm; _m++; _precision = _sumaP / _m;
                      for (int i = 0; i < _puntos.length; i++) {
                        if ((d.localPosition - _puntos[i]).distance < 32.0) _cubiertos[i] = true;
                      }
                      if (_trazoActual.length % 4 == 0) _huerto.add(TomateAnimado(posicion: d.localPosition));
                    });
                  },
                  onPanEnd: (_) {
                    _audioPlayer.stop();
                    if (_trazoActual.isNotEmpty) { _trazos.add(List.from(_trazoActual)); _trazoActual.clear(); }
                  },
                  child: AnimatedBuilder(
                    animation: _blink,
                    builder: (context, child) => CustomPaint(
                      painter: LetraOPainter(_trazos, _trazoActual, _huerto, _puntos, _cubiertos, _blink.value, 60.0),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red[400],
                  ),
                  onPressed: () => setState(() { _trazos.clear(); _huerto.clear(); _m = 0; _sumaP = 0; _precision = 0; _generarReferencias(); }),
                  icon: const Icon(Icons.delete_sweep, color: Colors.white)),
                const SizedBox(width: 20),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                  ),
                  onPressed: _mostrarDialogo,
                  icon: const Icon(Icons.fact_check, color: Colors.white)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _mostrarDialogo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('¡Asombroso!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('${_precision.toStringAsFixed(0)}% de Precisión', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red[400],
                ),
                onPressed: () { Navigator.pop(context); setState(() { _trazos.clear(); _huerto.clear(); _m = 0; _sumaP = 0; _precision = 0; _generarReferencias(); }); },
                icon: const Icon(Icons.replay, color: Colors.white)),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFb388ff),
                ),
                onPressed: () { Navigator.pop(context); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HLibro1()), (r) => false); },
                icon: const Icon(Icons.home, color: Colors.white)),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green[400],
                ),
                onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const TrazoUMayusculaScreen())); },
                icon: const Icon(Icons.arrow_forward, color: Colors.white)),
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// CLASE CLAVE: LetraOPainter INTEGRADA
// ==========================================
class LetraOPainter extends CustomPainter {
  final List<List<Offset>> trazos;
  final List<Offset> trazoActual;
  final List<TomateAnimado> huerto;
  final List<Offset> puntos;
  final List<bool> cubiertos;
  final double blinkValue;
  final double radio;

  LetraOPainter(
    this.trazos,
    this.trazoActual,
    this.huerto,
    this.puntos,
    this.cubiertos,
    this.blinkValue,
    this.radio,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Configuración del pincel de dibujo del usuario
    final paintTrazo = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;

    // Dibujar trazos guardados anteriormente
    for (var trazo in trazos) {
      for (int i = 0; i < trazo.length - 1; i++) {
        canvas.drawLine(trazo[i], trazo[i + 1], paintTrazo);
      }
    }

    // Dibujar trazo en tiempo real
    for (int i = 0; i < trazoActual.length - 1; i++) {
      canvas.drawLine(trazoActual[i], trazoActual[i + 1], paintTrazo);
    }

    // 2. Dibujar los Tomates Animados en el huerto
    final paintTomate = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (var tomate in huerto) {
      canvas.drawCircle(tomate.posicion, 6.0, paintTomate);
      
      // Detalle verde superior del tomate
      final paintHojita = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tomate.posicion.dx, tomate.posicion.dy - 4), 2.0, paintHojita);
    }

    // 3. Dibujar la guía parpadeante de la letra 'o'
    final paintGuia = Paint()
      ..color = Colors.blue.withOpacity(0.3 + (0.4 * blinkValue))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke;

    // Usamos el centro aproximado configurado en generarReferencias() (165, 240)
    canvas.drawCircle(const Offset(165, 240), radio, paintGuia);
  }

  @override
  bool shouldRepaint(covariant LetraOPainter oldDelegate) {
    return oldDelegate.blinkValue != blinkValue ||
        oldDelegate.trazoActual != trazoActual ||
        oldDelegate.huerto.length != huerto.length;
  }
}