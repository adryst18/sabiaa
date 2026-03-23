import 'package:flutter/material.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/models/log_entry.dart';
import 'log4.dart';

class Log3 extends StatefulWidget {
  const Log3({super.key});

  @override
  State<Log3> createState() => _Log3State();
}

class _Log3State extends State<Log3> {
  final _correoController = TextEditingController();
  bool _isLoading = false;
  
  final LogService _logService = LogService();

  @override
  void initState() {
    super.initState();
    _logService.addLog(
      type: LogType.navegacion,
      message: 'Pantalla de recuperación de contraseña cargada',
      details: {'pantalla': 'Log3'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF134074),
              Color(0xFF1A4D7A),
              Color(0xFF2A5F8E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF38b000),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/imagenes/logo.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF134074),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recuperar contraseña',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tu correo electrónico y te enviaremos\nun enlace para restablecer tu contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF9b9b9b),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Campo Correo
                  _buildTextField(
                    label: 'Correo electrónico',
                    controller: _correoController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón de recuperar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRecovery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38b000), // Verde
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enviar enlace',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Botón de volver a inicio de sesión
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        _logService.addLog(
                          type: LogType.navegacion,
                          message: 'Navegación a inicio de sesión desde recuperación',
                          details: {'origen': 'Log3'},
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const Log4()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF9252e3), width: 2), // Morado
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Volver al inicio de sesión',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF9252e3), // Morado
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF9b9b9b).withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: const Color(0xFF9b9b9b)),
          prefixIcon: Icon(icon, color: const Color(0xFF9252e3), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF38b000), width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Future<void> _handleRecovery() async {
    final correo = _correoController.text.trim();

    if (correo.isEmpty || !correo.contains('@')) {
      _showError('Por favor ingresa un correo válido');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(seconds: 1));
    
    await _logService.addLog(
      type: LogType.navegacion,
      message: 'Solicitud de recuperación de contraseña',
      details: {
        'correo': correo,
      },
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📧 Se ha enviado un enlace a $correo'),
          backgroundColor: const Color(0xFF38b000),
          duration: const Duration(seconds: 3),
        ),
      );
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Log4()),
      );
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }
}