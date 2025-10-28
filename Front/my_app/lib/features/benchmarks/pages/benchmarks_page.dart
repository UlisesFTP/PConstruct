import 'package:flutter/material.dart';
import 'dart:ui';

class BenchmarksPage extends StatefulWidget {
  const BenchmarksPage({super.key});

  @override
  State<BenchmarksPage> createState() => _BenchmarksPageState();
}

class _BenchmarksPageState extends State<BenchmarksPage> {
  final TextEditingController _componentSearchController =
      TextEditingController();
  final TextEditingController _gameSearchController =
      TextEditingController(); // Ya existe
  String _selectedBuild = '';

  final List<Map<String, String>> builds = [
    {'value': '', 'label': 'Selecciona tu Build Guardada'},
    {'value': 'build1', 'label': 'Build Gaming 2024'},
    {'value': 'build2', 'label': 'Build Workstation'},
    {'value': 'build3', 'label': 'Build Edición de Video'},
  ];

  @override
  void dispose() {
    _componentSearchController.dispose();
    _gameSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    const Text(
                      'Buscar Componente Individual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchField(
                      controller: _componentSearchController,
                      hintText: 'Ej: RTX 4070, Ryzen 7 7800X3D...',
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
                    const Text(
                      'Comparar Mis Builds Guardadas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBuildSelector(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- NUEVO: Game/Program Search Card ---
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
                      controller:
                          _gameSearchController, // Usa el controlador existente
                      hintText:
                          'Busca Programa/Juego (Ej: Cyberpunk, Blender...)',
                      // TODO: Añadir lógica de búsqueda/sugerencias para juegos/programas
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        // Habilitar solo si hay algo seleccionado (componente o build) Y un juego/programa
                        onPressed:
                            (_componentSearchController.text.isNotEmpty ||
                                    _selectedBuild.isNotEmpty) &&
                                _gameSearchController.text.isNotEmpty
                            ? () {
                                /* TODO: Ejecutar benchmark específico */
                              }
                            : null,
                        child: const Text('Ejecutar Benchmark Específico'),
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
              // --- FIN NUEVO ---

              // Performance Visualization Card (Placeholder)
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
                      child: Center(/* ... Icono y texto placeholder ... */),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- NUEVO: Recommendations Section ---
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuraciones Recomendadas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Basado en tu selección actual, podríamos recomendar las siguientes optimizaciones o componentes alternativos:\n' // Ejemplo
                      '- Para juegos a 1440p, considera una GPU RX 7800 XT.\n'
                      '- Si usas Blender, aumentar la RAM a 32GB podría mejorar los tiempos de renderizado.\n'
                      '- Para presupuestos ajustados, el Ryzen 5 5600 sigue siendo una excelente opción.', // Texto estático/ejemplo
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                        height: 1.5, // Mejorar legibilidad
                      ),
                    ),
                    // Podrías añadir botones aquí si las recomendaciones fueran interactivas
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- FIN NUEVO ---
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildGlassCard({required Widget child}) {
    // ... (sin cambios)
    return Container(
      width: double.infinity, // Ensure card takes full width
      margin: const EdgeInsets.only(
        bottom: 0,
      ), // Remove default margin if wrapped
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface.withOpacity(0.6), // Use theme surface
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Adjusted blur
          child: Padding(
            // Add padding *inside* the filter
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
  }) {
    // ... (sin cambios)
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
        filled: true,
        fillColor:
            theme.inputDecorationTheme.fillColor ??
            Colors.black.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ), // Use theme border style
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
        ), // Adjusted padding
      ),
    );
  }

  Widget _buildBuildSelector() {
    // ... (sin cambios)
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 448,
      ), // Max width for dropdown
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color:
            theme.inputDecorationTheme.fillColor ??
            Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          // Use first item's value if _selectedBuild is empty, otherwise use _selectedBuild
          value: _selectedBuild.isEmpty
              ? builds.first['value']
              : _selectedBuild,
          hint: Text(
            builds.first['label']!,
            style: TextStyle(color: Colors.grey[500]),
          ), // Use first item as hint text
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: Colors.grey[500]),
          dropdownColor: const Color(0xFF1C1C1C), // Dark dropdown background
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: builds.map((build) {
            // Map ALL items including the placeholder
            return DropdownMenuItem<String>(
              value: build['value'],
              // Disable the placeholder item
              enabled: build['value']!.isNotEmpty,
              child: Text(
                build['label']!,
                style: TextStyle(
                  // Grey out the placeholder text
                  color: build['value']!.isEmpty
                      ? Colors.grey[600]
                      : Colors.white,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              // Don't allow selecting the placeholder value directly
              _selectedBuild = (value != null && value.isNotEmpty) ? value : '';
              // TODO: Load benchmark data for the selected build if value is not empty
            });
          },
        ),
      ),
    );
  }
}
