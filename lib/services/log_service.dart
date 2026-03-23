import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/log_entry.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  static const String _logsKey = 'app_logs';
  static const int _maxLogs = 200; // Máximo de logs a guardar

  List<LogEntry> _logs = [];

  Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsString = prefs.getString(_logsKey);
      if (logsString != null) {
        final List<dynamic> logsList = jsonDecode(logsString);
        _logs = logsList.map((log) => LogEntry.fromJson(log)).toList();
      }
    } catch (e) {
      print('Error al cargar logs: $e');
    }
  }

  Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsString = jsonEncode(_logs.map((log) => log.toJson()).toList());
      await prefs.setString(_logsKey, logsString);
    } catch (e) {
      print('Error al guardar logs: $e');
    }
  }

  Future<void> addLog({
    required LogType type,
    required String message,
    Map<String, dynamic>? details,
  }) async {
    await _loadLogs();
    
    final newLog = LogEntry(
      timestamp: DateTime.now(),
      type: type,
      message: message,
      details: details,
    );
    
    _logs.insert(0, newLog); // Insertar al inicio (más reciente primero)
    
    // Limitar número de logs
    if (_logs.length > _maxLogs) {
      _logs = _logs.sublist(0, _maxLogs);
    }
    
    await _saveLogs();
  }

  Future<List<LogEntry>> getLogs() async {
    await _loadLogs();
    return _logs;
  }

  Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogs();
  }

  Future<List<LogEntry>> getLogsByType(LogType type) async {
    await _loadLogs();
    return _logs.where((log) => log.type == type).toList();
  }
}