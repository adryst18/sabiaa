import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/pantallas/NyCM/hlilbro1.dart';
import 'package:sabia/pantallas/NyCM/travoumi.dart';

class MelonAnimado {
  final Offset posicion;
  MelonAnimado({required this.posicion});
}

class TrazoUMayusculaScreen extends StatefulWidget {
  const TrazoUMayusculaScreen({super.key});
  @override
  State<TrazoUMayusculaScreen> createState() => _TrazoUMayusculaScreenState();
}

class _TrazoUMayusculaScreenState extends State<TrazoUMayusculaScreen> with TickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<List<Offset>> _trazos = [];
  List<Offset> _trazoActual = [];
  List<MelonAnimado> _huerto = [];
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
    _voiceService.hablar('¡Llegamos a la letra U mayúscula! Conduce curvando hacia abajo y vuelve a subir.');
  }

  void _generarReferencias() {
    _puntos.clear();
    for (double y = 110; y <= 250; y += 12) { _puntos.add(Offset(100, y)); }
    for (double a = math.pi; a <= 2 * math.pi; a += 0.2) {
      double x = 165 + 65 * math.cos(a);
      double y = 250 + 65 * math.sin(a);
      _puntos.add(Offset(x, y));
    }
    for (double y = 250; y >= 110; y -= 12) { _puntos.add(Offset(230, y)); }
    _cubiertos = List.filled(_puntos.length, false);
  }

  @override
  void dispose() { _blink.dispose(); _audioPlayer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(backgroundColor: const Color(0xFF134074), title: const Text('SABIA - Letra U Mayúscula', style: TextStyle(color: Colors.white))),
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
                      if (_trazoActual.length % 4 == 0) _huerto.add(MelonAnimado(posicion: d.localPosition));
                    });
                  },
                  onPanEnd: (_) {
                    _audioPlayer.stop();
                    if (_trazoActual.isNotEmpty) { _trazos.add(List.from(_trazoActual)); _trazoActual.clear(); }
                  },
                  child: AnimatedBuilder(
                    animation: _blink,
                    builder: (context, child) => CustomPaint(
                      painter: LetraUPainter(_trazos, _trazoActual, _huerto, _puntos, _cubiertos, _blink.value),
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
        title: const Text('¡Espectacular!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const TrazoUMinusculaScreen())); },
                icon: const Icon(Icons.arrow_forward, color: Colors.white)),
            ],
          )
        ],
      ),
    );
  }
}

class LetraUPainter extends CustomPainter {
  final List<List<Offset>> trazos; final List<Offset> trazoActual; final List<MelonAnimado> huerto;
  final List<Offset> puntos; final List<bool> cubiertos; final double blink;
  LetraUPainter(this.trazos, this.trazoActual, this.huerto, this.puntos, this.cubiertos, this.blink);

  @override
  void paint(Canvas canvas, Size size) {
    final sPaint = Paint()..color = const Color(0xFF55a644)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 64.0;
    final lPaint = Paint()..color = const Color(0xFFb7e4c7)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 50.0;

    final base = Path()..moveTo(100, 110)..lineTo(100, 250)..arcTo(Rect.fromCircle(center: const Offset(165, 250), radius: 65), math.pi, -math.pi, false)..lineTo(230, 110);
    canvas.drawPath(base, sPaint); canvas.drawPath(base, lPaint);

    final tPaint = Paint()..color = const Color(0xFF4a3319)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 44.0;
    for (var t in [...trazos, trazoActual]) {
      if (t.length > 1) {
        final path = Path()..moveTo(t.first.dx, t.first.dy);
        for (int i = 1; i < t.length; i++) { path.lineTo(t[i].dx, t[i].dy); }
        canvas.drawPath(path, tPaint);
      }
    }
    final sem = Paint()..color = const Color(0xFFFFEE58).withOpacity(0.4 + (blink * 0.6));
    for (int i = 0; i < puntos.length; i++) { if (!cubiertos[i]) canvas.drawCircle(puntos[i], 5, sem); }

    for (var h in huerto) {
      canvas.save(); canvas.translate(h.posicion.dx, h.posicion.dy);
      TextPainter(text: const TextSpan(text: '🍈', style: TextStyle(fontSize: 22)), textDirection: TextDirection.ltr)..layout()..paint(canvas, const Offset(-11, -11));
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(CustomPainter old) => true;
}