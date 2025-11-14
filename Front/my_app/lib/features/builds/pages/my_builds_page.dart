// lib/features/builds/pages/my_builds_page.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/build.dart';
import 'package:intl/intl.dart';

class MyBuildsPage extends StatefulWidget {
  const MyBuildsPage({super.key});

  @override
  State<MyBuildsPage> createState() => _MyBuildsPageState();
}

class _MyBuildsPageState extends State<MyBuildsPage> {
  late Future<List<BuildSummary>> _buildsFuture;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    _loadBuilds();
  }

  void _loadBuilds() {
    setState(() {
      _buildsFuture = _apiClient.getMyBuilds();
    });
  }

  Future<void> _deleteBuild(String buildId) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1C),
            title: const Text(
              'Confirmar Eliminación',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              '¿Estás seguro de que deseas eliminar esta build? Esta acción no se puede deshacer.',
              style: TextStyle(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(
                  'Eliminar',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _apiClient.deleteBuild(buildId);
        _loadBuilds();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Build eliminada exitosamente'),
            backgroundColor: Color.fromARGB(255, 192, 26, 62),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la build: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 24,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y botón
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Builds',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/builds/create');
                    },
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    label: const Text(
                      'Crear Nueva Build',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC7384D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // FutureBuilder
              FutureBuilder<List<BuildSummary>>(
                future: _buildsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'Error al cargar tus builds: ${snapshot.error}',
                          style: TextStyle(color: Colors.grey[400]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'Aún no has guardado ninguna build. ¡Crea una!',
                          style: TextStyle(color: Colors.grey[400]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final builds = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: builds.length,
                    itemBuilder: (context, index) {
                      final build = builds[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: BuildCard(
                          // --- CORRECCIÓN 1 ---
                          // Pasamos la variable al nuevo nombre 'buildSummary'
                          buildSummary: build,
                          onDelete: () => _deleteBuild(build.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TARJETA DE BUILD (Actualizada para usar BuildSummary)
class BuildCard extends StatelessWidget {
  // --- CORRECCIÓN 2 ---
  // Renombramos el campo de 'build' a 'buildSummary'
  final BuildSummary buildSummary;
  final VoidCallback onDelete;

  // Actualizamos el constructor
  const BuildCard({
    super.key,
    required this.buildSummary,
    required this.onDelete,
  });

  // El método build() se mantiene igual
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    // Usamos el nuevo nombre de variable
    final String createdDate = formatter.format(
      buildSummary.createdAt.toLocal(),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: const EdgeInsets.all(24.0),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContent(context, createdDate),
                    const SizedBox(height: 16),
                    _buildActions(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildContent(context, createdDate)),
                    const SizedBox(width: 16),
                    _buildActions(),
                  ],
                ),
        ),
      ),
    );
  }

  // --- CORRECCIÓN 3 ---
  // Usamos 'buildSummary' en lugar de 'build'
  Widget _buildContent(BuildContext context, String createdDate) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
    );
    // Usamos el nuevo nombre de variable
    final String totalPrice = currencyFormatter.format(buildSummary.totalPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                buildSummary.name, // <-- Dato real
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              totalPrice, // <-- Dato real (formateado)
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Creada el: $createdDate', // <-- Dato real (formateado)
          style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            // Usamos el nuevo nombre de variable
            _buildSpec(Icons.memory, 'CPU:', buildSummary.cpuName ?? 'N/A'),
            _buildSpec(
              Icons.developer_board,
              'GPU:',
              buildSummary.gpuName ?? 'N/A',
            ),
            _buildSpec(Icons.dns, 'RAM:', buildSummary.ramName ?? 'N/A'),
          ],
        ),
      ],
    );
  }

  Widget _buildSpec(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFC7384D), size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            // TODO: Navegar a la página de detalle de la build
            // (requerirá pasar buildSummary.id)
          },
          icon: const Icon(Icons.visibility, color: Color(0xFFE0E0E0)),
          tooltip: 'Ver detalles',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            // TODO: Navegar a la página de edición
            // (requerirá pasar la build completa o su id)
          },
          icon: const Icon(Icons.edit, color: Color(0xFFE0E0E0)),
          tooltip: 'Editar build',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onDelete, // ¡Acción conectada!
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Eliminar build',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        ),
      ],
    );
  }
}
