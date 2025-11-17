// lib/features/builds/pages/builds_page.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/build.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:my_app/core/widgets/builds_chat.dart';
import 'package:my_app/core/api/builds_chat_api.dart';
import 'package:intl/intl.dart';
// --- NUEVAS IMPORTACIONES ---
import 'package:my_app/core/widgets/builds_comments_modal.dart';
import 'package:my_app/models/build_comment.dart';
// --- FIN DE NUEVAS IMPORTACIONES ---

class BuildsPage extends StatefulWidget {
  const BuildsPage({super.key});

  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  final TextEditingController _cpuController = TextEditingController();
  final TextEditingController _gpuController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
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
    final maxPrice = double.tryParse(_budgetController.text);
    setState(() {
      _buildsFuture = _apiClient.getCommunityBuilds(
        useType: _selectedUseType,
        cpu: _cpuController.text.trim(),
        gpu: _gpuController.text.trim(),
        maxPrice: (maxPrice != null && maxPrice > 0) ? maxPrice : null,
      );
    });
  }

  @override
  void dispose() {
    _cpuController.dispose();
    _gpuController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _showFiltersBottomSheet() {
    // ... (Esta función de modal no cambia en absoluto)
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
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadBuilds(); // Aplica los filtros
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
                        // Header (sin cambios)
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
                        ] else if (isTablet) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        ] else ...[
                          const Text(
                            'Builds de la comunidad',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                                    'No se encontraron builds con esos filtros.',
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
                                  // --- CAMBIO: Pasamos el ApiClient ---
                                  child: _CommunityBuildCard(
                                    builds[index], // <-- Renombrado para claridad (pasado como argumento posicional)
                                    isMobile: isMobile,
                                    apiClient: _apiClient,
                                  ),
                                );
                              },
                            );
                          },
                        ),
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
        // FABs (sin cambios)
        if (isMobile) ...[
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

  // --- Widgets de Sidebar y Filtros (sin cambios) ---
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadBuilds,
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

// =======================================================
// --- WIDGET DE TARJETA DE BUILD (AHORA STATEFUL) ---
// =======================================================
class _CommunityBuildCard extends StatefulWidget {
  final BuildSummary build;
  final bool isMobile;
  final ApiClient apiClient;

  const _CommunityBuildCard(
    this.build, {
    required this.isMobile,
    required this.apiClient,
  });

  @override
  State<_CommunityBuildCard> createState() => _CommunityBuildCardState();
}

class _CommunityBuildCardState extends State<_CommunityBuildCard> {
  // --- LÓGICA DE ESTADO (COMO EN POSTCARD) ---
  late int localLikesCount;
  late int localCommentsCount;
  late bool isLiked;
  bool isLoadingLike = false;

  final currencyFormatter = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    localLikesCount = widget.build.likes_count;
    localCommentsCount = widget.build.comments_count;
    isLiked = widget.build.is_liked_by_user;
  }

  void _handleLike() async {
    if (isLoadingLike) return;

    setState(() {
      isLoadingLike = true;
      if (isLiked) {
        localLikesCount--;
        isLiked = false;
      } else {
        localLikesCount++;
        isLiked = true;
      }
    });

    try {
      if (!isLiked) {
        await widget.apiClient.unlikeBuild(widget.build.id);
      } else {
        await widget.apiClient.likeBuild(widget.build.id);
      }
      if (mounted) {
        setState(() {
          isLoadingLike = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Revertir el estado si hay error
        setState(() {
          if (isLiked) {
            localLikesCount--;
            isLiked = false;
          } else {
            localLikesCount++;
            isLiked = true;
          }
          isLoadingLike = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reaccionar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1C),
      builder: (modalContext) {
        return BuildsCommentsModal(
          buildId: widget.build.id,
          // TODO: Añadir callback para actualizar contador
        );
      },
    );
  }

  void _openComponents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BuildComponentsModal(
        buildId: widget.build.id,
        apiClient: widget.apiClient,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeAgoString = timeago.format(
      widget.build.createdAt.toLocal(),
      locale: 'es',
    );
    final totalPrice = currencyFormatter.format(widget.build.totalPrice);

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(28, 28, 28, 0.8),
        borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.isMobile ? 12 : 16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: widget.isMobile ? 20 : 24,
                          child: const Icon(Icons.person),
                        ),
                        SizedBox(width: widget.isMobile ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.build.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: widget.isMobile ? 14 : 16,
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
                    SizedBox(height: widget.isMobile ? 20 : 24),
                    // Título
                    Text(
                      widget.build.name,
                      style: TextStyle(
                        fontSize: widget.isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Imagen
                    if (widget.build.imageUrl != null &&
                        widget.build.imageUrl!.isNotEmpty) ...[
                      SizedBox(height: widget.isMobile ? 12 : 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.build.imageUrl!,
                          width: double.infinity,
                          height: widget.isMobile ? 180 : 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: widget.isMobile ? 180 : 200,
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
                    SizedBox(height: widget.isMobile ? 12 : 16),
                    // Componentes clave
                    _buildSpec(
                      Icons.memory,
                      'CPU:',
                      widget.build.cpuName ?? 'N/A',
                      isMobile: widget.isMobile,
                    ),
                    const SizedBox(height: 8),
                    _buildSpec(
                      Icons.developer_board,
                      'GPU:',
                      widget.build.gpuName ?? 'N/A',
                      isMobile: widget.isMobile,
                    ),
                    SizedBox(height: widget.isMobile ? 12 : 16),
                    // Footer
                    Container(
                      padding: EdgeInsets.only(top: widget.isMobile ? 12 : 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF2A2A2A)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLikeButton(),
                          _buildCommentsButton(),
                          _buildComponentsButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Precio Total
              Positioned(
                top: widget.isMobile ? 16 : 24,
                right: widget.isMobile ? 16 : 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    totalPrice,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NUEVO: Botón de Like (copiado de PostCard) ---
  Widget _buildLikeButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isLiked
            ? const Color.fromARGB(255, 197, 0, 69).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLiked
              ? const Color.fromARGB(100, 197, 0, 69)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleLike,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isLiked ? Icons.whatshot : Icons.whatshot_outlined,
                    color: isLiked
                        ? const Color(0xFFC7384D)
                        : const Color(0xFFA0A0A0),
                    size: 22,
                    key: ValueKey<bool>(isLiked),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    localLikesCount.toString(),
                    style: TextStyle(
                      color: isLiked
                          ? const Color(0xFFC7384D)
                          : const Color(0xFFA0A0A0),
                      fontSize: 15,
                      fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                    ),
                    key: ValueKey<int>(localLikesCount),
                  ),
                ),
                if (isLoadingLike) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLiked
                            ? const Color(0xFFC7384D)
                            : const Color(0xFFA0A0A0),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NUEVO: Botón de Comentarios (adaptado) ---
  Widget _buildCommentsButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openComments,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localCommentsCount.toString(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NUEVO: Botón de Componentes (adaptado) ---
  Widget _buildComponentsButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openComponents,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.view_list_outlined,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              if (!widget.isMobile)
                Text(
                  "Componentes",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MODAL DE COMPONENTES (Sin cambios) ---
class _BuildComponentsModal extends StatelessWidget {
  final String buildId;
  final ApiClient apiClient;

  const _BuildComponentsModal({required this.buildId, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Componentes de la Build',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            Expanded(
              child: FutureBuilder<BuildRead>(
                future: apiClient.getBuildDetail(buildId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar detalles: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text('No se encontró la build.'),
                    );
                  }

                  final build = snapshot.data!;
                  final components = build.components;

                  return ListView.separated(
                    controller: controller,
                    itemCount: components.length,
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final comp = components[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                comp.imageUrl ?? '',
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[800],
                                    child: Icon(
                                      Icons.memory,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comp.category.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    comp.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              currencyFormatter.format(comp.priceAtBuildTime),
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widgets de Sidebar y Filtros (sin cambios) ---
Widget _buildSpec(
  IconData icon,
  String label,
  String value, {
  bool isMobile = false,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: const Color(0xFFA0A0A0), size: isMobile ? 18 : 20),
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
              value: 'Todos', // Hardcoded
              decoration: _inputDecoration(),
              dropdownColor: const Color(0xFF1C1C1C),
              items: ['Todos', 'Gaming', 'Oficina', 'Edición', 'Programación']
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) {
                // setState(() {
                //   _selectedUseType = value!;
                // });
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildFilterField(
            label: 'CPU (contiene)',
            child: TextField(
              controller: TextEditingController(), // Hardcoded
              decoration: _inputDecoration(hintText: 'Ej: Ryzen 7, i9'),
              onChanged: (v) => {},
            ),
          ),
          const SizedBox(height: 16),
          _buildFilterField(
            label: 'GPU (contiene)',
            child: TextField(
              controller: TextEditingController(), // Hardcoded
              decoration: _inputDecoration(hintText: 'Ej: RTX 4070, RX 6800'),
              onChanged: (v) => {},
            ),
          ),
          const SizedBox(height: 16),
          _buildFilterField(
            label: 'Presupuesto máximo',
            child: TextField(
              controller: TextEditingController(), // Hardcoded
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(hintText: '\$ MXN'),
              onChanged: (v) => {},
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {}, // Hardcoded
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
