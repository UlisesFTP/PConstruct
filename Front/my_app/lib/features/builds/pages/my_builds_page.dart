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
  late ApiClient _apiClient;

  // Estado local: Usamos una lista explícita para manipularla al instante
  List<BuildSummary>? _builds;
  bool _isLoading = true;
  bool _isDeleting = false; // Candado para evitar doble clic
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    _loadBuilds();
  }

  // Carga inicial de datos
  Future<void> _loadBuilds() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final builds = await _apiClient.getMyBuilds();
      if (mounted) {
        setState(() {
          _builds = builds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBuild(String buildId) async {
    // 1. Si ya estamos borrando, ignorar nuevos clics
    if (_isDeleting) return;

    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1C),
            title: const Text(
              'Confirmar Eliminación',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta build? Esta acción no se puede deshacer.',
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isDeleting = true);

    // 2. BORRADO OPTIMISTA:
    // Guardamos copia por si falla
    final previousBuilds = List<BuildSummary>.from(_builds!);

    // Borramos visualmente AHORA MISMO (sin esperar internet)
    setState(() {
      _builds?.removeWhere((b) => b.id == buildId);
    });

    try {
      // 3. Petición al servidor en segundo plano
      await _apiClient.deleteBuild(buildId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Build eliminada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 4. MANEJO INTELIGENTE DE ERRORES
      // Si el error dice "not found" (404), significa que ya se borró (quizás por doble clic).
      // ¡Eso cuenta como éxito! No revertimos la lista.
      final errString = e.toString().toLowerCase();
      if (errString.contains('not found') || errString.contains('404')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Build eliminada (Sincronizado)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Si es otro error (ej. internet), revertimos la lista visualmente
        if (mounted) {
          setState(() {
            _builds = previousBuilds;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      // 5. Liberar el candado siempre
      if (mounted) setState(() => _isDeleting = false);
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
              // Header
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

              // Lógica de carga manual (sin FutureBuilder)
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Text(
                    'Error al cargar: $_errorMessage',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              else if (_builds == null || _builds!.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Aún no has guardado ninguna build. ¡Crea una!',
                      style: TextStyle(color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _builds!.length,
                  itemBuilder: (context, index) {
                    final build = _builds![index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      // Key única para rendimiento
                      key: ValueKey(build.id),
                      child: BuildCard(
                        buildSummary: build,
                        onDelete: () => _deleteBuild(build.id),
                      ),
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

// --- WIDGET DE TARJETA (Sin cambios lógicos, solo estructura) ---
class BuildCard extends StatelessWidget {
  final BuildSummary buildSummary;
  final VoidCallback onDelete;

  const BuildCard({
    super.key,
    required this.buildSummary,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
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

  Widget _buildContent(BuildContext context, String createdDate) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
    );
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
                buildSummary.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              totalPrice,
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
          'Creada el: $createdDate',
          style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
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
            /* Navegar a detalle */
          },
          icon: const Icon(Icons.visibility, color: Color(0xFFE0E0E0)),
          tooltip: 'Ver detalles',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Eliminar build',
        ),
      ],
    );
  }
}
