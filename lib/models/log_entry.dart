import 'package:flutter/material.dart';

class LogEntry {
  final DateTime timestamp;
  final LogType type;
  final String message;
  final Map<String, dynamic>? details;

  LogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.index,
    'message': message,
    'details': details,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    timestamp: DateTime.parse(json['timestamp']),
    type: LogType.values[json['type']],
    message: json['message'],
    details: json['details'],
  );

  String getFormattedDate() {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  String getTypeIcon() {
    switch (type) {
      case LogType.login:
        return '🔐';
      case LogType.register:
        return '📝';
      case LogType.retoCompletado:
        return '🎯';
      case LogType.vozCambiada:
        return '🎤';
      case LogType.navegacion:
        return '📱';
      case LogType.puntosGanados:
        return '⭐';
      case LogType.error:
        return '❌';
    }
  }

  Color getTypeColor() {
    switch (type) {
      case LogType.login:
        return const Color(0xFF4CAF50);
      case LogType.register:
        return const Color(0xFF2196F3);
      case LogType.retoCompletado:
        return const Color(0xFFFF9800);
      case LogType.vozCambiada:
        return const Color(0xFF9C27B0);
      case LogType.navegacion:
        return const Color(0xFF00BCD4);
      case LogType.puntosGanados:
        return const Color(0xFFFFD700);
      case LogType.error:
        return const Color(0xFFF44336);
    }
  }
}

enum LogType {
  login,
  register,
  retoCompletado,
  vozCambiada,
  navegacion,
  puntosGanados,
  error,
}