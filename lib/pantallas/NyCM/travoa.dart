import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/models/log_entry.dart';
import 'package:sabia/pantallas/NyCM/hlilbro1.dart'; 
import 'travoami.dart';

class AbejaAnimada {
  final Offset posicion;
  final double rotacion;
  final double escalaObjetivo;
  double escalaActual = 0.0;

  AbejaAnimada({
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
  final AudioPlayer _audioPlayerAbejas = AudioPlayer();
  
  List<List<Offset>> _trazos = [];
  List<Offset> _trazoActual = [];
  List<AbejaAnimada> _abejasHuerto = [];
  
  Offset? _posicionPanal;
  double _anguloPanal = 0.0;
  bool _estaTocando = false;

  final Stopwatch _cronometro = Stopwatch();
  int _intentosFallidos = 0;
  bool _completadoExitosamente = false;
  
  double _porcentajePrecision = 0.0;
  double _sumaPrecisionMuestras = 0.0;
  int _totalMuestrasTomadas = 0;

  late AnimationController _semillasBlinkController;
  late AnimationController _loopAbejasController;
  late AnimationController _confetiController; 
  late AnimationController _demostracionController;
  
  int _faseTrazoActual = 0;
  List<Offset> _puntosReferenciaIzquierda = [];
  List<Offset> _puntosReferenciaDerecha = [];
  List<Offset> _puntosReferenciaMedio = [];
  
  List<bool> _cubiertosIzquierda = [];
  List<bool> _cubiertosDerecha = [];
  List<bool> _cubiertosMedio = [];
  
  bool _mostrandoDemostracion = false;
  List<Offset> _trazoDemostracion = [];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _generarPuntosReferenciaPorPartes();
    
    _semillasBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _loopAbejasController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(() {
        setState(() {
          for (var abeja in _abejasHuerto) {
            if (abeja.escalaActual < abeja.escalaObjetivo) {
              abeja.escalaActual += 0.08;
              if (abeja.escalaActual > abeja.escalaObjetivo) {
                abeja.escalaActual = abeja.escalaObjetivo;
              }
            }
          }
        });
      });
    _loopAbejasController.repeat();

    _confetiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _demostracionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _voiceService.hablar('Toca la letra A y luego sigue el camino de miel');
  }

  @override
  void dispose() {
    _semillasBlinkController.dispose();
    _loopAbejasController.dispose();
    _confetiController.dispose();
    _demostracionController.dispose();
    _audioPlayerAbejas.dispose();
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

    // Línea izquierda
    for (double t = 0; t <= 1; t += 0.05) {
      _puntosReferenciaIzquierda.add(Offset(centerX - (t * 110), topY + (t * (bottomY - topY))));
    }
    
    // Línea derecha
    for (double t = 0; t <= 1; t += 0.05) {
      _puntosReferenciaDerecha.add(Offset(centerX + (t * 110), topY + (t * (bottomY - topY))));
    }
    
    // Línea del medio (horizontal)
    for (double t = 0.15; t <= 0.85; t += 0.08) {
      _puntosReferenciaMedio.add(Offset(leftX + (t * (rightX - leftX)), crossY));
    }

    _cubiertosIzquierda = List.filled(_puntosReferenciaIzquierda.length, false);
    _cubiertosDerecha = List.filled(_puntosReferenciaDerecha.length, false);
    _cubiertosMedio = List.filled(_puntosReferenciaMedio.length, false);
    
    _faseTrazoActual = 0; 
    _posicionPanal = Offset(centerX, topY);
    
    _porcentajePrecision = 0.0;
    _sumaPrecisionMuestras = 0.0;
    _totalMuestrasTomadas = 0;
  }

  Future<void> _reproducirSonidoAbejas() async {
    try {
      await _audioPlayerAbejas.setReleaseMode(ReleaseMode.loop);
      await _audioPlayerAbejas.play(AssetSource('sounds/abeja.mp3'));
    } catch (e) {
      debugPrint('Error cargando audio de abejas: $e');
    }
  }

  Future<void> _detenerSonidoAbejas() async {
    await _audioPlayerAbejas.stop();
  }

  void _pronunciarLetraA() {
    _voiceService.hablar('A');
  }

  Future<void> _iniciarDemostracion() async {
    setState(() {
      _mostrandoDemostracion = true;
      _trazoDemostracion.clear();
    });
    
    // Demostración del trazo izquierdo
    await _demostrarTrazo(_puntosReferenciaIzquierda, 0);
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Demostración del trazo derecho
    await _demostrarTrazo(_puntosReferenciaDerecha, 1);
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Demostración del trazo del medio
    await _demostrarTrazo(_puntosReferenciaMedio, 2);
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Limpiar demostración
    setState(() {
      _mostrandoDemostracion = false;
      _trazoDemostracion.clear();
      _trazos.clear();
      _trazoActual.clear();
      _generarPuntosReferenciaPorPartes();
    });
    
    _voiceService.hablar('Ahora te toca a ti');
  }

  Future<void> _demostrarTrazo(List<Offset> puntos, int fase) async {
    _demostracionController.reset();
    _demostracionController.addListener(() {
      if (mounted) {
        setState(() {
          int indiceActual = (puntos.length * _demostracionController.value).floor();
          _trazoDemostracion = puntos.sublist(0, indiceActual.clamp(0, puntos.length));
        });
      }
    });
    
    await _demostracionController.forward();
    _demostracionController.removeListener(() {});
  }

  void _iniciarNuevoTrazo(Offset puntoInicial) {
    if (_completadoExitosamente || _mostrandoDemostracion) return;
    _reproducirSonidoAbejas();

    if (!_cronometro.isRunning) {
      _cronometro.start();
    }

    setState(() {
      _estaTocando = true;
      _trazoActual = [puntoInicial];
      _posicionPanal = puntoInicial;
    });
  }

  void _actualizarTrazo(Offset puntoActual) {
    if (!_estaTocando || _trazoActual.isEmpty) return;
    
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
        _abejasHuerto.add(
          AbejaAnimada(
            posicion: puntoActual,
            rotacion: (math.Random().nextDouble() * 0.4) - 0.2,
            escalaObjetivo: 1.1,
          ),
        );
      }

      setState(() {
        _posicionPanal = puntoActual;
        _anguloPanal = nuevoAngulo;
      });
    }
  }

  void _evaluarPrecisionMuestraContinua(Offset posicionPanal) {
    const double maxCanalSombreado = 32.0; 
    double menorDistanciaALineaCentro = double.infinity;

    for (var p in _puntosReferenciaIzquierda) {
      double d = (posicionPanal - p).distance;
      if (d < menorDistanciaALineaCentro) menorDistanciaALineaCentro = d;
    }
    for (var p in _puntosReferenciaDerecha) {
      double d = (posicionPanal - p).distance;
      if (d < menorDistanciaALineaCentro) menorDistanciaALineaCentro = d;
    }
    for (var p in _puntosReferenciaMedio) {
      double d = (posicionPanal - p).distance;
      if (d < menorDistanciaALineaCentro) menorDistanciaALineaCentro = d;
    }

    double precisionMuestra = 0.0;
    if (menorDistanciaALineaCentro <= 14.0) {
      precisionMuestra = 100.0; 
    } else if (menorDistanciaALineaCentro <= maxCanalSombreado) {
      precisionMuestra = 100.0 * (1.0 - ((menorDistanciaALineaCentro - 14.0) / (maxCanalSombreado - 14.0)));
    } else {
      precisionMuestra = 0.0; 
    }

    _sumaPrecisionMuestras += precisionMuestra;
    _totalMuestrasTomadas++;

    if (_faseTrazoActual == 0) {
      for (int i = 0; i < _puntosReferenciaIzquierda.length; i++) {
        if ((posicionPanal - _puntosReferenciaIzquierda[i]).distance < maxCanalSombreado) {
          _cubiertosIzquierda[i] = true;
        }
      }
      if (!_cubiertosIzquierda.contains(false)) {
        setState(() => _faseTrazoActual = 1); 
        _voiceService.hablar('¡Bien! Ahora el lado derecho.');
      }
    } else if (_faseTrazoActual == 1) {
      for (int i = 0; i < _puntosReferenciaDerecha.length; i++) {
        if ((posicionPanal - _puntosReferenciaDerecha[i]).distance < maxCanalSombreado) {
          _cubiertosDerecha[i] = true;
        }
      }
      if (!_cubiertosDerecha.contains(false)) {
        setState(() => _faseTrazoActual = 2); 
        _voiceService.hablar('Excelente, ahora cruza el medio.');
      }
    } else if (_faseTrazoActual == 2) {
      for (int i = 0; i < _puntosReferenciaMedio.length; i++) {
        if ((posicionPanal - _puntosReferenciaMedio[i]).distance < maxCanalSombreado) {
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
    _detenerSonidoAbejas();
    if (_trazoActual.isNotEmpty) {
      setState(() {
        _trazos.add(List.from(_trazoActual));
        _trazoActual.clear();
        _estaTocando = false;
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
      _abejasHuerto.clear();
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
              
              // Letra A en la parte superior
              GestureDetector(
                onTap: _pronunciarLetraA,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF59D),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF134074),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Center(
                  child: Container(
                    width: 330,
                    height: 440,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: const Color(0xFFFFF59D), width: 6),
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
                                    abejasHuerto: _abejasHuerto,
                                    refIzquierda: _puntosReferenciaIzquierda,
                                    refDerecha: _puntosReferenciaDerecha,
                                    refMedio: _puntosReferenciaMedio,
                                    cubiertosIzquierda: _cubiertosIzquierda,
                                    cubiertosDerecha: _cubiertosDerecha,
                                    cubiertosMedio: _cubiertosMedio,
                                    faseActual: _faseTrazoActual,
                                    factorParpadeo: _semillasBlinkController.value,
                                    trazosDemostracion: _trazoDemostracion,
                                    mostrandoDemostracion: _mostrandoDemostracion,
                                  ),
                                  size: Size.infinite,
                                );
                              },
                            ),

                            if (_posicionPanal != null && !_mostrandoDemostracion)
                              Positioned(
                                left: _posicionPanal!.dx - 24,
                                top: _posicionPanal!.dy - 24,
                                child: Transform.rotate(
                                  angle: _anguloPanal,
                                  child: AnimatedScale(
                                    scale: _estaTocando ? 1.3 : 1.0,
                                    duration: const Duration(milliseconds: 120),
                                    curve: Curves.easeOutBack,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFD54F),
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)], 
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.hexagon, size: 36, color: Color(0xFF134074)),
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
                    // Botón amarillo de play para demostración
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: const Color(0xFF134074),
                        padding: const EdgeInsets.all(14),
                        fixedSize: const Size(56, 56),
                      ),
                      onPressed: _mostrandoDemostracion ? null : _iniciarDemostracion,
                      icon: Icon(
                        _mostrandoDemostracion ? Icons.hourglass_empty : Icons.play_arrow,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[400], 
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.all(14),
                        fixedSize: const Size(56, 56),
                      ),
                      onPressed: _reiniciarTodo,
                      icon: const Icon(Icons.delete_sweep, size: 28),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[600], 
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.all(14),
                        fixedSize: const Size(56, 56),
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
  final List<AbejaAnimada> abejasHuerto;
  
  final List<Offset> refIzquierda;
  final List<Offset> refDerecha;
  final List<Offset> refMedio;
  
  final List<bool> cubiertosIzquierda;
  final List<bool> cubiertosDerecha;
  final List<bool> cubiertosMedio;
  
  final int faseActual;
  final double factorParpadeo;
  final List<Offset> trazosDemostracion;
  final bool mostrandoDemostracion;

  MontessoriPainter({
    required this.trazos,
    required this.trazoActual,
    required this.abejasHuerto,
    required this.refIzquierda,
    required this.refDerecha,
    required this.refMedio,
    required this.cubiertosIzquierda,
    required this.cubiertosDerecha,
    required this.cubiertosMedio,
    required this.faseActual,
    required this.factorParpadeo,
    required this.trazosDemostracion,
    required this.mostrandoDemostracion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sombreado AMARILLO de la letra (ya no verde)
    final shadowPaint = Paint()
      ..color = const Color(0xFFFFF59D).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 64.0;

    final letterPaint = Paint()
      ..color = const Color(0xFFFFF176)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 50.0;

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

    // Camino de miel (marrón/dorado)
    final paintCaminoMiel = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 44.0;

// Trazos del usuario (Miel base con efecto fluido)
final paintMielBase = Paint()
  ..color = const Color(0xFFD48C22) // Un tono miel dorado/ámbar más vivo
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..strokeWidth = 38.0 // Un poco más grueso para la base de la gota
  // El truco del fluido: desenfocar los bordes para que los puntos cercanos se "fusionen"
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0); 

final paintMielBrillo = Paint()
  ..color = const Color(0xFFFFE082) // Brillo interno amarillo claro/miel fluido
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..strokeWidth = 14.0; // Más delgado, va al centro simulando volumen

// Opcional: Para el borde oscuro de la miel
final paintMielBorde = Paint()
  ..color = const Color(0xFF9E5E00)
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..strokeWidth = 42.0
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

// Función interna para dibujar un Path
void _dibujarCamino(Canvas canvas, List<Offset> puntos) {
  if (puntos.length > 1) {
    final path = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    
    // En lugar de lineTo directo, usamos curvas Bézier (quadraticBezierTo) 
    // para que el trazo de la miel se mueva de forma fluida y no rígida.
    for (int i = 1; i < puntos.length - 1; i++) {
      final xc = (puntos[i].dx + puntos[i + 1].dx) / 2;
      final yc = (puntos[i].dy + puntos[i + 1].dy) / 2;
      path.quadraticBezierTo(puntos[i].dx, puntos[i].dy, xc, yc);
    }
    // Conectar el último punto
    path.lineTo(puntos.last.dx, puntos.last.dy);

    // Dibujamos las capas para generar el volumen de la miel
    canvas.drawPath(path, paintMielBorde);   // 1. Sombra/Borde exterior
    canvas.drawPath(path, paintMielBase);    // 2. Cuerpo de la miel
    canvas.drawPath(path, paintMielBrillo);  // 3. Brillo de reflejo líquido
  }
}

// Renderizar todos los trazos guardados
for (var trazo in trazos) {
  _dibujarCamino(canvas, trazo);
}

// Renderizar el trazo actual en tiempo real
_dibujarCamino(canvas, trazoActual);
    // Trazo de demostración (miel brillante)
    if (mostrandoDemostracion && trazosDemostracion.length > 1) {
      final paintDemostracion = Paint()
        ..color = const Color(0xFFE6B800).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 36.0;

      final pathDemostracion = Path()
        ..moveTo(trazosDemostracion.first.dx, trazosDemostracion.first.dy);
      for (int i = 1; i < trazosDemostracion.length; i++) {
        pathDemostracion.lineTo(trazosDemostracion[i].dx, trazosDemostracion[i].dy);
      }
      canvas.drawPath(pathDemostracion, paintDemostracion);
    }

    // Semillas amarillas parpadeantes (solo las no cubiertas)
    final paintSemilla = Paint()
      ..color = const Color.fromARGB(255, 202, 142, 12).withOpacity(0.4 + (factorParpadeo * 0.6))
      ..style = PaintingStyle.fill;

    if (faseActual == 0) {
      for (int i = 0; i < refIzquierda.length; i++) {
        if (!cubiertosIzquierda[i]) {
          canvas.drawCircle(refIzquierda[i], 5.0 + (factorParpadeo * 3), paintSemilla);
        }
      }
    } else if (faseActual == 1) {
      for (int i = 0; i < refDerecha.length; i++) {
        if (!cubiertosDerecha[i]) {
          canvas.drawCircle(refDerecha[i], 5.0 + (factorParpadeo * 3), paintSemilla);
        }
      }
    } else if (faseActual == 2) {
      for (int i = 0; i < refMedio.length; i++) {
        if (!cubiertosMedio[i]) {
          canvas.drawCircle(refMedio[i], 5.0 + (factorParpadeo * 3), paintSemilla);
        }
      }
    }

    // Abejas en el huerto (reemplazan a las zanahorias)
    for (var abeja in abejasHuerto) {
      if (abeja.escalaActual > 0.05) {
        canvas.save();
        canvas.translate(abeja.posicion.dx, abeja.posicion.dy);
        canvas.rotate(abeja.rotacion);
        canvas.scale(abeja.escalaActual);

        final textPainter = TextPainter(
          text: const TextSpan(text: '🐝', style: TextStyle(fontSize: 24)),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }
    }
  }

  void _drawDashedLine(Canvas canvas, List<Offset> puntos, Paint paint) {
    if (puntos.length < 2) return;
    
    for (int i = 0; i < puntos.length - 1; i += 2) {
      canvas.drawLine(puntos[i], puntos[i + 1], paint);
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