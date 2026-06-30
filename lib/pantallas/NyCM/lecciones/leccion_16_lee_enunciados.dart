import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// ============================================================
/// LECCIÓN 16 — "Lee en voz alta los siguientes enunciados y
/// menciona cuántas palabras los forman."
///
/// Digitalización interactiva de la página 24 del cuadernillo.
/// Ubicación sugerida: lib/pantallas/NyCM/lecciones/leccion_16_lee_enunciados.dart
///
/// Requiere agregar en pubspec.yaml:
///   dependencies:
///     flutter_tts: ^4.0.2
/// ============================================================

/// Modelo de un enunciado de la lección, con su color de fondo
/// (igual al de los puntos en el cuadernillo original) y la
/// lista de palabras que lo forman.
class FraseLeccion {
  final List<String> palabras;
  final Color color;

  const FraseLeccion({required this.palabras, required this.color});

  int get numeroDePalabras => palabras.length;

  String get textoCompleto => '${palabras.join(' ')}';
}

class Leccion16LeeEnunciados extends StatefulWidget {
  const Leccion16LeeEnunciados({super.key});

  @override
  State<Leccion16LeeEnunciados> createState() =>
      _Leccion16LeeEnunciadosState();
}

class _Leccion16LeeEnunciadosState extends State<Leccion16LeeEnunciados> {
  late final FlutterTts _tts;

  // Enunciados tal como aparecen en la página, con sus colores.
  final List<FraseLeccion> _frases = const [
    FraseLeccion(
      palabras: ['Lalo', 'le', 'lee', 'a', 'Lolo.'],
      color: Color(0xFFF6E27A), // amarillo
    ),
    FraseLeccion(
      palabras: ['Le', 'leo', 'a', 'Lola.'],
      color: Color(0xFFF3B68A), // naranja/durazno
    ),
    FraseLeccion(
      palabras: ['Lili', 'usa', 'la', 'lata.'],
      color: Color(0xFFF3B8C7), // rosa
    ),
    FraseLeccion(
      palabras: ['El', 'loro', 'tiene', 'alas.'],
      color: Color(0xFFA9D3E5), // azul
    ),
    FraseLeccion(
      palabras: ['El', 'león', 'mira', 'la', 'luna.'],
      color: Color(0xFFC3D9A0), // verde
    ),
  ];

  final List<String> _preguntas = const [
    '¿A quién le leo?',
    '¿Qué hace Lalo?',
    '¿Quién usa la lata?',
    '¿Quién mira la luna?',
    '¿Qué tiene el loro?',
  ];

  // Controla, por cada frase, qué palabra está resaltada (si alguna).
  late List<int?> _palabraResaltada;

  // Controladores de texto para que el usuario escriba cuántas
  // palabras contó en cada enunciado.
  late List<TextEditingController> _controladoresConteo;

  // Resultado de la verificación: null = sin verificar,
  // true = correcto, false = incorrecto.
  late List<bool?> _resultadoConteo;

  bool _hablando = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('es-MX');
    _tts.setSpeechRate(0.45); // un poco más lento, pensado para alfabetización
    _tts.setPitch(1.0);

    _tts.setStartHandler(() => setState(() => _hablando = true));
    _tts.setCompletionHandler(() => setState(() => _hablando = false));
    _tts.setCancelHandler(() => setState(() => _hablando = false));

    _palabraResaltada = List<int?>.filled(_frases.length, null);
    _controladoresConteo =
        List.generate(_frases.length, (_) => TextEditingController());
    _resultadoConteo = List<bool?>.filled(_frases.length, null);
  }

  @override
  void dispose() {
    _tts.stop();
    for (final c in _controladoresConteo) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _hablar(String texto) async {
    await _tts.stop();
    await _tts.speak(texto);
  }

  Future<void> _hablarPalabra(int fraseIndex, int palabraIndex) async {
    setState(() => _palabraResaltada[fraseIndex] = palabraIndex);
    final palabra = _frases[fraseIndex].palabras[palabraIndex];
    await _hablar(palabra.replaceAll('.', ''));
    // Quita el resaltado después de un momento.
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _palabraResaltada[fraseIndex] = null);
    }
  }

  void _verificarConteo(int index) {
    final texto = _controladoresConteo[index].text.trim();
    final numero = int.tryParse(texto);
    setState(() {
      _resultadoConteo[index] =
          numero != null && numero == _frases[index].numeroDePalabras;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      appBar: AppBar(
        title: const Text('Lección 16'),
        backgroundColor: const Color(0xFF6FA8C9),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildIndicacion(),
            const SizedBox(height: 24),
            for (int i = 0; i < _frases.length; i++) ...[
              _buildFrase(i),
              const SizedBox(height: 20),
            ],
            const Divider(height: 40, thickness: 1.2),
            _buildPreguntas(),
          ],
        ),
      ),
    );
  }

  /// Indicación principal con botón de "escuchar".
  Widget _buildIndicacion() {
    const texto =
        '16. Lee en voz alta los siguientes enunciados y menciona '
        'cuántas palabras los forman.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2A26),
              ),
            ),
          ),
          IconButton(
            iconSize: 32,
            color: const Color(0xFF6FA8C9),
            icon: Icon(_hablando ? Icons.volume_up : Icons.volume_up_outlined),
            tooltip: 'Escuchar indicación',
            onPressed: () => _hablar(texto),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de un enunciado: palabras tocables + puntos + conteo.
  Widget _buildFrase(int index) {
    final frase = _frases[index];
    final resultado = _resultadoConteo[index];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: frase.color.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: frase.color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de palabras tocables + botón para oír todo el enunciado.
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (int p = 0; p < frase.palabras.length; p++)
                      _buildPalabraChip(index, p),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.record_voice_over),
                color: const Color(0xFF2D2A26),
                tooltip: 'Escuchar enunciado completo',
                onPressed: () => _hablar(frase.textoCompleto),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Puntos visuales (uno por palabra), como en el cuadernillo.
          Row(
            children: [
              for (int p = 0; p < frase.numeroDePalabras; p++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: const Color(0xFF2D2A26),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Campo para que el usuario escriba cuántas palabras contó.
          Row(
            children: [
              const Text('¿Cuántas palabras tiene?  '),
              SizedBox(
                width: 56,
                child: TextField(
                  controller: _controladoresConteo[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _verificarConteo(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6FA8C9),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Verificar'),
              ),
              const SizedBox(width: 10),
              if (resultado != null)
                Icon(
                  resultado ? Icons.check_circle : Icons.cancel,
                  color: resultado ? Colors.green[700] : Colors.red[700],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPalabraChip(int fraseIndex, int palabraIndex) {
    final resaltada = _palabraResaltada[fraseIndex] == palabraIndex;
    final palabra = _frases[fraseIndex].palabras[palabraIndex];

    return GestureDetector(
      onTap: () => _hablarPalabra(fraseIndex, palabraIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: resaltada ? const Color(0xFF6FA8C9) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          palabra,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: resaltada ? Colors.white : const Color(0xFF2D2A26),
          ),
        ),
      ),
    );
  }

  /// Sección de preguntas de comprensión, cada una con su botón de audio.
  Widget _buildPreguntas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Responde en voz alta:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        for (final pregunta in _preguntas)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      pregunta,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined),
                    color: const Color(0xFF6FA8C9),
                    onPressed: () => _hablar(pregunta),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}