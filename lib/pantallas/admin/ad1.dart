import 'package:flutter/material.dart';
import 'package:sabia/services/log_service.dart';
import 'package:sabia/models/log_entry.dart';
import 'dart:math';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final LogService _logService = LogService();
  
  // Control de navegación inferior
  int _selectedIndex = 0;
  
  // Datos simulados para estadísticas
  final Map<String, dynamic> _estadisticas = {
    'totalUsuarios': 156,
    'usuariosActivos': 142,
    'totalActividades': 48,
    'actividadesCompletadas': 1247,
    'tasaExito': 78.5,
    'promedioCalificacion': 85.3,
  };
  
  // Datos simulados para usuarios
  List<Map<String, dynamic>> _usuarios = [
    {'id': 1, 'nombre': 'Adrián Cruz', 'email': 'adriancruz@email.com', 'rol': 'usuario', 'activo': true, 'fechaRegistro': '2024-01-15', 'progreso': 85},
    {'id': 2, 'nombre': 'María González', 'email': 'maria.g@email.com', 'rol': 'usuario', 'activo': true, 'fechaRegistro': '2024-01-20', 'progreso': 92},
    {'id': 3, 'nombre': 'Carlos Martínez', 'email': 'carlos.m@email.com', 'rol': 'usuario', 'activo': true, 'fechaRegistro': '2024-02-01', 'progreso': 67},
    {'id': 4, 'nombre': 'Ana Rodríguez', 'email': 'ana.r@email.com', 'rol': 'usuario', 'activo': false, 'fechaRegistro': '2024-02-10', 'progreso': 45},
    {'id': 5, 'nombre': 'Luis Fernández', 'email': 'luis.f@email.com', 'rol': 'usuario', 'activo': true, 'fechaRegistro': '2024-02-15', 'progreso': 78},
  ];
  
  // Datos simulados para actividades
  List<Map<String, dynamic>> _actividades = [
    {'id': 1, 'titulo': 'Letra A mayúscula', 'tipo': 'trazado', 'completados': 234, 'dificultad': 'fácil', 'activo': true},
    {'id': 2, 'titulo': 'Letra A minúscula', 'tipo': 'trazado', 'completados': 198, 'dificultad': 'fácil', 'activo': true},
    {'id': 3, 'titulo': 'Letra E mayúscula', 'tipo': 'trazado', 'completados': 156, 'dificultad': 'media', 'activo': true},
    {'id': 4, 'titulo': 'Letra E minúscula', 'tipo': 'trazado', 'completados': 142, 'dificultad': 'media', 'activo': true},
    {'id': 5, 'titulo': 'Números del 1 al 10', 'tipo': 'numeros', 'completados': 312, 'dificultad': 'fácil', 'activo': true},
    {'id': 6, 'titulo': 'Palabras simples', 'tipo': 'lectura', 'completados': 89, 'dificultad': 'difícil', 'activo': false},
  ];
  
  // Control para diálogos de edición
  Map<String, dynamic>? _usuarioEditando;
  Map<String, dynamic>? _actividadEditando;
  
  // Controladores para formularios
  final _formKeyUsuario = GlobalKey<FormState>();
  final _formKeyActividad = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _rolController = TextEditingController();
  final _tituloController = TextEditingController();
  final _dificultadController = TextEditingController();
  final _tipoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logService.addLog(
      type: LogType.navegacion,
      message: 'Panel de administrador cargado',
      details: {'pantalla': 'AdminPanelScreen'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF134074),
        elevation: 2,
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
                    child: const Icon(Icons.admin_panel_settings, color: Color(0xFF134074), size: 24),
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
                    'Panel de Administración',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'SABIA - Sistema de Gestión',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _logService.addLog(
                type: LogType.navegacion,
                message: 'Administrador cerró sesión',
                details: {},
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF38b000),
          unselectedItemColor: const Color(0xFF134074),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Usuarios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Actividades',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildUsuarios();
      case 2:
        return _buildActividades();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjetas de estadísticas
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard('Usuarios Totales', '${_estadisticas['totalUsuarios']}', Icons.people, const Color(0xFF38b000)),
              _buildStatCard('Usuarios Activos', '${_estadisticas['usuariosActivos']}', Icons.person, const Color(0xFF134074)),
              _buildStatCard('Actividades', '${_estadisticas['totalActividades']}', Icons.school, const Color(0xFF9252e3)),
              _buildStatCard('Completadas', '${_estadisticas['actividadesCompletadas']}', Icons.check_circle, const Color(0xFFFFB74D)),
              _buildStatCard('Tasa de Éxito', '${_estadisticas['tasaExito']}%', Icons.trending_up, const Color(0xFF38b000)),
              _buildStatCard('Promedio Calif.', '${_estadisticas['promedioCalificacion']}%', Icons.star, const Color(0xFF9252e3)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Gráfica de progreso semanal
          Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actividades Completadas (Últimos 7 días)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF134074),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildWeeklyChart(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Últimas actividades
          Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actividades Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF134074),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _actividades.length > 3 ? 3 : _actividades.length,
                  itemBuilder: (context, index) {
                    final actividad = _actividades[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38b000).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school, color: Color(0xFF38b000), size: 20),
                      ),
                      title: Text(
                        actividad['titulo'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('${actividad['completados']} completados • Dificultad: ${actividad['dificultad']}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: actividad['activo'] 
                              ? const Color(0xFF38b000).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          actividad['activo'] ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 12,
                            color: actividad['activo'] ? const Color(0xFF38b000) : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final datos = [45, 62, 58, 71, 84, 93, 78];
    final dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final maxValue = datos.reduce((a, b) => a > b ? a : b).toDouble();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final altura = (datos[index] / maxValue) * 160;
        return Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 35,
                  height: altura,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF38b000),
                        const Color(0xFF9252e3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38b000).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dias[index],
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF134074),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${datos[index]}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildUsuarios() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _usuarios.length,
      itemBuilder: (context, index) {
        final usuario = _usuarios[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: usuario['rol'] == 'admin' 
                    ? const Color(0xFF9252e3).withOpacity(0.1)
                    : const Color(0xFF38b000).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                usuario['rol'] == 'admin' ? Icons.admin_panel_settings : Icons.person,
                color: usuario['rol'] == 'admin' ? const Color(0xFF9252e3) : const Color(0xFF38b000),
              ),
            ),
            title: Text(
              usuario['nombre'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usuario['email'], style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: usuario['progreso'] / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38b000)),
                ),
                Text('Progreso: ${usuario['progreso']}%', style: const TextStyle(fontSize: 10)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF134074), size: 20),
                  onPressed: () => _editarUsuario(usuario),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _eliminarUsuario(usuario),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: usuario['activo'] ? const Color(0xFF38b000) : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActividades() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _actividades.length,
      itemBuilder: (context, index) {
        final actividad = _actividades[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTipoColor(actividad['tipo']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTipoIcon(actividad['tipo']),
                color: _getTipoColor(actividad['tipo']),
              ),
            ),
            title: Text(
              actividad['titulo'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo: ${actividad['tipo']} • Dificultad: ${actividad['dificultad']}'),
                Text('Completados: ${actividad['completados']} veces'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF134074), size: 20),
                  onPressed: () => _editarActividad(actividad),
                ),
                Switch(
                  value: actividad['activo'],
                  onChanged: (value) {
                    setState(() {
                      actividad['activo'] = value;
                    });
                    _logService.addLog(
                      type: LogType.navegacion,
                      message: 'Estado de actividad cambiado',
                      details: {'actividad': actividad['titulo'], 'nuevoEstado': value},
                    );
                  },
                  activeColor: const Color(0xFF38b000),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editarUsuario(Map<String, dynamic> usuario) {
    _usuarioEditando = usuario;
    _nombreController.text = usuario['nombre'];
    _emailController.text = usuario['email'];
    _rolController.text = usuario['rol'];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKeyUsuario,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Editar Usuario',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF134074),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _rolController.text,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'usuario', child: Text('Usuario')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  ],
                  onChanged: (value) {
                    _rolController.text = value!;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKeyUsuario.currentState!.validate()) {
                            setState(() {
                              _usuarioEditando!['nombre'] = _nombreController.text;
                              _usuarioEditando!['email'] = _emailController.text;
                              _usuarioEditando!['rol'] = _rolController.text;
                            });
                            _logService.addLog(
                              type: LogType.navegacion,
                              message: 'Usuario editado',
                              details: {'usuario': _usuarioEditando!['nombre']},
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38b000),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _eliminarUsuario(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar a ${usuario['nombre']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _usuarios.remove(usuario);
              });
              _logService.addLog(
                type: LogType.navegacion,
                message: 'Usuario eliminado',
                details: {'usuario': usuario['nombre']},
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _editarActividad(Map<String, dynamic> actividad) {
    _actividadEditando = actividad;
    _tituloController.text = actividad['titulo'];
    _dificultadController.text = actividad['dificultad'];
    _tipoController.text = actividad['tipo'];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKeyActividad,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Editar Actividad',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF134074),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _tipoController.text,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'trazado', child: Text('Trazado')),
                    DropdownMenuItem(value: 'numeros', child: Text('Números')),
                    DropdownMenuItem(value: 'lectura', child: Text('Lectura')),
                  ],
                  onChanged: (value) {
                    _tipoController.text = value!;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _dificultadController.text,
                  decoration: const InputDecoration(
                    labelText: 'Dificultad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.speed),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'fácil', child: Text('Fácil')),
                    DropdownMenuItem(value: 'media', child: Text('Media')),
                    DropdownMenuItem(value: 'difícil', child: Text('Difícil')),
                  ],
                  onChanged: (value) {
                    _dificultadController.text = value!;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKeyActividad.currentState!.validate()) {
                            setState(() {
                              _actividadEditando!['titulo'] = _tituloController.text;
                              _actividadEditando!['dificultad'] = _dificultadController.text;
                              _actividadEditando!['tipo'] = _tipoController.text;
                            });
                            _logService.addLog(
                              type: LogType.navegacion,
                              message: 'Actividad editada',
                              details: {'actividad': _actividadEditando!['titulo']},
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9252e3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'trazado':
        return const Color(0xFF38b000);
      case 'numeros':
        return const Color(0xFF134074);
      case 'lectura':
        return const Color(0xFF9252e3);
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'trazado':
        return Icons.edit;
      case 'numeros':
        return Icons.numbers;
      case 'lectura':
        return Icons.menu_book;
      default:
        return Icons.school;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _rolController.dispose();
    _tituloController.dispose();
    _dificultadController.dispose();
    _tipoController.dispose();
    super.dispose();
  }
}