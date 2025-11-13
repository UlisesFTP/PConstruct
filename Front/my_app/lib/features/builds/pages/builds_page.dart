import 'package:flutter/material.dart';
import 'dart:ui'; // Necesario para BackdropFilter
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
// Importamos el nuevo modelo y quitamos el mock
import 'package:my_app/models/build.dart';
// Para formatear fechas (timeago)
import 'package:timeago/timeago.dart' as timeago;
import 'package:my_app/core/widgets/builds_chat.dart';
import 'package:my_app/core/api/builds_chat_api.dart';

// ❌ Eliminamos la clase mock 'CommunityBuild'
// class CommunityBuild { ... }

class BuildsPage extends StatefulWidget {
  const BuildsPage({super.key});

  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  // Controladores de filtros (se mantienen)
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cpuController = TextEditingController();
  final TextEditingController _gpuController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _ramController = TextEditingController();
  String _selectedUseType = 'Todos';

  // ❌ Eliminamos la lista de datos mock
  // final List<CommunityBuild> communityBuilds = [ ... ];

  // ¡NUEVO ESTADO!
  late Future<List<BuildSummary>> _buildsFuture;
  late ApiClient _apiClient;
  late final BuildsChatApi _chatApi;

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    _chatApi = BuildsChatApi('http://localhost:8000');

    // Seteamos el idioma para timeago
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _loadBuilds();
  }

  // Nueva función para cargar o refrescar las builds
  void _loadBuilds() {
    // TODO: Usar los controladores de filtros para la llamada a la API
    setState(() {
      _buildsFuture = _apiClient.getCommunityBuilds();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cpuController.dispose();
    _gpuController.dispose();
    _budgetController.dispose();
    _ramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showSidebar = MediaQuery.of(context).size.width > 1024;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 896),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header (se mantiene igual)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Builds de la comunidad',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: _inputDecoration(
                                    hintText: 'Buscar builds...',
                                  ),
                                  onChanged: (value) {
                                    // TODO: Implementar debouncing y búsqueda
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ¡NUEVO: FUTURE BUILDER!
                        FutureBuilder<List<BuildSummary>>(
                          future: _buildsFuture,
                          builder: (context, snapshot) {
                            // 1. Estado de Carga
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            // 2. Estado de Error
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    'Error al cargar las builds: ${snapshot.error}',
                                    style: TextStyle(color: Colors.grey[400]),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            // 3. Estado sin Datos
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    'Aún no hay builds en la comunidad.',
                                    style: TextStyle(color: Colors.grey[400]),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }

                            // 4. Estado con Datos
                            final builds = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: builds.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),

                                  // --- ¡CORRECCIÓN AQUÍ! ---
                                  // Se pasa como un argumento posicional, no nombrado.
                                  child: _CommunityBuildCard(
                                    builds[index], // <-- Se quita 'build:'
                                  ),

                                  // --- FIN DE LA CORRECCIÓN ---
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (showSidebar) _buildSidebar(),
          ],
        ),
        // Botón FAB (se mantiene igual)

        // === FAB de Chat (izquierda del +) ===
        Positioned(
          bottom: 24,
          right: 96, // 24 (margen) + 60 (ancho del +) + 12 (espacio)
          child: SizedBox(
            width: 60,
            height: 60,
            child: Material(
              color: const Color(0xFFC7384D),
              shape: const CircleBorder(),
              elevation: 6,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BuildsChatSheet(api: _chatApi),
                  );
                },
                child: const Center(
                  child: Icon(Icons.chat_bubble, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 24,
          right: 24,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFC7384D),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC7384D).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/builds/create');
                },
                customBorder: const CircleBorder(),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGETS INTERNOS (MODIFICADOS) ---

  // ¡WIDGET DE TARJETA ACTUALIZADO!
  // La definición es correcta (acepta un argumento posicional)
  Widget _CommunityBuildCard(BuildSummary build) {
    final timeAgoString = timeago.format(
      build.createdAt.toLocal(),
      locale: 'es',
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(28, 28, 28, 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Avatar, Nombre de Usuario, Tiempo)
                Row(
                  children: [
                    // TODO: Reemplazar con avatar real cuando esté en la API
                    const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          build.userName, // <-- Dato real
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          timeAgoString, // <-- Dato real (formateado)
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFA0A0A0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Título de la build
                Text(
                  build.name, // <-- Dato real (es el 'title' de la build)
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                // ❌ Descripción eliminada (no está en BuildSummary)

                // Imagen (si existe)
                if (build.imageUrl != null && build.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      build.imageUrl!, // <-- Dato real
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // ¡NUEVO: Componentes clave!
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildSpec(Icons.memory, 'CPU:', build.cpuName ?? 'N/A'),
                    _buildSpec(
                      Icons.developer_board,
                      'GPU:',
                      build.gpuName ?? 'N/A',
                    ),
                    _buildSpec(Icons.dns, 'RAM:', build.ramName ?? 'N/A'),
                  ],
                ),

                // Footer (Likes / Ver Detalles)
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // TODO: Añadir 'likes' al backend y conectarlo aquí
                      Row(
                        children: const [
                          Icon(
                            Icons.whatshot,
                            color: Color(0xFFA0A0A0), // Apagado por ahora
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '0', // Placeholder
                            style: TextStyle(color: Color(0xFFA0A0A0)),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          // TODO: Navegar al detalle de la build
                          // Navigator.pushNamed(context, '/build-detail', arguments: build.id);
                        },
                        child: Row(
                          children: const [
                            Icon(
                              Icons.visibility,
                              color: Color(0xFFA0A0A0),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Ver Detalles',
                              style: TextStyle(color: Color(0xFFA0A0A0)),
                            ),
                          ],
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

  // Helper para mostrar specs (copiado de my_builds_page)
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

  // Sidebar (sin cambios)
  Widget _buildSidebar() {
    // ... (Tu código de _buildSidebar se mantiene igual)
    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C).withOpacity(0.8),
        border: const Border(left: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildFilterField(
              // Can call other state methods
              label: 'Tipo de uso',
              child: DropdownButtonFormField<String>(
                value: _selectedUseType, // Access state variable
                decoration: _inputDecoration(), // Call state method
                dropdownColor: const Color(0xFF1C1C1C),
                items: ['Todos', 'Gaming', 'Oficina', 'Edición', 'Programación']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUseType = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterField(
              label: 'CPU (contiene)',
              child: TextField(
                controller: _cpuController, // Access state variable
                decoration: _inputDecoration(hintText: 'Ej: Ryzen 7, i9'),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterField(
              label: 'GPU (contiene)',
              child: TextField(
                controller: _gpuController, // Access state variable
                decoration: _inputDecoration(hintText: 'Ej: RTX 4070, RX 6800'),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterField(
              label: 'Presupuesto máximo',
              child: TextField(
                controller: _budgetController, // Access state variable
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(hintText: '\$ MXN'),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterField(
              label: 'RAM mínima',
              child: TextField(
                controller: _ramController, // Access state variable
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(hintText: 'GB'),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Llamar a _loadBuilds() con los filtros aplicados
                  print("Aplicar filtros");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC7384D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Aplicar Filtros",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildFilterField (sin cambios)
  Widget _buildFilterField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // _inputDecoration (sin cambios)
  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.black.withOpacity(0.4),
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC7384D), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
    );
  }
}
