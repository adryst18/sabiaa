import 'dart:math' as math;
import 'package:flutter/material.dart';

class SecuencialEstrellasWidget extends StatefulWidget {
  final int cantidadEstrellas;

  const SecuencialEstrellasWidget({super.key, required this.cantidadEstrellas});

  @override
  State<SecuencialEstrellasWidget> createState() => _SecuencialEstrellasWidgetState();
}

class _SecuencialEstrellasWidgetState extends State<SecuencialEstrellasWidget> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
    });

    _animations = _controllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.bounceOut);
    }).toList();

    _ejecutarCascada();
  }

  void _ejecutarCascada() async {
    for (int i = 0; i < widget.cantidadEstrellas; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return ScaleTransition(
          scale: _animations[index],
          child: Icon(
            index < widget.cantidadEstrellas ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 36,
          ),
        );
      }),
    );
  }
}

class ConfetiPainter extends CustomPainter {
  final double progreso;
  final List<ParticulaConfeti> particulas;

  ConfetiPainter({required this.progreso})
      : particulas = List.generate(40, (i) {
          final random = math.Random(i);
          return ParticulaConfeti(
            color: HSVColor.fromAHSV(1.0, random.nextDouble() * 360, 0.8, 0.9).toColor(),
            anguloInicial: random.nextDouble() * math.pi * 2,
            velocidad: random.nextDouble() * 150 + 50,
            escala: random.nextDouble() * 6 + 4,
          );
        });

  @override
  void paint(Canvas canvas, Size size) {
    if (progreso == 0.0 || progreso == 1.0) return;

    final centroX = size.width / 2;
    final centroY = size.height / 3; 

    for (var p in particulas) {
      final t = progreso;
      final x = centroX + p.velocidad * math.cos(p.anguloInicial) * t;
      final y = centroY + p.velocidad * math.sin(p.anguloInicial) * t + (200 * t * t);

      final paint = Paint()
        ..color = p.color.withOpacity(1.0 - t) 
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.escala, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfetiPainter oldDelegate) => oldDelegate.progreso != progreso;
}

class ParticulaConfeti {
  final Color color;
  final double anguloInicial;
  final double velocidad;
  final double escala;

  ParticulaConfeti({
    required this.color,
    required this.anguloInicial,
    required this.velocidad,
    required this.escala,
  });
}