import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Control de audio para tractor y éxito
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/models/log_entry.dart';
import 'package:sabia/pantallas/NyCM/hlilbro1.dart'; 
import 'travoami.dart';

class ZanahoriaAnimada {
  final Offset posicion;
  final double rotacion;
  final double escalaObjetivo;
  double escalaActual = 0.0;

  ZanahoriaAnimada({
    required this.posicion,
    required this.rotacion,
    required this.escalaObjetivo,
  });
}

class TrazoAScreen extends StatefulWidget {
  const TrazoAScreen({super.key});

  @override
  State<TrazoAScreen> createState() => _TrazoAScreenState();
}

class _TrazoAScreenState extends State<TrazoAScreen> with TickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final LogService _logService = LogService();
  final AudioPlayer _audioPlayerTractor = AudioPlayer();
  
  List<List<Offset>> _trazos = [];
  List<Offset> _trazoActual = [];
  List<ZanahoriaAnimada> _huertoZanahorias = [];
  
  Offset? _posicionTractor;
  double _anguloTractor = 0.0;
  bool _estaTocandoTractor = false;

  final Stopwatch _cronometro = Stopwatch();
  int _intentosFallidos = 0;
  bool _completadoExitosamente = false;
  
  // Nuevas variables para el cálculo acumulativo y continuo de precisión real
  double _porcentajePrecision = 0.0;
  double _sumaPrecisionMuestras = 0.0;
  int _totalMuestrasTomadas = 0;

  // Controladores de Animación Guía y Celebración
  late AnimationController _semillasBlinkController;
  late AnimationController _loopZanahoriasController;
  late AnimationController _confetiController; 
  
  int _faseTrazoActual = 0;
  List<Offset> _puntosReferenciaIzquierda = [];
  List<Offset> _puntosReferenciaDerecha = [];
  List<Offset> _puntosReferenciaMedio = [];
  
  List<bool> _cubiertosIzquierda = [];
  List<bool> _cubiertosDerecha = [];
  List<bool> _cubiertosMedio = [];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _generarPuntosReferenciaPorPartes();
    
    _semillasBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _loopZanahoriasController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(() {
        setState(() {
          for (var zanahoria in _huertoZanahorias) {
            if (zanahoria.escalaActual < zanahoria.escalaObjetivo) {
              zanahoria.escalaActual += 0.08;
              if (zanahoria.escalaActual > zanahoria.escalaObjetivo) {
                zanahoria.escalaActual = zanahoria.escalaObjetivo;
              }
            }
          }
        });
      });
    _loopZanahoriasController.repeat();

    _confetiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _voiceService.hablar('¡Conduce el tractor siguiendo el orden de las semillas amarillas!');
  }

  @override
  void dispose() {
    _semillasBlinkController.dispose();
    _loopZanahoriasController.dispose();
    _confetiController.dispose();
    _audioPlayerTractor.dispose();
    _cronometro.stop();
    super.dispose();
  }

  void _generarPuntosReferenciaPorPartes() {
    final centerX = 165.0;
    final topY = 60.0;
    final bottomY = 360.0;
    final leftX = centerX - 110.0;
    final rightX = centerX + 110.0;
    final crossY = 220.0;
    
    _puntosReferenciaIzquierda.clear();
    _puntosReferenciaDerecha.clear();
    _puntosReferenciaMedio.clear();

    for (double t = 0; t <= 1; t += 0.05) {
      _puntosReferenciaIzquierda.add(Offset(centerX - (t * 110), topY + (t * (bottomY - topY))));
      _puntosReferenciaDerecha.add(Offset(centerX + (t * 110), topY + (t * (bottomY - topY))));
    }
    for (double t = 0.15; t <= 0.85; t += 0.08) {
      _puntosReferenciaMedio.add(Offset(leftX + (t * (rightX - leftX)), crossY));
    }

    _cubiertosIzquierda = List.filled(_puntosReferenciaIzquierda.length, false);
    _cubiertosDerecha = List.filled(_puntosReferenciaDerecha.length, false);
    _cubiertosMedio = List.filled(_puntosReferenciaMedio.length, false);
    
    _faseTrazoActual = 0; 
    _posicionTractor = Offset(centerX, topY);
    
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
        _huertoZanahorias.add(
          ZanahoriaAnimada(
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

  // NUEVA LÓGICA CONTINUA: Mide en tiempo real la desviación matemática del trazo del niño
  void _evaluarPrecisionMuestraContinua(Offset posicionTractor) {
    const double maxCanalSombreado = 27.0; // Radio del strokeWidth de 54.0
    double menorDistanciaALineaCentro = double.infinity;

    // Buscar cuál es el punto central teórico más cercano a donde está el tractor actualmente
    for (var p in _puntosReferenciaIzquierda) {
      double d = (posicionTractor - p).distance;
      if (d < menorDistanciaALineaCentro) menorDistanciaALineaCentro = d;
    }
    for (var p in _puntosReferenciaDerecha) {
      double d = (posicionTractor - p).distance;
      if (d < menorDistanciaALineaCentro) menorDistanciaALineaCentro = d;
    }
    for (var p in _puntosReferenciaMedio) {
      double d = (posicionTractor - p).distance;
      if (d < menorDistanciaALineaCentro) menorDistanciaALineaCentro = d;
    }

    // Calcular score de esta muestra específica
    double precisionMuestra = 0.0;
    if (menorDistanciaALineaCentro <= 7.0) {
      precisionMuestra = 100.0; // Casi perfecto en el medio de la guía
    } else if (menorDistanciaALineaCentro <= maxCanalSombreado) {
      // Va disminuyendo linealmente a medida que se desplaza hacia los bordes de la sombra
      precisionMuestra = 100.0 * (1.0 - (menorDistanciaALineaCentro / maxCanalSombreado));
    } else {
      precisionMuestra = 0.0; // Completamente fuera del canal sombreado
    }

    _sumaPrecisionMuestras += precisionMuestra;
    _totalMuestrasTomadas++;

    // Control visual de las semillas guía (avances de fase)
    if (_faseTrazoActual == 0) {
      for (int i = 0; i < _puntosReferenciaIzquierda.length; i++) {
        if ((posicionTractor - _puntosReferenciaIzquierda[i]).distance < maxCanalSombreado) {
          _cubiertosIzquierda[i] = true;
        }
      }
      if (!_cubiertosIzquierda.contains(false)) {
        setState(() => _faseTrazoActual = 1); 
        _voiceService.hablar('¡Bien! Ahora el lado derecho.');
      }
    } else if (_faseTrazoActual == 1) {
      for (int i = 0; i < _puntosReferenciaDerecha.length; i++) {
        if ((posicionTractor - _puntosReferenciaDerecha[i]).distance < maxCanalSombreado) {
          _cubiertosDerecha[i] = true;
        }
      }
      if (!_cubiertosDerecha.contains(false)) {
        setState(() => _faseTrazoActual = 2); 
        _voiceService.hablar('Excelente, ahora cruza el medio.');
      }
    } else if (_faseTrazoActual == 2) {
      for (int i = 0; i < _puntosReferenciaMedio.length; i++) {
        if ((posicionTractor - _puntosReferenciaMedio[i]).distance < maxCanalSombreado) {
          _cubiertosMedio[i] = true;
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
    if (_porcentajePrecision >= 92) {
      estrellasGanadas = 5; // Reservado exclusivamente para trazos impecables
    } else if (_porcentajePrecision >= 75) {
      estrellasGanadas = 4;
    } else if (_porcentajePrecision >= 55) {
      estrellasGanadas = 3;
    } else if (_porcentajePrecision >= 30) {
      estrellasGanadas = 2;
    }

    _confetiController.forward(from: 0.0);
    _voiceService.hablar('A, que se pronuncia "aaa"');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text(
          'Resultado del Trazo', 
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
                    MaterialPageRoute(builder: (context) => const TrazoAMinusculaScreen()),
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
      _huertoZanahorias.clear();
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
        title: const Text('SABIA - Letra A', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), 
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
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
                                  painter: MontessoriPainter(
                                    trazos: _trazos,
                                    trazoActual: _trazoActual,
                                    huerto: _huertoZanahorias,
                                    refIzquierda: _puntosReferenciaIzquierda,
                                    refDerecha: _puntosReferenciaDerecha,
                                    refMedio: _puntosReferenciaMedio,
                                    cubiertosIzquierda: _cubiertosIzquierda,
                                    cubiertosDerecha: _cubiertosDerecha,
                                    cubiertosMedio: _cubiertosMedio,
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

          IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetiController,
              builder: (context, child) {
                if (!_confetiController.isAnimating) return const SizedBox.shrink();
                return CustomPaint(
                  painter: ConfetiPainter(progreso: _confetiController.value),
                  size: Size.infinite,
                );
              },
            ),
          )
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

class MontessoriPainter extends CustomPainter {
  final List<List<Offset>> trazos;
  final List<Offset> trazoActual;
  final List<ZanahoriaAnimada> huerto;
  
  final List<Offset> refIzquierda;
  final List<Offset> refDerecha;
  final List<Offset> refMedio;
  
  final List<bool> cubiertosIzquierda;
  final List<bool> cubiertosDerecha;
  final List<bool> cubiertosMedio;
  
  final int faseActual;
  final double factorParpadeo;

  MontessoriPainter({
    required this.trazos,
    required this.trazoActual,
    required this.huerto,
    required this.refIzquierda,
    required this.refDerecha,
    required this.refMedio,
    required this.cubiertosIzquierda,
    required this.cubiertosDerecha,
    required this.cubiertosMedio,
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
      ..strokeWidth = 54.0;

    final letterPaint = Paint()
      ..color = const Color(0xFFb7e4c7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 44.0;

    final pathLetra = Path()
      ..moveTo(165.0, 60.0)
      ..lineTo(165.0 - 110.0, 360.0)
      ..moveTo(165.0, 60.0)
      ..lineTo(165.0 + 110.0, 360.0);
    
    final pathBarra = Path()
      ..moveTo(165.0 - 110.0 + (0.15 * 220.0), 220.0)
      ..lineTo(165.0 - 110.0 + (0.85 * 220.0), 220.0);

    canvas.drawPath(pathLetra, shadowPaint);
    canvas.drawPath(pathBarra, shadowPaint);
    canvas.drawPath(pathLetra, letterPaint);
    canvas.drawPath(pathBarra, letterPaint);

    final paintTierra = Paint()
      ..color = const Color(0xFF4a3319)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 40.0;

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
      for (int i = 0; i < refIzquierda.length; i++) {
        if (!cubiertosIzquierda[i]) canvas.drawCircle(refIzquierda[i], 5.0 + (factorParpadeo * 3), paintSemilla);
      }
    } else if (faseActual == 1) {
      for (int i = 0; i < refDerecha.length; i++) {
        if (!cubiertosDerecha[i]) canvas.drawCircle(refDerecha[i], 5.0 + (factorParpadeo * 3), paintSemilla);
      }
    } else if (faseActual == 2) {
      for (int i = 0; i < refMedio.length; i++) {
        if (!cubiertosMedio[i]) canvas.drawCircle(refMedio[i], 5.0 + (factorParpadeo * 3), paintSemilla);
      }
    }

    for (var zanahoria in huerto) {
      if (zanahoria.escalaActual > 0.05) {
        canvas.save();
        canvas.translate(zanahoria.posicion.dx, zanahoria.posicion.dy);
        canvas.rotate(zanahoria.rotacion);
        canvas.scale(zanahoria.escalaActual);

        final textPainter = TextPainter(
          text: const TextSpan(text: '🥕', style: TextStyle(fontSize: 24)),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant MontessoriPainter oldDelegate) => true;
}

class ConfetiPainter extends CustomPainter {
  final double progreso;
  ConfetiPainter({required this.progreso});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(12345);
    final paintStar = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      double startX = size.width / 2;
      double startY = size.height / 2;
      
      double angulo = random.nextDouble() * 2 * math.pi;
      double velocidad = 80.0 + random.nextDouble() * 150.0;
      
      double currentX = startX + math.cos(angulo) * velocidad * progreso;
      double currentY = startY + math.sin(angulo) * velocidad * progreso + (progreso * progreso * 60.0); 

      paintStar.color = Colors.primaries[random.nextInt(Colors.primaries.length)].withOpacity(1.0 - progreso);
      canvas.drawCircle(Offset(currentX, currentY), 6.0 * (1.0 - progreso), paintStar);
    }
  }

  @override
  bool shouldRepaint(covariant ConfetiPainter oldDelegate) => true;
}