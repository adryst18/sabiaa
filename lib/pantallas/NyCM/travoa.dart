import 'package:flutter/material.dart';
import 'package:sabia/services/voice_service.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/models/log_entry.dart';

class TrazoAScreen extends StatefulWidget {
  const TrazoAScreen({super.key});

  @override
  State<TrazoAScreen> createState() => _TrazoAScreenState();
}

class _TrazoAScreenState extends State<TrazoAScreen> {
  final VoiceService _voiceService = VoiceService();
  final LogService _logService = LogService();
  
  // Lista para almacenar los puntos del trazo
  List<Offset> _puntos = [];
  
  // Control de estado
  bool _mostrarReferencia = true;
  int _intentos = 0;
  int _aciertos = 0;
  double _calificacion = 0;
  bool _mostrarCalificacion = false;
  
  // Control de animación del GIF
  int _pasoAnimacion = 0;
  final List<String> _pasosAnimacion = [
    'assets/animaciones/a_paso1.png',
    'assets/animaciones/a_paso2.png',
    'assets/animaciones/a_paso3.png',
    'assets/animaciones/a_paso4.png',
  ];

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _iniciarAnimacion();
    _logService.addLog(
      type: LogType.navegacion,
      message: 'Pantalla de trazado de letra A cargada',
      details: {'pantalla': 'TrazoAScreen'},
    );
  }

  void _iniciarAnimacion() {
    // Simular animación cambiando de imagen cada 0.8 segundos
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _mostrarReferencia) {
        setState(() {
          _pasoAnimacion = (_pasoAnimacion + 1) % _pasosAnimacion.length;
        });
        _iniciarAnimacion();
      }
    });
  }

  void _reiniciarTrazo() {
    setState(() {
      _puntos.clear();
      _mostrarCalificacion = false;
    });
  }

  void _evaluarTrazo() {
    if (_puntos.length < 20) {
      _voiceService.hablar('Dibuja la letra A primero');
      return;
    }
    
    // Evaluación básica del trazo
    // En una implementación real, se compararía con puntos de referencia
    // Por ahora, usamos heurísticas simples
    
    // Calcular bounding box del trazo
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    
    for (var punto in _puntos) {
      minX = punto.dx < minX ? punto.dx : minX;
      maxX = punto.dx > maxX ? punto.dx : maxX;
      minY = punto.dy < minY ? punto.dy : minY;
      maxY = punto.dy > maxY ? punto.dy : maxY;
    }
    
    final ancho = maxX - minX;
    final alto = maxY - minY;
    final relacion = alto / ancho;
    
    // La letra A debe tener forma triangular (más alta que ancha)
    // y debe tener un trazo continuo
    
    double calificacion = 0;
    
    // 1. Proporción correcta (la A es más alta que ancha)
    if (relacion > 1.2 && relacion < 2.0) {
      calificacion += 0.4;
    } else if (relacion > 1.0 && relacion < 2.5) {
      calificacion += 0.2;
    }
    
    // 2. El trazo debe tener puntos en la parte superior y inferior
    bool tienePuntoSuperior = _puntos.any((p) => p.dy < minY + (alto * 0.2));
    bool tienePuntoInferior = _puntos.any((p) => p.dy > maxY - (alto * 0.2));
    bool tienePuntoIzquierdo = _puntos.any((p) => p.dx < minX + (ancho * 0.2));
    bool tienePuntoDerecho = _puntos.any((p) => p.dx > maxX - (ancho * 0.2));
    
    if (tienePuntoSuperior && tienePuntoInferior && tienePuntoIzquierdo && tienePuntoDerecho) {
      calificacion += 0.4;
    } else if (tienePuntoSuperior && tienePuntoInferior) {
      calificacion += 0.2;
    }
    
    // 3. Longitud del trazo (suficientes puntos)
    if (_puntos.length > 100) {
      calificacion += 0.2;
    } else if (_puntos.length > 50) {
      calificacion += 0.1;
    }
    
    // Redondear calificación
    calificacion = (calificacion * 100).roundToDouble();
    _calificacion = calificacion;
    
    setState(() {
      _mostrarCalificacion = true;
    });
    
    if (calificacion >= 70) {
      _aciertos++;
      _voiceService.hablar('¡Excelente! Has dibujado la letra A correctamente. Calificación: ${calificacion.toInt()} puntos.');
      
      _logService.addLog(
        type: LogType.navegacion,
        message: 'Trazo de letra A completado exitosamente',
        details: {'calificacion': calificacion, 'intentos': _intentos + 1},
      );
    } else {
      _voiceService.hablar('Sigue practicando. Calificación: ${calificacion.toInt()} puntos. Recuerda que la A tiene forma triangular.');
      
      _logService.addLog(
        type: LogType.navegacion,
        message: 'Trazo de letra A - intento con calificación baja',
        details: {'calificacion': calificacion},
      );
    }
    
    _intentos++;
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
              message: 'Regreso desde pantalla de trazado',
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SABIA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
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
          ],
        ),
      ),
      
      body: Column(
        children: [
          // Área superior con animación/GIF de referencia
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
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
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline, color: Color(0xFF38b000), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Cómo escribir la letra A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF134074),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        _voiceService.hablar('Para escribir la letra A, primero dibuja una línea curva hacia la izquierda que sube, luego baja en diagonal y cruza en el medio.');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38b000).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.volume_up, color: Color(0xFF38b000), size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Animación de referencia (simulada con imágenes)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Center(
                    child: Image.asset(
                      _pasosAnimacion[_pasoAnimacion],
                      height: 120,
                      width: 120,
                      errorBuilder: (context, error, stackTrace) {
                        // Placeholder mientras no haya imágenes
                        return Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getInstruccionPaso(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9252e3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getInstruccionPaso(),
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF9252e3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Estadísticas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatChip('Intentos', '$_intentos', const Color(0xFF134074)),
                const SizedBox(width: 12),
                _buildStatChip('Aciertos', '$_aciertos', const Color(0xFF38b000)),
                const SizedBox(width: 12),
                _buildStatChip('Aciertos %', _aciertos > 0 ? '${((_aciertos / (_intentos + 1)) * 100).toInt()}%' : '0%', const Color(0xFF9252e3)),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Área de dibujo
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
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
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _puntos.add(details.localPosition);
                      _mostrarCalificacion = false;
                    });
                  },
                  onPanEnd: (details) {
                    // Fin del trazo
                  },
                  child: CustomPaint(
                    painter: TrazoPainter(
                      puntos: _puntos,
                      mostrarReferencia: _mostrarReferencia,
                      calificacion: _calificacion,
                      mostrarCalificacion: _mostrarCalificacion,
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Stack(
                        children: [
                          // Texto de guía
                          if (_puntos.isEmpty)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 50,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Dibuja la letra A aquí',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Botones de acción
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInstruccionPaso() {
    switch (_pasoAnimacion) {
      case 0:
        return '1. Comienza en la parte superior izquierda';
      case 1:
        return '2. Traza una curva hacia la derecha';
      case 2:
        return '3. Baja en diagonal hacia la izquierda';
      case 3:
        return '4. Cruza con una línea en el medio';
      default:
        return 'Sigue los pasos para dibujar la A';
    }
  }

  @override
  void dispose() {
    _voiceService.detener();
    super.dispose();
  }
}

// CustomPainter para dibujar el trazo
class TrazoPainter extends CustomPainter {
  final List<Offset> puntos;
  final bool mostrarReferencia;
  final double calificacion;
  final bool mostrarCalificacion;

  TrazoPainter({
    required this.puntos,
    required this.mostrarReferencia,
    required this.calificacion,
    required this.mostrarCalificacion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo blanco con cuadrícula sutil
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 0.5;
    
    // Dibujar cuadrícula
    for (double i = 0; i < size.width; i += 25) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
    
    // Dibujar puntos de referencia para la letra A (forma triangular)
    if (mostrarReferencia) {
      final refPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      final centerX = size.width / 2;
      final topY = size.height * 0.2;
      final bottomY = size.height * 0.8;
      final leftX = centerX - size.width * 0.2;
      final rightX = centerX + size.width * 0.2;
      final crossY = size.height * 0.5;
      
      // Triángulo exterior
      var path = Path();
      path.moveTo(centerX, topY);
      path.lineTo(leftX, bottomY);
      path.lineTo(rightX, bottomY);
      path.close();
      canvas.drawPath(path, refPaint);
      
      // Línea horizontal del medio
      canvas.drawLine(Offset(leftX + (rightX - leftX) * 0.2, crossY),
                      Offset(rightX - (rightX - leftX) * 0.2, crossY), refPaint);
    }
    
    // Dibujar el trazo del usuario
    if (puntos.isNotEmpty) {
      final paint = Paint()
        ..color = const Color(0xFF38b000)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      for (int i = 0; i < puntos.length - 1; i++) {
        canvas.drawLine(puntos[i], puntos[i + 1], paint);
      }
      
      // Dibujar puntos al inicio y final
      final pointPaint = Paint()
        ..color = const Color(0xFF38b000)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(puntos.first, 8, pointPaint);
      pointPaint.color = const Color(0xFF134074);
      canvas.drawCircle(puntos.last, 8, pointPaint);
    }
    
    // Mostrar calificación
    if (mostrarCalificacion) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Calificación: ${calificacion.toInt()}%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: calificacion >= 70 ? const Color(0xFF38b000) : const Color(0xFFFF6B6B),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - 50),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrazoPainter oldDelegate) {
    return oldDelegate.puntos != puntos ||
           oldDelegate.mostrarCalificacion != mostrarCalificacion;
  }
}