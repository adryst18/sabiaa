import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/pantallas/NyCM/hlilbro1.dart';
import 'package:sabia/pantallas/NyCM/travou.dart';

class TomateAnimado {
  final Offset posicion;
  final double rotacion;
  final double escalaObjetivo;
  double escalaActual = 0.0;

  TomateAnimado({
    required this.posicion,
    required this.rotacion,
    required this.escalaObjetivo,
  });
}

class TrazoOMinusculaScreen extends StatefulWidget {
  const TrazoOMinusculaScreen({super.key});

  @override
  State<TrazoOMinusculaScreen> createState() => _TrazoOMinusculaScreenState();
}

class _TrazoOMinusculaScreenState extends State<TrazoOMinusculaScreen> with TickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final AudioPlayer _audioPlayerTractor = AudioPlayer();
  final AudioPlayer _audioPlayerLetra = AudioPlayer();
  
  List<List<Offset>> _trazos = [];
  List<Offset> _trazoActual = [];
  List<TomateAnimado> _huertoTomates = [];
  
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
  late AnimationController _loopTomatesController;
  
  int _faseTrazoActual = 0;
  
  List<Offset> _puntosReferenciaCirculo = [];
  List<bool> _cubiertosCirculo = [];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _generarPuntosReferenciaPorPartes();
    
    _semillasBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _loopTomatesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(() {
        setState(() {
          for (var tomate in _huertoTomates) {
            if (tomate.escalaActual < tomate.escalaObjetivo) {
              tomate.escalaActual += 0.08;
              if (tomate.escalaActual > tomate.escalaObjetivo) {
                tomate.escalaActual = tomate.escalaObjetivo;
              }
            }
          }
        });
      });
    _loopTomatesController.repeat();

    _voiceService.hablar('¡Ahora la o minúscula! Traza este pequeño círculo.');
  }

  @override
  void dispose() {
    _semillasBlinkController.dispose();
    _loopTomatesController.dispose();
    _audioPlayerTractor.dispose();
    _audioPlayerLetra.dispose();
    _cronometro.stop();
    super.dispose();
  }

  void _generarPuntosReferenciaPorPartes() {
    _puntosReferenciaCirculo.clear();

    // Círculo completo de la o minúscula (radio 60, centro en 165, 240)
    for (double a = 0; a <= 2 * math.pi; a += 0.25) {
      double x = 165 + 60 * math.cos(a);
      double y = 240 + 60 * math.sin(a);
      _puntosReferenciaCirculo.add(Offset(x, y));
    }

    _cubiertosCirculo = List.filled(_puntosReferenciaCirculo.length, false);
    
    _faseTrazoActual = 0; 
    _posicionTractor = _puntosReferenciaCirculo.first;
    
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
      await _audioPlayerLetra.play(AssetSource('sounds/o.mp3'));
    } catch (e) {
      debugPrint('Error cargando audio de la letra o: $e');
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
        _huertoTomates.add(
          TomateAnimado(
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

    for (var p in _puntosReferenciaCirculo) {
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
      for (int i = 0; i < _puntosReferenciaCirculo.length; i++) {
        if ((posicionTractor - _puntosReferenciaCirculo[i]).distance < maxCanalSombreado) {
          _cubiertosCirculo[i] = true;
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
    _voiceService.hablar('¡Felicidades, lograste escribir la o minúscula!');

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
                    MaterialPageRoute(builder: (context) => const TrazoUMayusculaScreen()),
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
      _huertoTomates.clear();
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
        title: const Text('Letra o', style: TextStyle(color: Colors.white)), 
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
                                huerto: _huertoTomates,
                                refCirculo: _puntosReferenciaCirculo,
                                cubiertosCirculo: _cubiertosCirculo,
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
  final List<TomateAnimado> huerto;
  
  final List<Offset> refCirculo;
  
  final List<bool> cubiertosCirculo;
  
  final int faseActual;
  final double factorParpadeo;

  _MontessoriPainter({
    required this.trazos,
    required this.trazoActual,
    required this.huerto,
    required this.refCirculo,
    required this.cubiertosCirculo,
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

    // Dibujar círculo de la o minúscula (radio 60, centro en 165, 240)
    canvas.drawCircle(const Offset(165, 240), 60.0, shadowPaint);
    canvas.drawCircle(const Offset(165, 240), 60.0, letterPaint);

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
      for (int i = 0; i < refCirculo.length; i++) {
        if (!cubiertosCirculo[i]) canvas.drawCircle(refCirculo[i], 5.0 + (factorParpadeo * 3), paintSemilla);
      }
    }

    for (var tomate in huerto) {
      if (tomate.escalaActual > 0.05) {
        canvas.save();
        canvas.translate(tomate.posicion.dx, tomate.posicion.dy);
        canvas.rotate(tomate.rotacion);
        canvas.scale(tomate.escalaActual);

        final textPainter = TextPainter(
          text: const TextSpan(text: '🍅', style: TextStyle(fontSize: 24)),
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