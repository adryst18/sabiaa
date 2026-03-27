import 'package:flutter/material.dart';
import 'dart:async';

class PrivadoScreen extends StatefulWidget {
  const PrivadoScreen({super.key});

  @override
  State<PrivadoScreen> createState() => _PrivadoScreenState();
}

class _PrivadoScreenState extends State<PrivadoScreen> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    // Iniciar animación
    _animationController.forward();
    
    // Configurar temporizador para cerrar después de 3 segundos
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF134074).withOpacity(0.95),
                        const Color(0xFF0B2B4F).withOpacity(0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF38b000).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icono de candado con animación
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38b000).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF38b000),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 60,
                          color: Color(0xFF38b000),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Mensaje principal
                      const Text(
                        'ACCESO RESTRINGIDO',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // Línea decorativa
                      Container(
                        width: 80,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF38b000),
                              const Color(0xFF9252e3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Mensaje secundario
                      const Text(
                        'No tienes permisos para acceder\na esta sección',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Indicador de tiempo
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 1.0, end: 0.0),
                        duration: const Duration(seconds: 3),
                        builder: (context, value, child) {
                          return Column(
                            children: [
                              LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38b000)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Redirigiendo en ${(value * 3).toInt()} segundos...',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}