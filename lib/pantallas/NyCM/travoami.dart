import 'package:flutter/material.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/models/log_entry.dart';
import 'dart:math';

class TrazoAMinusculaScreen extends StatefulWidget {
  const TrazoAMinusculaScreen({super.key});

  @override
  State<TrazoAMinusculaScreen> createState() => _TrazoAMinusculaScreenState();
}

class _TrazoAMinusculaScreenState extends State<TrazoAMinusculaScreen> with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final LogService _logService = LogService();
  
  // Lista de trazos independientes (cada trazo es una lista de puntos)
  List<List<Offset>> _trazos = [];
  
  // Trazo actual que se está dibujando
  List<Offset> _trazoActual = [];
  
  // Control de estado
  bool _mostrarReferencia = true;
  int _intentos = 0;
  double _calificacion = 0;
  bool _mostrarDialogoCalificacion = false;
  
  // Color seleccionado para el trazo
  Color _colorTrazo = const Color(0xFF38b000);
  
  // Colores disponibles en la paleta
  final List<Color> _coloresPaleta = [
    const Color(0xFF38b000), // Verde
    Colors.blue,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.pink,
  ];
  
  // Control de animación para las estrellas
  late AnimationController _starAnimationController;
  List<Animation<double>> _starAnimations = [];
  
  // Puntos de referencia para la letra a minúscula
  List<Offset> _puntosReferencia = [];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _generarPuntosReferenciaA();
    
    _starAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _logService.addLog(
      type: LogType.navegacion,
      message: 'Pantalla de trazado de letra a minúscula cargada',
      details: {'pantalla': 'TrazoAMinusculaScreen'},
    );
  }

  void _generarPuntosReferenciaA() {
    // Generar puntos de referencia para una a minúscula perfecta
    // La a minúscula tiene forma de círculo con una línea vertical en el lado DERECHO, PEGADA POR FUERA
    final centerX = 150.0;
    final centerY = 150.0;
    final radius = 55.0; // Reducido un poco para dar espacio al palito
    final stemX = centerX + radius; // El palito empieza donde termina el círculo (por fuera)
    final stemTopY = centerY - radius * 0.4; // El palito comienza más arriba
    final stemBottomY = centerY + radius * 0.6; // El palito termina más abajo que el círculo
    
    // Círculo principal (parte redonda de la a)
    for (double angle = 0; angle <= 2 * pi; angle += 0.05) {
      double x = centerX + radius * cos(angle);
      double y = centerY + radius * sin(angle);
      _puntosReferencia.add(Offset(x, y));
    }
    
    // Línea vertical (palo de la a) - PEGADO POR FUERA
    for (double t = 0; t <= 1; t += 0.03) {
      double x = stemX;
      double y = stemTopY + t * (stemBottomY - stemTopY);
      _puntosReferencia.add(Offset(x, y));
    }
  }

  void _iniciarNuevoTrazo(Offset puntoInicial) {
    setState(() {
      _trazoActual = [puntoInicial];
    });
  }

  void _actualizarTrazo(Offset punto) {
    if (_trazoActual.isEmpty) return;
    
    // Agregar el punto y actualizar la UI inmediatamente
    _trazoActual.add(punto);
    setState(() {});
  }

  void _finalizarTrazoActual() {
    if (_trazoActual.isNotEmpty && _trazoActual.length > 1) {
      setState(() {
        _trazos.add(List.from(_trazoActual));
        _trazoActual.clear();
      });
    } else if (_trazoActual.isNotEmpty) {
      setState(() {
        _trazos.add(List.from(_trazoActual));
        _trazoActual.clear();
      });
    }
  }

  void _reiniciarTrazo() {
    setState(() {
      _trazos.clear();
      _trazoActual.clear();
      _mostrarDialogoCalificacion = false;
      _calificacion = 0;
    });
  }

  List<Offset> _obtenerTodosLosPuntos() {
    List<Offset> todosLosPuntos = [];
    for (var trazo in _trazos) {
      todosLosPuntos.addAll(trazo);
    }
    if (_trazoActual.isNotEmpty) {
      todosLosPuntos.addAll(_trazoActual);
    }
    return todosLosPuntos;
  }

  void _evaluarTrazo() {
    final todosLosPuntos = _obtenerTodosLosPuntos();
    
    if (todosLosPuntos.length < 30) {
      _voiceService.hablar('Dibuja la letra a minúscula primero. Haz uno o varios trazos para formar la letra.');
      return;
    }
    
    double calificacion = _calcularSimilitud(todosLosPuntos);
    
    setState(() {
      _calificacion = calificacion;
      _mostrarDialogoCalificacion = true;
    });
    
    _mostrarDialogoCalificacionConVoz(calificacion);
    _intentos++;
    
    _logService.addLog(
      type: LogType.navegacion,
      message: 'Trazo de letra a minúscula calificado',
      details: {'calificacion': calificacion, 'intentos': _intentos, 'trazos': _trazos.length},
    );
  }

  void _mostrarDialogoCalificacionConVoz(double calificacion) {
    double estrellasObtenidas = _calcularEstrellas(calificacion);
    String mensaje = _obtenerMensajeCalificacion(calificacion, estrellasObtenidas);
    
    _voiceService.hablar(mensaje);
    
    _starAnimations.clear();
    for (int i = 0; i < 5; i++) {
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _starAnimationController,
          curve: Interval(i * 0.15, 1.0, curve: Curves.elasticOut),
        ),
      );
      _starAnimations.add(animation);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _starAnimationController.forward(from: 0.0);
            });
            
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38b000).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              calificacion >= 70 ? Icons.celebration : Icons.emoji_events,
                              size: 48 * value,
                              color: calificacion >= 70 ? const Color(0xFF38b000) : const Color(0xFFFFB74D),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      calificacion >= 70 ? '¡Excelente trabajo!' : '¡Sigue practicando!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF134074),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      child: Text(
                        _obtenerMensajeBreve(calificacion),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return _buildAnimatedStar(
                          index, 
                          estrellasObtenidas, 
                          _starAnimations.isNotEmpty && index < _starAnimations.length 
                              ? _starAnimations[index] 
                              : null
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: calificacion),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF134074).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${value.toInt()}% de precisión',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF134074),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _voiceService.detener();
                              Navigator.pop(context);
                              _reiniciarTrazo();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB74D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, size: 20),
                                SizedBox(width: 8),
                                Text('Reintentar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _voiceService.detener();
                              Navigator.pop(context);
                              // TODO: Navegar a TrazoEScreen cuando esté disponible
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(builder: (context) => const TrazoEScreen()),
                              // );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Próximamente: Lección de la letra E'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9252e3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward, size: 20),
                                SizedBox(width: 8),
                                Text('Siguiente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedStar(int index, double estrellasObtenidas, Animation<double>? animation) {
    double starValue = (estrellasObtenidas - index).clamp(0.0, 1.0);
    
    if (animation != null) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          double currentValue = starValue * animation.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildStarWithValue(currentValue),
          );
        },
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _buildStarWithValue(starValue),
      );
    }
  }

  Widget _buildStarWithValue(double value) {
    if (value >= 0.95) {
      return TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Stack(
              children: [
                Icon(Icons.star_border, size: 44, color: Colors.grey[300]),
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFB74D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: Icon(Icons.star, size: 44, color: Colors.white),
                ),
              ],
            ),
          );
        },
      );
    } else if (value >= 0.45) {
      return TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Stack(
              children: [
                Icon(Icons.star_border, size: 44, color: Colors.grey[300]),
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFB74D)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.0, 0.5, 0.5],
                    ).createShader(bounds);
                  },
                  child: Icon(Icons.star, size: 44, color: Colors.white),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Icon(Icons.star_border, size: 44, color: Colors.grey[300]),
          );
        },
      );
    }
  }

  double _calcularEstrellas(double calificacion) {
    if (calificacion >= 95) return 5.0;
    if (calificacion >= 85) return 4.5;
    if (calificacion >= 75) return 4.0;
    if (calificacion >= 65) return 3.5;
    if (calificacion >= 55) return 3.0;
    if (calificacion >= 45) return 2.5;
    if (calificacion >= 35) return 2.0;
    if (calificacion >= 25) return 1.5;
    if (calificacion >= 15) return 1.0;
    if (calificacion >= 5) return 0.5;
    return 0.0;
  }

  String _obtenerMensajeCalificacion(double calificacion, double estrellas) {
    int estrellasEnteras = estrellas.floor();
    String textoEstrellas = '';
    
    if (estrellasEnteras == 5) {
      textoEstrellas = 'cinco estrellas';
    } else if (estrellasEnteras == 4) {
      textoEstrellas = estrellas >= 4.5 ? 'cuatro estrellas y media' : 'cuatro estrellas';
    } else if (estrellasEnteras == 3) {
      textoEstrellas = estrellas >= 3.5 ? 'tres estrellas y media' : 'tres estrellas';
    } else if (estrellasEnteras == 2) {
      textoEstrellas = estrellas >= 2.5 ? 'dos estrellas y media' : 'dos estrellas';
    } else if (estrellasEnteras == 1) {
      textoEstrellas = estrellas >= 1.5 ? 'una estrella y media' : 'una estrella';
    } else if (estrellasEnteras == 0) {
      textoEstrellas = estrellas >= 0.5 ? 'media estrella' : 'cero estrellas';
    }
    
    return 'Felicidades obtuviste un ${calificacion.toInt()}% de acierto en tu trazo. '
           'Obtuviste $textoEstrellas de 5. '
           'Continúa con tu progreso, pulsa el botón amarillo de la izquierda para reintentar '
           'o el botón morado de la derecha para continuar a la siguiente lección.';
  }

  String _obtenerMensajeBreve(double calificacion) {
    if (calificacion >= 90) return '¡Perfecto! Dominas la letra a minúscula';
    if (calificacion >= 70) return '¡Muy bien! Sigue así';
    if (calificacion >= 50) return 'Buen intento, puedes mejorar';
    if (calificacion >= 30) return 'Sigue practicando';
    return 'Vamos, tú puedes lograrlo';
  }

  double _calcularSimilitud(List<Offset> puntos) {
    if (_puntosReferencia.isEmpty || puntos.isEmpty) return 0;
    
    List<Offset> puntosNormalizados = _normalizarPuntos(puntos);
    List<Offset> referenciasNormalizadas = _normalizarPuntos(_puntosReferencia);
    
    double distanciaTotal = 0;
    int puntosEvaluados = 0;
    
    for (var puntoUsuario in puntosNormalizados) {
      double minDistancia = double.infinity;
      for (var puntoRef in referenciasNormalizadas) {
        double distancia = _calcularDistancia(puntoUsuario, puntoRef);
        if (distancia < minDistancia) minDistancia = distancia;
      }
      distanciaTotal += minDistancia;
      puntosEvaluados++;
    }
    
    int puntosCubiertos = 0;
    for (var puntoRef in referenciasNormalizadas) {
      double minDistancia = double.infinity;
      for (var puntoUsuario in puntosNormalizados) {
        double distancia = _calcularDistancia(puntoUsuario, puntoRef);
        if (distancia < minDistancia) minDistancia = distancia;
      }
      if (minDistancia < 30) puntosCubiertos++;
    }
    
    double cobertura = puntosCubiertos / referenciasNormalizadas.length;
    double precision = 1 - (distanciaTotal / (puntosEvaluados * 50));
    double calificacion = (precision * 0.6 + cobertura * 0.4) * 100;
    
    // Factores adicionales para la a minúscula
    double proporcion = _verificarProporciones(puntos);
    if (proporcion > 0.8 && proporcion < 1.5) {
      calificacion *= 1.1;
    } else {
      calificacion *= 0.9;
    }
    
    // Verificar si tiene forma redonda
    bool tieneFormaRedonda = _verificarFormaRedonda(puntos);
    if (tieneFormaRedonda) {
      calificacion *= 1.05;
    }
    
    return calificacion.clamp(0, 100);
  }

  List<Offset> _normalizarPuntos(List<Offset> puntos) {
    if (puntos.isEmpty) return [];
    
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    
    for (var punto in puntos) {
      minX = punto.dx < minX ? punto.dx : minX;
      maxX = punto.dx > maxX ? punto.dx : maxX;
      minY = punto.dy < minY ? punto.dy : minY;
      maxY = punto.dy > maxY ? punto.dy : maxY;
    }
    
    double ancho = maxX - minX;
    double alto = maxY - minY;
    
    List<Offset> normalizados = [];
    for (var punto in puntos) {
      double x = ((punto.dx - minX) / ancho) * 300;
      double y = ((punto.dy - minY) / alto) * 300;
      normalizados.add(Offset(x, y));
    }
    
    return normalizados;
  }

  double _calcularDistancia(Offset p1, Offset p2) => (p1 - p2).distance;

  double _verificarProporciones(List<Offset> puntos) {
    if (puntos.length < 2) return 0;
    
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    
    for (var punto in puntos) {
      minX = punto.dx < minX ? punto.dx : minX;
      maxX = punto.dx > maxX ? punto.dx : maxX;
      minY = punto.dy < minY ? punto.dy : minY;
      maxY = punto.dy > maxY ? punto.dy : maxY;
    }
    
    double ancho = maxX - minX;
    double alto = maxY - minY;
    return alto / ancho;
  }

  bool _verificarFormaRedonda(List<Offset> puntos) {
    if (puntos.length < 10) return false;
    
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    
    for (var punto in puntos) {
      minX = punto.dx < minX ? punto.dx : minX;
      maxX = punto.dx > maxX ? punto.dx : maxX;
      minY = punto.dy < minY ? punto.dy : minY;
      maxY = punto.dy > maxY ? punto.dy : maxY;
    }
    
    double centerX = (minX + maxX) / 2;
    double centerY = (minY + maxY) / 2;
    double radioEsperado = (maxX - minX) / 2;
    
    int puntosEnCirculo = 0;
    for (var punto in puntos) {
      double distancia = _calcularDistancia(punto, Offset(centerX, centerY));
      if (distancia <= radioEsperado * 1.2) {
        puntosEnCirculo++;
      }
    }
    
    return puntosEnCirculo / puntos.length > 0.6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF134074),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _logService.addLog(
              type: LogType.navegacion,
              message: 'Regreso desde pantalla de trazado de a minúscula',
              details: {},
            );
            Navigator.pop(context);
          },
        ),
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
                    child: const Icon(Icons.school, color: Color(0xFF134074), size: 24),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SABIA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                  Text('Sistema de Alfabetización Basado en Inteligencia Artificial', 
                    style: TextStyle(fontSize: 10, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.image, color: Color(0xFF38b000), size: 20),
                    const SizedBox(width: 8),
                    const Text('Letra a minúscula', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF134074))),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _voiceService.hablar('La letra a minúscula se escribe con un círculo y una línea vertical pegada por fuera en el lado derecho. Comienza con un círculo y luego baja una línea recta pegada al círculo.'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF38b000).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.volume_up, color: Color(0xFF38b000), size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/imagenes/vocales/ami.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF0F0F0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('Imagen de referencia no disponible', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                const SizedBox(height: 4),
                                const Text('Letra a minúscula', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF134074))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF38b000).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tips_and_updates, size: 14, color: Color(0xFF38b000)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _voiceService.hablar('Traza la letra a minúscula: primero dibuja un círculo y luego una línea vertical pegada por fuera en el lado derecho. Puedes levantar el dedo para hacer trazos separados.'),
                          child: const Text(
                            'Traza la letra - primero el círculo, luego la línea vertical pegada por fuera',
                            style: TextStyle(fontSize: 11, color: Color(0xFF38b000), fontWeight: FontWeight.w500),
                            softWrap: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _voiceService.hablar('Traza la letra a minúscula: primero dibuja un círculo y luego una línea vertical pegada por fuera en el lado derecho. Puedes levantar el dedo para hacer trazos separados.'),
                        child: const Icon(Icons.volume_up, size: 14, color: Color(0xFF38b000)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFF134074).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('$_intentos', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF134074))),
                      const Text('Intentos', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.palette, size: 20, color: Color(0xFF134074)),
                      const SizedBox(width: 8),
                      ..._coloresPaleta.map((color) {
                        return GestureDetector(
                          onTap: () => setState(() => _colorTrazo = color),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: _colorTrazo == color ? Border.all(color: Colors.white, width: 3) : null,
                              boxShadow: _colorTrazo == color ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GestureDetector(
                  onPanStart: (details) => _iniciarNuevoTrazo(details.localPosition),
                  onPanUpdate: (details) => _actualizarTrazo(details.localPosition),
                  onPanEnd: (details) => _finalizarTrazoActual(),
                  child: CustomPaint(
                    painter: TrazoAMinusculaPainter(
                      trazos: _trazos,
                      trazoActual: _trazoActual,
                      mostrarReferencia: _mostrarReferencia,
                      colorTrazo: _colorTrazo,
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: (_trazos.isEmpty && _trazoActual.isEmpty)
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit, size: 50, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text('Dibuja la letra a aquí', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                                  const SizedBox(height: 8),
                                  Text('Primero el círculo, luego la línea vertical pegada por fuera', 
                                    style: TextStyle(fontSize: 12, color: Colors.grey[400]), textAlign: TextAlign.center),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reiniciarTrazo,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Reiniciar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF134074),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFF134074)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _evaluarTrazo,
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Calificar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38b000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _starAnimationController.dispose();
    _voiceService.detener();
    super.dispose();
  }
}

class TrazoAMinusculaPainter extends CustomPainter {
  final List<List<Offset>> trazos;
  final List<Offset> trazoActual;
  final bool mostrarReferencia;
  final Color colorTrazo;

  TrazoAMinusculaPainter({
    required this.trazos,
    required this.trazoActual,
    required this.mostrarReferencia,
    required this.colorTrazo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    
    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.15)..strokeWidth = 1.0;
    for (double i = 0; i < size.width; i += 25) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
    
    if (mostrarReferencia) {
      final refPaint = Paint()..color = Colors.grey.withOpacity(0.3)..strokeWidth = 3.0..style = PaintingStyle.stroke;
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      final radius = size.width * 0.13; // Reducido para dar espacio al palito por fuera
      final stemX = centerX + radius; // PEGADO POR FUERA
      final stemTopY = centerY - radius * 0.4;
      final stemBottomY = centerY + radius * 0.6;
      
      // Círculo de referencia para la a minúscula
      canvas.drawCircle(Offset(centerX, centerY), radius, refPaint);
      
      // Línea vertical de referencia - PEGADA POR FUERA
      canvas.drawLine(Offset(stemX, stemTopY), Offset(stemX, stemBottomY), refPaint);
      
      // Puntos guía
      final guidePaint = Paint()..color = Colors.grey.withOpacity(0.2)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), 6, guidePaint);
      canvas.drawCircle(Offset(stemX, stemTopY), 6, guidePaint);
      canvas.drawCircle(Offset(stemX, stemBottomY), 6, guidePaint);
    }
    
    final strokePaint = Paint()
      ..color = colorTrazo
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    
    for (final trazo in trazos) {
      if (trazo.length > 1) {
        for (int i = 0; i < trazo.length - 1; i++) {
          canvas.drawLine(trazo[i], trazo[i + 1], strokePaint);
        }
      }
    }
    
    if (trazoActual.length > 1) {
      for (int i = 0; i < trazoActual.length - 1; i++) {
        canvas.drawLine(trazoActual[i], trazoActual[i + 1], strokePaint);
      }
    }
    
    final startPaint = Paint()..color = colorTrazo.withOpacity(0.7)..style = PaintingStyle.fill;
    for (final trazo in trazos) {
      if (trazo.isNotEmpty) canvas.drawCircle(trazo.first, 6, startPaint);
    }
    if (trazoActual.isNotEmpty) canvas.drawCircle(trazoActual.first, 6, startPaint);
  }

  @override
  bool shouldRepaint(covariant TrazoAMinusculaPainter oldDelegate) {
    return oldDelegate.trazos != trazos || 
           oldDelegate.trazoActual != trazoActual ||
           oldDelegate.colorTrazo != colorTrazo;
  }
}