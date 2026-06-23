import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/pantallas/NyCM/hlilbro1.dart';
import 'package:sabia/pantallas/NyCM/travoo.dart';

class JicamaAnimada {
  final Offset posicion;
  final double rotacion;
  final double escalaObjetivo;
  double escalaActual = 0.0;

  JicamaAnimada({
    required this.posicion,
    required this.rotacion,
    required this.escalaObjetivo,
  });
}

class TrazoIMinusculaScreen extends StatefulWidget {
  const TrazoIMinusculaScreen({super.key});

  @override
  State<TrazoIMinusculaScreen> createState() => _TrazoIMinusculaScreenState();
}

class _TrazoIMinusculaScreenState extends State<TrazoIMinusculaScreen> with TickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final AudioPlayer _audioPlayerTractor = AudioPlayer();
  final AudioPlayer _audioPlayerLetra = AudioPlayer();
  
  List<List<Offset>> _trazos = [];
  List<Offset> _trazoActual = [];
  List<JicamaAnimada> _huertoJicamas = [];
  
  Offset? _posicionTractor;
  double _anguloTractor = 0.0;
  bool _estaTocandoTractor = false;

  final Stopwatch _cronometro = Stopwatch();
  int _intentosFallidos = 0;
  bool _completadoExitosamente = false;
  
  double _porcentajePrecision = 0.0;
  double _sumaPrecisionMuestras = 0.0;
  int _totalMuestrasTomadas = 0;

  late AnimationController _semillasBlinkController;
  late AnimationController _loopJicamasController;
  
  int _faseTrazoActual = 0;
  
  List<Offset> _puntosReferenciaPalito = [];
  List<Offset> _puntosReferenciaPunto = [];
  
  List<bool> _cubiertosPalito = [];
  List<bool> _cubiertosPunto = [];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _generarPuntosReferenciaPorPartes();
    
    _semillasBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _loopJicamasController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(() {
        setState(() {
          for (var jicama in _huertoJicamas) {
            if (jicama.escalaActual < jicama.escalaObjetivo) {
              jicama.escalaActual += 0.08;
              if (jicama.escalaActual > jicama.escalaObjetivo) {
                jicama.escalaActual = jicama.escalaObjetivo;
              }
            }
          }
        });
      });
    _loopJicamasController.repeat();

    _voiceService.hablar('¡A sembrar la i minúscula! Dibuja el palito hacia abajo y luego coloca el punto arriba.');
  }

  @override
  void dispose() {
    _semillasBlinkController.dispose();
    _loopJicamasController.dispose();
    _audioPlayerTractor.dispose();
    _audioPlayerLetra.dispose();
    _cronometro.stop();
    super.dispose();
  }

  void _generarPuntosReferenciaPorPartes() {
    _puntosReferenciaPalito.clear();
    _puntosReferenciaPunto.clear();

    // 1. Línea corta recta vertical (palito)
    for (double y = 210; y <= 340; y += 12) {
      _puntosReferenciaPalito.add(Offset(165, y));
    }

    // 2. Punto flotante superior
    _puntosReferenciaPunto.add(const Offset(165, 145));

    _cubiertosPalito = List.filled(_puntosReferenciaPalito.length, false);
    _cubiertosPunto = List.filled(_puntosReferenciaPunto.length, false);
    
    _faseTrazoActual = 0; 
    _posicionTractor = _puntosReferenciaPalito.first;
    
    _porcentajePrecision = 0.0;
    _sumaPrecisionMuestras = 0.0;
    _totalMuestrasTomadas = 0;
  }

  Future<void> _encenderMotorTractor() async {
    try {
      await _audioPlayerTractor.setReleaseMode(ReleaseMode.loop);
      await _audioPlayerTractor.play(AssetSource('sounds/tractor.mp3'));
    } catch (e) {
      debugPrint('Error cargando audio del tractor: $e');
    }
  }

  Future<void> _apagarMotorTractor() async {
    await _audioPlayerTractor.stop();
  }

  Future<void> _reproducirSonidoLetra() async {
    try {
      await _audioPlayerLetra.play(AssetSource('sounds/i.mp3'));
    } catch (e) {
      debugPrint('Error cargando audio de la letra i: $e');
    }
  }

  void _iniciarNuevoTrazo(Offset puntoInicial) {
    if (_completadoExitosamente) return;
    _encenderMotorTractor();

    if (!_cronometro.isRunning) {
      _cronometro.start();
    }

    setState(() {
      _estaTocandoTractor = true;
      _trazoActual = [puntoInicial];
      _posicionTractor = puntoInicial;
    });
  }

  void _actualizarTrazo(Offset puntoActual) {
    if (!_estaTocandoTractor || _trazoActual.isEmpty) return;
    
    Offset puntoAnterior = _trazoActual.last;
    double distancia = (puntoActual - puntoAnterior).distance;

    if (distancia > 6) {
      double nuevoAngulo = math.atan2(
        puntoActual.dy - puntoAnterior.dy,
        puntoActual.dx - puntoAnterior.dx,
      );

      _trazoActual.add(puntoActual);
      _evaluarPrecisionMuestraContinua(puntoActual);

      if (_trazoActual.length % 3 == 0) {
        _huertoJicamas.add(
          JicamaAnimada(
            posicion: puntoActual,
            rotacion: (math.Random().nextDouble() * 0.4) - 0.2,
            escalaObjetivo: 1.1,
          ),
        );
      }

      setState(() {
        _posicionTractor = puntoActual;
        _anguloTractor = nuevoAngulo;
      });
    }
  }

  void _evaluarPrecisionMuestraContinua(Offset posicionTractor) {
    const double maxCanalSombreado = 32.0; 
    double menorDistanciaALineaCentro = double.infinity;

    for (var p in _puntosReferenciaPalito) {
      double d = (posicionTractor - p).distance;
      if (d < menorDistanciaALineaCentro) menorDistanciaALineaCentro = d;
    }
    for (var p in _puntosReferenciaPunto) {
      double d = (posicionTractor - p).distance;
      if (d < menorDistanciaALineaCentro) menorDistanciaALineaCentro = d;
    }

    double precisionMuestra = 0.0;
    if (menorDistanciaALineaCentro <= 10.0) {
      precisionMuestra = 100.0; 
    } else if (menorDistanciaALineaCentro <= maxCanalSombreado) {
      precisionMuestra = 100.0 * (1.0 - ((menorDistanciaALineaCentro - 10.0) / (maxCanalSombreado - 10.0)));
    } else {
      precisionMuestra = 0.0; 
    }

    _sumaPrecisionMuestras += precisionMuestra;
    _totalMuestrasTomadas++;

    if (_faseTrazoActual == 0) {
      for (int i = 0; i < _puntosReferenciaPalito.length; i++) {
        if ((posicionTractor - _puntosReferenciaPalito[i]).distance < maxCanalSombreado) {
          _cubiertosPalito[i] = true;
        }
      }
      if (!_cubiertosPalito.contains(false)) {
        setState(() => _faseTrazoActual = 1); 
        _voiceService.hablar('¡Perfecto! Ahora coloca el punto arriba.');
      }
    } else if (_faseTrazoActual == 1) {
      for (int i = 0; i < _puntosReferenciaPunto.length; i++) {
        if ((posicionTractor - _puntosReferenciaPunto[i]).distance < maxCanalSombreado) {
          _cubiertosPunto[i] = true;
        }
      }
    }

    setState(() {
      _porcentajePrecision = _totalMuestrasTomadas > 0 
          ? (_sumaPrecisionMuestras / _totalMuestrasTomadas) 
          : 0.0;
    });
  }

  void _finalizarTrazoActual() {
    _apagarMotorTractor();
    if (_trazoActual.isNotEmpty) {
      setState(() {
        _trazos.add(List.from(_trazoActual));
        _trazoActual.clear();
        _estaTocandoTractor = false;
      });
      if (!_completadoExitosamente && _porcentajePrecision < 15) {
        _intentosFallidos++;
      }
    }
  }

  void _ejecutarCalificacionYVentana() {
    _cronometro.stop();
    setState(() {
      _completadoExitosamente = true;
    });

    int estrellasGanadas = 1;
    if (_porcentajePrecision >= 90) {
      estrellasGanadas = 5;
    } else if (_porcentajePrecision >= 75) {
      estrellasGanadas = 4;
    } else if (_porcentajePrecision >= 55) {
      estrellasGanadas = 3;
    } else if (_porcentajePrecision >= 30) {
      estrellasGanadas = 2;
    }

    _reproducirSonidoLetra();
    _voiceService.hablar('¡Felicidades, lograste escribir la i minúscula!');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text(
          '¡Excelente Trabajo!', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF134074)),
          textAlign: TextAlign.center
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_porcentajePrecision.toStringAsFixed(0)}% de Precisión', 
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: _porcentajePrecision >= 75 ? Colors.green : Colors.orange
              )
            ),
            const SizedBox(height: 16),
            SecuencialEstrellasWidget(cantidadEstrellas: estrellasGanadas),
            const SizedBox(height: 16),
            Text('Tiempo empleado: ${_cronometro.elapsed.inSeconds}s', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _reiniciarTodo();
                },
                icon: const Icon(Icons.replay, size: 28),
              ),

              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFb388ff),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HLibro1()),
                  );
                },
                icon: const Icon(Icons.home, size: 28),
              ),

              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF4caf50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TrazoOMayusculaScreen()),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _reiniciarTodo() {
    setState(() {
      _trazos.clear();
      _trazoActual.clear();
      _huertoJicamas.clear();
      _completadoExitosamente = false;
      _intentosFallidos = 0;
      _cronometro.reset();
      _generarPuntosReferenciaPorPartes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF134074),
        title: const Text('Letra i', style: TextStyle(color: Colors.white)), 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), 
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLiveStatWidget(Icons.ads_click, 'Precisión Real', '${_porcentajePrecision.toStringAsFixed(0)}%', Colors.purple),
                _buildLiveStatWidget(Icons.refresh, 'Intentos', '$_intentosFallidos', Colors.orange),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: Container(
                width: 330,
                height: 440,
                decoration: BoxDecoration(
                  color: const Color(0xFF99d98c),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFd8f3dc), width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: GestureDetector(
                    onPanStart: (details) => _iniciarNuevoTrazo(details.localPosition),
                    onPanUpdate: (details) => _actualizarTrazo(details.localPosition),
                    onPanEnd: (_) => _finalizarTrazoActual(),
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _semillasBlinkController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _MontessoriPainter(
                                trazos: _trazos,
                                trazoActual: _trazoActual,
                                huerto: _huertoJicamas,
                                refPalito: _puntosReferenciaPalito,
                                refPunto: _puntosReferenciaPunto,
                                cubiertosPalito: _cubiertosPalito,
                                cubiertosPunto: _cubiertosPunto,
                                faseActual: _faseTrazoActual,
                                factorParpadeo: _semillasBlinkController.value,
                              ),
                              size: Size.infinite,
                            );
                          },
                        ),

                        if (_posicionTractor != null)
                          Positioned(
                            left: _posicionTractor!.dx - 28,
                            top: _posicionTractor!.dy - 28,
                            child: Transform.rotate(
                              angle: _anguloTractor,
                              child: AnimatedScale(
                                scale: _estaTocandoTractor ? 1.3 : 1.0,
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOutBack,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E88E5),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)], 
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.agriculture, size: 38, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red[400], 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.all(14)
                  ),
                  onPressed: _reiniciarTodo,
                  icon: const Icon(Icons.delete_sweep, size: 28),
                ),
                const SizedBox(width: 20),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue[600], 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.all(14)
                  ),
                  onPressed: _ejecutarCalificacionYVentana,
                  icon: const Icon(Icons.fact_check, size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatWidget(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

class _MontessoriPainter extends CustomPainter {
  final List<List<Offset>> trazos;
  final List<Offset> trazoActual;
  final List<JicamaAnimada> huerto;
  
  final List<Offset> refPalito;
  final List<Offset> refPunto;
  
  final List<bool> cubiertosPalito;
  final List<bool> cubiertosPunto;
  
  final int faseActual;
  final double factorParpadeo;

  _MontessoriPainter({
    required this.trazos,
    required this.trazoActual,
    required this.huerto,
    required this.refPalito,
    required this.refPunto,
    required this.cubiertosPalito,
    required this.cubiertosPunto,
    required this.faseActual,
    required this.factorParpadeo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = const Color(0xFF55a644)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 64.0;

    final letterPaint = Paint()
      ..color = const Color(0xFFb7e4c7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 50.0;

    // Dibujar palito vertical
    canvas.drawLine(const Offset(165, 210), const Offset(165, 340), shadowPaint);
    canvas.drawLine(const Offset(165, 210), const Offset(165, 340), letterPaint);
    
    // Dibujar punto superior
    canvas.drawCircle(const Offset(165, 145), 12.0, shadowPaint);
    canvas.drawCircle(const Offset(165, 145), 4.0, letterPaint);

    final paintTierra = Paint()
      ..color = const Color(0xFF4a3319)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 44.0;

    for (var trazo in trazos) {
      if (trazo.length > 1) {
        final path = Path()..moveTo(trazo.first.dx, trazo.first.dy);
        for (int i = 1; i < trazo.length; i++) {
          path.lineTo(trazo[i].dx, trazo[i].dy);
        }
        canvas.drawPath(path, paintTierra);
      }
    }

    if (trazoActual.length > 1) {
      final pathActual = Path()..moveTo(trazoActual.first.dx, trazoActual.first.dy);
      for (int i = 1; i < trazoActual.length; i++) {
        pathActual.lineTo(trazoActual[i].dx, trazoActual[i].dy);
      }
      canvas.drawPath(pathActual, paintTierra);
    }

    final paintSemilla = Paint()
      ..color = const Color(0xFFFFEE58).withOpacity(0.4 + (factorParpadeo * 0.6))
      ..style = PaintingStyle.fill;

    if (faseActual == 0) {
      for (int i = 0; i < refPalito.length; i++) {
        if (!cubiertosPalito[i]) canvas.drawCircle(refPalito[i], 5.0 + (factorParpadeo * 3), paintSemilla);
      }
    } else if (faseActual == 1) {
      for (int i = 0; i < refPunto.length; i++) {
        if (!cubiertosPunto[i]) canvas.drawCircle(refPunto[i], 5.0 + (factorParpadeo * 3), paintSemilla);
      }
    }

    for (var jicama in huerto) {
      if (jicama.escalaActual > 0.05) {
        canvas.save();
        canvas.translate(jicama.posicion.dx, jicama.posicion.dy);
        canvas.rotate(jicama.rotacion);
        canvas.scale(jicama.escalaActual);

        final textPainter = TextPainter(
          text: const TextSpan(text: '🌱', style: TextStyle(fontSize: 24)),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MontessoriPainter oldDelegate) => true;
}

class SecuencialEstrellasWidget extends StatefulWidget {
  final int cantidadEstrellas;
  const SecuencialEstrellasWidget({super.key, required this.cantidadEstrellas});

  @override
  State<SecuencialEstrellasWidget> createState() => _SecuencialEstrellasWidgetState();
}

class _SecuencialEstrellasWidgetState extends State<SecuencialEstrellasWidget> {
  final List<double> _escalasEstrellas = [0.0, 0.0, 0.0, 0.0, 0.0];
  final AudioPlayer _audioPlayerEfecto = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _reproducirEstrellasConRetraso();
  }

  @override
  void dispose() {
    _audioPlayerEfecto.dispose();
    super.dispose();
  }

  void _reproducirEstrellasConRetraso() async {
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      
      setState(() {
        _escalasEstrellas[i] = 1.0;
      });

      if (i < widget.cantidadEstrellas) {
        try {
          await _audioPlayerEfecto.play(AssetSource('sounds/bien.mp3'), mode: PlayerMode.lowLatency);
        } catch (e) {
          debugPrint('Error reproduciendo sonido bien.mp3: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        bool esGanada = index < widget.cantidadEstrellas;
        return AnimatedScale(
          scale: _escalasEstrellas[index],
          duration: const Duration(milliseconds: 600),
          curve: Curves.bounceOut, 
          child: Icon(
            Icons.star,
            color: esGanada ? Colors.amber : Colors.grey[300],
            size: 44,
          ),
        );
      }),
    );
  }
}