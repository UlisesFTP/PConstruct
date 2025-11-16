// lib/features/benchmarks/pages/benchmarks_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/build.dart';

class BenchmarksPage extends StatefulWidget {
  const BenchmarksPage({super.key});

  @override
  State<BenchmarksPage> createState() => _BenchmarksPageState();
}

class _BenchmarksPageState extends State<BenchmarksPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _componentSearchController =
      TextEditingController();
  final TextEditingController _gameSearchController = TextEditingController();

  BuildSummary? _selectedBuild;
  List<BuildSummary> _myBuilds = [];
  bool _isBuildsLoading = true;
  String? _buildsError;

  bool _isLoading = false;
  Map<String, dynamic>? _benchmarkClassification;
  String? _benchmarkRecommendation;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fetchMyBuilds();

    // Animación de pulso para el botón
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _componentSearchController.dispose();
    _gameSearchController.dispose();
    _pulseController.dispose();
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

  Future<void> _runBenchmark() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _benchmarkClassification = null;
      _benchmarkRecommendation = null;
    });

    if (_selectedBuild == null && _componentSearchController.text.isNotEmpty) {
      String component = _componentSearchController.text.toLowerCase();
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
        _showInvalidComponentAlert();
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);

      Map<String, dynamic> requestBody = {
        'scenario': _gameSearchController.text,
      };

      if (_selectedBuild != null) {
        requestBody['cpu_model'] = _selectedBuild!.cpuName;
        requestBody['gpu_model'] = _selectedBuild!.gpuName;
      } else {
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

  void _showInvalidComponentAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC7384D).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFC7384D),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Componente No Válido',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'El texto que ingresaste no parece ser una CPU o GPU reconocida. Por favor, usa un nombre de modelo (ej: "RTX 4070" o "Ryzen 5 5600").',
          style: TextStyle(color: Colors.grey[300], height: 1.5),
        ),
        actions: [
          TextButton(
            child: Text(
              'Entendido',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canRunBenchmark =
        (_componentSearchController.text.isNotEmpty ||
            _selectedBuild != null) &&
        _gameSearchController.text.isNotEmpty &&
        !_isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card con decoración
              _buildHeaderCard(),
              const SizedBox(height: 24),

              // Component Search Card
              _buildComponentSearchCard(),
              const SizedBox(height: 24),

              // Builds Selector Card
              _buildBuildsCard(),
              const SizedBox(height: 24),

              // Game/Program Search Card
              _buildGameSearchCard(canRunBenchmark),
              const SizedBox(height: 24),

              // Performance Visualization Card
              _buildPerformanceCard(),
              const SizedBox(height: 24),

              // Recommendations Section
              _buildRecommendationsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFC7384D).withOpacity(0.15),
            Theme.of(context).colorScheme.surface.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC7384D).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC7384D).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                // Icono decorativo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFC7384D), Color(0xFF8B2839)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC7384D).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.speed, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 24),

                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Benchmarks',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC7384D).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFC7384D),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'BETA',
                              style: TextStyle(
                                color: Color(0xFFC7384D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Compara el rendimiento estimado de componentes y builds en diferentes resoluciones.',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComponentSearchCard() {
    return _buildEnhancedGlassCard(
      icon: Icons.search,
      iconColor: Colors.blue[400]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.memory, color: Colors.blue[400], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Buscar Componente Individual',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _selectedBuild != null
                      ? Colors.grey[600]
                      : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchField(
            controller: _componentSearchController,
            hintText: 'Ej: RTX 4070, Ryzen 7 7800X3D...',
            enabled: _selectedBuild == null,
            icon: Icons.search,
          ),
        ],
      ),
    );
  }

  Widget _buildBuildsCard() {
    return _buildEnhancedGlassCard(
      icon: Icons.inventory_2,
      iconColor: Colors.purple[400]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: Colors.purple[400],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Comparar Mis Builds Guardadas',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _componentSearchController.text.isNotEmpty
                      ? Colors.grey[600]
                      : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBuildSelector(),
        ],
      ),
    );
  }

  Widget _buildGameSearchCard(bool canRunBenchmark) {
    return _buildEnhancedGlassCard(
      icon: Icons.sports_esports,
      iconColor: Colors.orange[400]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sports_esports,
                  color: Colors.orange[400],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Selecciona Programa/Juego',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchField(
            controller: _gameSearchController,
            hintText: 'Busca Programa/Juego (Ej: Cyberpunk, Blender...)',
            enabled: true,
            icon: Icons.gamepad,
          ),
          const SizedBox(height: 20),

          // Botón mejorado
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: canRunBenchmark && !_isLoading
                      ? _pulseAnimation.value
                      : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: canRunBenchmark
                          ? const LinearGradient(
                              colors: [Color(0xFFC7384D), Color(0xFF8B2839)],
                            )
                          : null,
                      boxShadow: canRunBenchmark
                          ? [
                              BoxShadow(
                                color: const Color(0xFFC7384D).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: canRunBenchmark ? _runBenchmark : null,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.rocket_launch, size: 20),
                      label: Text(
                        _isLoading ? 'Analizando...' : 'Ejecutar Benchmark',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canRunBenchmark
                            ? Colors.transparent
                            : Colors.grey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return _buildEnhancedGlassCard(
      icon: Icons.bar_chart,
      iconColor: const Color(0xFFC7384D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7384D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bar_chart,
                      color: Color(0xFFC7384D),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Visualización de Rendimiento',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_benchmarkClassification != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7384D).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFC7384D),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFFC7384D),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Completado',
                        style: TextStyle(
                          color: Color(0xFFC7384D),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.2),
                ],
              ),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildPerformanceChild(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return _buildEnhancedGlassCard(
      icon: Icons.lightbulb,
      iconColor: Colors.amber[400]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology,
                  color: Colors.amber[400],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recomendación Personalizada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _benchmarkRecommendation != null
                    ? Colors.amber.withOpacity(0.3)
                    : const Color(0xFF2A2A2A),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_benchmarkRecommendation != null)
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.amber[400],
                    size: 24,
                  ),
                if (_benchmarkRecommendation != null) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isLoading
                        ? 'Analizando rendimiento y generando recomendaciones...'
                        : _benchmarkRecommendation?.replaceAll(r'\n', '\n') ??
                              'Ejecuta un benchmark para recibir recomendaciones personalizadas de la IA basadas en el rendimiento de tus componentes.',
                    style: TextStyle(
                      color: _benchmarkRecommendation != null
                          ? Colors.grey[200]
                          : Colors.grey[500],
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChild() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFC7384D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: Color(0xFFC7384D),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Calculando rendimiento...',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error al ejecutar benchmark',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.show_chart, color: Colors.grey[600], size: 64),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin Resultados',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los resultados del benchmark (FPS) aparecerán aquí.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> fpsData) {
    final List<BarChartGroupData> barGroups = [];
    final List<String> resolutions = ['1080p', '1440p', '4K'];
    final List<Color> barColors = [
      Colors.green[400]!,
      Colors.orange[400]!,
      const Color(0xFFC7384D),
    ];
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
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [barColors[index].withOpacity(0.7), barColors[index]],
              ),
              width: 32,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY * 1.2,
                color: Colors.grey[900]!.withOpacity(0.3),
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
                '${rod.toY.round()} FPS\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                children: [
                  TextSpan(
                    text: resolutions[groupIndex],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
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
                IconData icon;
                switch (value.toInt()) {
                  case 0:
                    text = '1080p';
                    icon = Icons.hd;
                    break;
                  case 1:
                    text = '1440p';
                    icon = Icons.high_quality;
                    break;
                  case 2:
                    text = '4K';
                    icon = Icons.four_k;
                    break;
                  default:
                    text = '';
                    icon = Icons.help_outline;
                    break;
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: barColors[value.toInt()], size: 18),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
              reservedSize: 45,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: (maxY / 4).floorToDouble(),
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0 || value == maxY) return Container();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${value.round()}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[800]!, width: 1),
            left: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4).floorToDouble(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[850]!.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildEnhancedGlassCard({
    required Widget child,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.7),
            Theme.of(context).colorScheme.surface.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFFC7384D).withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.grey[600],
          fontSize: 15,
        ),
        onChanged: (text) => setState(() {
          if (controller == _componentSearchController && text.isNotEmpty) {
            _selectedBuild = null;
          } else {
            setState(() {});
          }
        }),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFFC7384D).withOpacity(0.1)
                  : Colors.grey[800]!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: enabled ? const Color(0xFFC7384D) : Colors.grey[600],
              size: 20,
            ),
          ),
          filled: true,
          fillColor: enabled
              ? Colors.black.withOpacity(0.4)
              : Colors.black.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF2A2A2A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC7384D), width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBuildSelector() {
    final theme = Theme.of(context);
    final bool isEnabled = _componentSearchController.text.isEmpty;

    if (_isBuildsLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFC7384D),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cargando builds...',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_buildsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error al cargar builds: $_buildsError',
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    if (_myBuilds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[300], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No tienes builds guardadas',
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¡Crea una en la sección "Mis Builds"!',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    List<DropdownMenuItem<BuildSummary?>> dropdownItems = [
      DropdownMenuItem<BuildSummary?>(
        value: null,
        enabled: false,
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Selecciona tu Build Guardada',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    ];

    dropdownItems.addAll(
      _myBuilds.map((build) {
        return DropdownMenuItem<BuildSummary?>(
          value: build,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7384D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.computer,
                    size: 16,
                    color: Color(0xFFC7384D),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        build.name,
                        style: TextStyle(
                          color: isEnabled ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (build.cpuName != null || build.gpuName != null)
                        Text(
                          '${build.cpuName ?? "N/A"} • ${build.gpuName ?? "N/A"}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEnabled
              ? [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.3)]
              : [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.2)],
        ),
        border: Border.all(
          color: _selectedBuild != null
              ? const Color(0xFFC7384D).withOpacity(0.5)
              : const Color(0xFF2A2A2A),
          width: _selectedBuild != null ? 1.5 : 1,
        ),
        boxShadow: _selectedBuild != null
            ? [
                BoxShadow(
                  color: const Color(0xFFC7384D).withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<BuildSummary?>(
            value: _selectedBuild,
            isExpanded: true,
            icon: Icon(
              Icons.expand_more,
              color: isEnabled ? const Color(0xFFC7384D) : Colors.grey[600],
            ),
            dropdownColor: const Color(0xFF1A1A1C),
            style: TextStyle(
              color: isEnabled ? Colors.white : Colors.grey[600],
              fontSize: 15,
            ),
            items: dropdownItems,
            onChanged: isEnabled
                ? (value) {
                    setState(() {
                      _selectedBuild = value;
                      if (value != null) {
                        _componentSearchController.clear();
                      }
                    });
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
