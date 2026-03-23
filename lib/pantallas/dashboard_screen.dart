import 'package:flutter/material.dart';
import 'package:sabia/models/log_entry.dart';
import 'package:sabia/services/log_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LogService _logService = LogService();
  List<LogEntry> _logs = [];
  bool _isLoading = true;
  LogType? _selectedFilter;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _logService.getLogs();
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Future<void> _clearLogs() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Limpiar bitácora'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los registros?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _logService.clearLogs();
              await _loadLogs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Bitácora limpiada'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  List<LogEntry> _getFilteredLogs() {
    if (_selectedFilter == null) return _logs;
    return _logs.where((log) => log.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B66),
        elevation: 2,
        title: const Text(
          'Dashboard - Bitácora de Actividades',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _clearLogs,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _selectedFilter == null,
                      onSelected: (_) => setState(() => _selectedFilter = null),
                      backgroundColor: Colors.grey.shade200,
                      selectedColor: const Color(0xFF0D3B66).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _selectedFilter == null ? const Color(0xFF0D3B66) : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...LogType.values.map((type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getTypeName(type)),
                        selected: _selectedFilter == type,
                        onSelected: (_) => setState(() => _selectedFilter = type),
                        avatar: Text(_getTypeIcon(type)),
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: const Color(0xFF0D3B66).withOpacity(0.2),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          
          // Contador de logs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total de registros: ${filteredLogs.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedFilter != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedFilter = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D3B66).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Limpiar filtro',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF0D3B66),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.close, size: 14, color: Color(0xFF0D3B66)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Lista de logs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D3B66)))
                : filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == null
                                  ? 'No hay registros aún\nRealiza acciones para ver la bitácora'
                                  : 'No hay registros con este filtro',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return _buildLogCard(log);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(LogEntry log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: log.getTypeColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                log.getTypeIcon(),
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E2A3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.getFormattedDate(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                if (log.details != null && log.details!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 8,
                      children: log.details!.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeName(LogType type) {
    switch (type) {
      case LogType.login:
        return 'Login';
      case LogType.register:
        return 'Registro';
      case LogType.retoCompletado:
        return 'Retos';
      case LogType.vozCambiada:
        return 'Voz';
      case LogType.navegacion:
        return 'Navegación';
      case LogType.puntosGanados:
        return 'Puntos';
      case LogType.error:
        return 'Errores';
    }
  }

  String _getTypeIcon(LogType type) {
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
}