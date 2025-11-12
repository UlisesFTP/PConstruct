// lib/features/benchmarks/pages/benchmarks_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/build.dart'; // Importar BuildSummary

class BenchmarksPage extends StatefulWidget {
  const BenchmarksPage({super.key});

  @override
  State<BenchmarksPage> createState() => _BenchmarksPageState();
}

class _BenchmarksPageState extends State<BenchmarksPage> {
  final TextEditingController _componentSearchController =
      TextEditingController();
  final TextEditingController _gameSearchController = TextEditingController();

  BuildSummary? _selectedBuild; // El objeto BuildSummary completo o null
  List<BuildSummary> _myBuilds = [];
  bool _isBuildsLoading = true;
  String? _buildsError;

  bool _isLoading = false;
  Map<String, dynamic>? _benchmarkClassification;
  String? _benchmarkRecommendation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMyBuilds();
  }

  @override
  void dispose() {
    _componentSearchController.dispose();
    _gameSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyBuilds() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final apiClient = Provider.of<ApiClient>(context, listen: false);
        final builds = await apiClient.getMyBuilds();
        setState(() {
          _myBuilds = builds;
          _isBuildsLoading = false;
        });
      } catch (e) {
        setState(() {
          _buildsError = e.toString();
          _isBuildsLoading = false;
        });
      }
    });
  }

  // --- FUNCIÓN _runBenchmark (MODIFICADA CON VALIDACIÓN) ---
  Future<void> _runBenchmark() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _benchmarkClassification = null;
      _benchmarkRecommendation = null;
    });

    // --- NUEVA VALIDACIÓN ---
    if (_selectedBuild == null && _componentSearchController.text.isNotEmpty) {
      String component = _componentSearchController.text.toLowerCase();
      // Heurística de validación
      bool isGpu =
          component.contains('rtx') ||
          component.contains('geforce') ||
          component.contains('radeon') ||
          component.contains('arc');
      bool isCpu =
          component.contains('ryzen') ||
          component.contains('core') ||
          component.contains('i5') ||
          component.contains('i7') ||
          component.contains('i9') ||
          component.contains('threadripper') ||
          component.contains('xeon');

      if (!isGpu && !isCpu) {
        // Si no es válido, muestra el "SweetAlert"
        _showInvalidComponentAlert();
        setState(() {
          _isLoading = false; // Detener el spinner
        });
        return; // Detener la ejecución
      }
    }
    // --- FIN DE LA VALIDACIÓN ---

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);

      Map<String, dynamic> requestBody = {
        'scenario': _gameSearchController.text,
      };

      if (_selectedBuild != null) {
        requestBody['cpu_model'] = _selectedBuild!.cpuName;
        requestBody['gpu_model'] = _selectedBuild!.gpuName;
      } else {
        // La lógica de componente individual (ya validada arriba)
        String component = _componentSearchController.text.toLowerCase();
        if (component.contains('rtx') ||
            component.contains('geforce') ||
            component.contains('radeon') ||
            component.contains('arc')) {
          requestBody['gpu_model'] = _componentSearchController.text;
        } else {
          requestBody['cpu_model'] = _componentSearchController.text;
        }
      }

      final Map<String, dynamic> jsonResponse = await apiClient.runBenchmark(
        requestBody,
      );

      setState(() {
        _benchmarkClassification =
            jsonResponse['classification'] as Map<String, dynamic>?;
        _benchmarkRecommendation = jsonResponse['gemini_reco'] as String?;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- NUEVO HELPER: "SWEETALERT" ---
  void _showInvalidComponentAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1C),
        title: const Text(
          'Componente No Válido',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'El texto que ingresaste no parece ser una CPU o GPU reconocida. Por favor, usa un nombre de modelo (ej: "RTX 4070" o "Ryzen 5 5600").',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            child: Text(
              'Entendido',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  // --- FIN DE NUEVO HELPER ---

  @override
  Widget build(BuildContext context) {
    final bool canRunBenchmark =
        (_componentSearchController.text.isNotEmpty ||
            _selectedBuild != null) &&
        _gameSearchController.text.isNotEmpty &&
        !_isLoading;

    return SingleChildScrollView(
      // ... (Resto del build, sin cambios en la estructura)
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Benchmarks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Compara el rendimiento estimado de componentes y builds.',
                      style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Component Search Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscar Componente Individual',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _selectedBuild != null
                            ? Colors.grey[600] // Atenuado
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchField(
                      controller: _componentSearchController,
                      hintText: 'Ej: RTX 4070, Ryzen 7 7800X3D...',
                      enabled:
                          _selectedBuild ==
                          null, // Deshabilitado si se selecciona build
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Builds Selector Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comparar Mis Builds Guardadas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _componentSearchController.text.isNotEmpty
                            ? Colors.grey[600] // Atenuado
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBuildSelector(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Game/Program Search Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona Programa/Juego',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchField(
                      controller: _gameSearchController,
                      hintText:
                          'Busca Programa/Juego (Ej: Cyberpunk, Blender...)',
                      enabled: true,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: canRunBenchmark ? _runBenchmark : null,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Ejecutar Benchmark Específico'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Performance Visualization Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visualización de Rendimiento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withOpacity(0.3),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: _buildPerformanceChild(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recommendations Section
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recomendación Personalizada',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLoading
                          ? 'Analizando...'
                          : _benchmarkRecommendation?.replaceAll(r'\n', '\n') ??
                                'Aquí aparecerá la recomendación de la IA después de ejecutar el benchmark.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- (Widgets _buildPerformanceChild y _buildBarChart sin cambios) ---
  Widget _buildPerformanceChild() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC7384D)),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        ),
      );
    }
    if (_benchmarkClassification != null &&
        _benchmarkClassification!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildBarChart(_benchmarkClassification!),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, color: Colors.grey[700], size: 60),
          const SizedBox(height: 16),
          Text(
            'Los resultados del benchmark (FPS) aparecerán aquí.',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> fpsData) {
    final List<BarChartGroupData> barGroups = [];
    final List<String> resolutions = ['1080p', '1440p', '4K'];
    double maxY = 0;

    int index = 0;
    for (String res in resolutions) {
      final num? fpsNum = fpsData[res];
      final double fps = (fpsNum ?? 0).toDouble();

      if (fps > maxY) maxY = fps;

      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: fps,
              color: Theme.of(context).primaryColor,
              width: 25,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
      index++;
    }

    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY < 60) maxY = 60;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} FPS',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                String text;
                switch (value.toInt()) {
                  case 0:
                    text = '1080p';
                    break;
                  case 1:
                    text = '1440p';
                    break;
                  case 2:
                    text = '4K';
                    break;
                  default:
                    text = '';
                    break;
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8.0,
                  child: Text(
                    text,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (maxY / 4).floorToDouble(),
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0 || value == maxY) return Container();
                return Text(
                  value.round().toString(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4).floorToDouble(),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[850]!, strokeWidth: 1);
          },
        ),
        barGroups: barGroups,
      ),
    );
  }

  // --- (Helper _buildGlassCard sin cambios) ---
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    );
  }

  // --- WIDGET _buildSearchField (MODIFICADO) ---
  // Lógica de exclusión mutua
  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(color: enabled ? Colors.white : Colors.grey[600]),
      onChanged: (text) => setState(() {
        if (controller == _componentSearchController && text.isNotEmpty) {
          _selectedBuild = null; // Limpia el dropdown si se escribe aquí
        } else {
          // Solo actualiza estado para habilitar/deshabilitar botón
          setState(() {});
        }
      }),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
        filled: true,
        fillColor: enabled
            ? theme.inputDecorationTheme.fillColor ??
                  Colors.black.withOpacity(0.4)
            : Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              theme.inputDecorationTheme.focusedBorder?.borderSide ??
              const BorderSide(color: Color(0xFFC7384D), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
  // --- FIN DE MODIFICACIÓN ---

  // --- WIDGET _buildBuildSelector (MODIFICADO) ---
  // Lógica de exclusión mutua
  Widget _buildBuildSelector() {
    final theme = Theme.of(context);
    final bool isEnabled = _componentSearchController.text.isEmpty;

    if (_isBuildsLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_buildsError != null) {
      return Text(
        'Error al cargar builds: $_buildsError',
        style: const TextStyle(color: Colors.redAccent),
      );
    }

    if (_myBuilds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        alignment: Alignment.centerLeft,
        child: Text(
          'No tienes builds guardadas. ¡Crea una en la sección "Mis Builds"!',
          style: TextStyle(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Placeholder
    List<DropdownMenuItem<BuildSummary?>> dropdownItems = [
      DropdownMenuItem<BuildSummary?>(
        value: null,
        enabled: false,
        child: Text(
          'Selecciona tu Build Guardada',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    ];

    // Builds del usuario
    dropdownItems.addAll(
      _myBuilds.map((build) {
        return DropdownMenuItem<BuildSummary?>(
          value: build, // El valor es el objeto BuildSummary
          child: Text(
            build.name,
            style: TextStyle(
              color: isEnabled ? Colors.white : Colors.grey[600],
            ),
          ),
        );
      }).toList(),
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 448),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled
            ? theme.inputDecorationTheme.fillColor ??
                  Colors.black.withOpacity(0.4)
            : Colors.black.withOpacity(0.2), // Atenuado
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BuildSummary?>(
          value: _selectedBuild,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: Colors.grey[500]),
          dropdownColor: const Color(0xFF1C1C1C),
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.grey[600],
            fontSize: 16,
          ),
          items: dropdownItems,
          onChanged: isEnabled
              ? (value) {
                  setState(() {
                    _selectedBuild =
                        value; // Asigna el objeto BuildSummary o null
                    // --- ¡LA CORRECCIÓN DE UX ESTÁ AQUÍ! ---
                    if (value != null) {
                      // Si selecciona una build, limpia el texto
                      _componentSearchController.clear();
                    }
                  });
                }
              : null, // Deshabilitado si hay texto en el buscador
        ),
      ),
    );
  }

  // --- FIN DE MODIFICACIÓN ---
}
