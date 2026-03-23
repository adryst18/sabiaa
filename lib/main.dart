import 'package:flutter/material.dart';
import 'package:sabia/login/log1.dart';
import 'pantallas/home_screen.dart'; // Asegúrate de que este import apunte al archivo correcto

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SABIA',
      debugShowCheckedModeBanner: false, // quita el banner de debug si quieres
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)), // azul SABIA
        useMaterial3: true,
      ),
      home: const Log1(), // ← Aquí cambiamos a tu pantalla principal
    );
  }//widget
}