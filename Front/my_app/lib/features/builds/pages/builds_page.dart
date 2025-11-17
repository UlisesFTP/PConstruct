import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/build.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:my_app/core/widgets/builds_chat.dart';
import 'package:my_app/core/api/builds_chat_api.dart';

class BuildsPage extends StatefulWidget {
  const BuildsPage({super.key});

  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cpuController = TextEditingController();
  final TextEditingController _gpuController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _ramController = TextEditingController();
  String _selectedUseType = 'Todos';

  late Future<List<BuildSummary>> _buildsFuture;
  late ApiClient _apiClient;
  late final BuildsChatApi _chatApi;

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    _chatApi = BuildsChatApi('http://localhost:8000');
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _loadBuilds();
  }

  void _loadBuilds() {
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

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildFilterField(
                      label: 'Tipo de uso',
                      child: DropdownButtonFormField<String>(
                        value: _selectedUseType,
                        decoration: _inputDecoration(),
                        dropdownColor: const Color(0xFF1C1C1C),
                        items:
                            [
                                  'Todos',
                                  'Gaming',
                                  'Oficina',
                                  'Edición',
                                  'Programación',
                                ]
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
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
                        controller: _cpuController,
                        decoration: _inputDecoration(
                          hintText: 'Ej: Ryzen 7, i9',
                        ),
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterField(
                      label: 'GPU (contiene)',
                      child: TextField(
                        controller: _gpuController,
                        decoration: _inputDecoration(
                          hintText: 'Ej: RTX 4070, RX 6800',
                        ),
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterField(
                      label: 'Presupuesto máximo',
                      child: TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(hintText: '\$ MXN'),
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterField(
                      label: 'RAM mínima',
                      child: TextField(
                        controller: _ramController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(hintText: 'GB'),
                        onChanged: (v) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Llamar a _loadBuilds() con los filtros aplicados
                          print("Aplicar filtros");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC7384D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Aplicar Filtros",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool showSidebar = screenWidth > 1024;
    final bool isMobile = screenWidth < 768;
    final bool isTablet = screenWidth >= 768 && screenWidth <= 1024;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 896),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header responsive
                        if (isMobile) ...[
                          const Text(
                            'Builds de la comunidad',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
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
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC7384D),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.filter_list,
                                    color: Colors.white,
                                  ),
                                  onPressed: _showFiltersBottomSheet,
                                ),
                              ),
                            ],
                          ),
                        ] else if (isTablet) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Builds de la comunidad',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC7384D),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.filter_list,
                                        color: Colors.white,
                                      ),
                                      onPressed: _showFiltersBottomSheet,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _searchController,
                                decoration: _inputDecoration(
                                  hintText: 'Buscar builds...',
                                ),
                                onChanged: (value) {
                                  // TODO: Implementar debouncing y búsqueda
                                },
                              ),
                            ],
                          ),
                        ] else ...[
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
                        ],
                        SizedBox(height: isMobile ? 24 : 32),

                        // FutureBuilder
                        FutureBuilder<List<BuildSummary>>(
                          future: _buildsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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
                                    'Error al cargar las builds: ${snapshot.error}',
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
                                    'Aún no hay builds en la comunidad.',
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
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isMobile ? 16.0 : 24.0,
                                  ),
                                  child: _CommunityBuildCard(
                                    builds[index],
                                    isMobile: isMobile,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        // Espacio adicional en móvil para los FABs
                        if (isMobile) const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (showSidebar) _buildSidebar(),
          ],
        ),

        // FABs responsivos
        if (isMobile) ...[
          // Chat FAB (móvil - izquierda)
          Positioned(
            bottom: 16,
            left: 16,
            child: SizedBox(
              width: 56,
              height: 56,
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
                    child: Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Add FAB (móvil - derecha)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              width: 56,
              height: 56,
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
                    child: Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          // Chat FAB (tablet/desktop)
          Positioned(
            bottom: 24,
            right: 96,
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
                    child: Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Add FAB (tablet/desktop)
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
      ],
    );
  }

  Widget _CommunityBuildCard(BuildSummary build, {required bool isMobile}) {
    final timeAgoString = timeago.format(
      build.createdAt.toLocal(),
      locale: 'es',
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(28, 28, 28, 0.8),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 20 : 24,
                      child: const Icon(Icons.person),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            build.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                          Text(
                            timeAgoString,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFA0A0A0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),
                // Título
                Text(
                  build.name,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Imagen
                if (build.imageUrl != null && build.imageUrl!.isNotEmpty) ...[
                  SizedBox(height: isMobile ? 12 : 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      build.imageUrl!,
                      width: double.infinity,
                      height: isMobile ? 180 : 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: isMobile ? 180 : 200,
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
                SizedBox(height: isMobile ? 12 : 16),
                // Componentes clave
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSpec(
                        Icons.memory,
                        'CPU:',
                        build.cpuName ?? 'N/A',
                        isMobile: true,
                      ),
                      const SizedBox(height: 8),
                      _buildSpec(
                        Icons.developer_board,
                        'GPU:',
                        build.gpuName ?? 'N/A',
                        isMobile: true,
                      ),
                      const SizedBox(height: 8),
                      _buildSpec(
                        Icons.dns,
                        'RAM:',
                        build.ramName ?? 'N/A',
                        isMobile: true,
                      ),
                    ],
                  )
                else
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
                SizedBox(height: isMobile ? 12 : 16),
                // Footer
                Container(
                  padding: EdgeInsets.only(top: isMobile ? 12 : 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.whatshot,
                            color: Color(0xFFA0A0A0),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('0', style: TextStyle(color: Color(0xFFA0A0A0))),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          // TODO: Navegar al detalle de la build
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: Color(0xFFA0A0A0),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isMobile ? 'Ver' : 'Ver Detalles',
                              style: const TextStyle(color: Color(0xFFA0A0A0)),
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

  Widget _buildSpec(
    IconData icon,
    String label,
    String value, {
    bool isMobile = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFC7384D), size: isMobile ? 18 : 20),
        SizedBox(width: isMobile ? 6 : 8),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFFE0E0E0),
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
        SizedBox(width: isMobile ? 3 : 4),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: const Color(0xFFE0E0E0),
              fontSize: isMobile ? 13 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
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
              label: 'Tipo de uso',
              child: DropdownButtonFormField<String>(
                value: _selectedUseType,
                decoration: _inputDecoration(),
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
                controller: _cpuController,
                decoration: _inputDecoration(hintText: 'Ej: Ryzen 7, i9'),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterField(
              label: 'GPU (contiene)',
              child: TextField(
                controller: _gpuController,
                decoration: _inputDecoration(hintText: 'Ej: RTX 4070, RX 6800'),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterField(
              label: 'Presupuesto máximo',
              child: TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(hintText: '\$ MXN'),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterField(
              label: 'RAM mínima',
              child: TextField(
                controller: _ramController,
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
