import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/component.dart';
import 'package:my_app/models/build.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:my_app/core/widgets/builds_chat.dart';
import 'package:my_app/core/api/builds_chat_api.dart';

class BuildConstructorPage extends StatefulWidget {
  BuildConstructorPage({super.key});

  @override
  State<BuildConstructorPage> createState() => _BuildConstructorPageState();
}

class _BuildConstructorPageState extends State<BuildConstructorPage> {
  late ApiClient _apiClient;
  late final BuildsChatApi _chatApi;
  bool _isSaving = false;
  bool _isCheckingCompatibility = false;
  Timer? _debounce;

  final Map<String, Future<PaginatedComponentsResponse>> _componentFutures = {};

  final Map<String, IconData> icons = {
    'cpu': Icons.memory,
    'gpu': Icons.developer_board_outlined,
    'motherboard': Icons.developer_board,
    'ram': Icons.memory_outlined,
    'storage_primary': Icons.save,
    'storage_secondary': Icons.save_alt,
    'cooler': Icons.ac_unit,
    'gabinete': Icons.desktop_windows_outlined,
    'psu': Icons.power,
    'fans': Icons.wind_power,
    'os': Icons.computer,
  };

  final Map<String, String> apiCategoryMap = {
    'cpu': 'CPU',
    'motherboard': 'Motherboard',
    'ram': 'RAM',
    'gpu': 'GPU',
    'storage_primary': 'SSD',
    'storage_secondary': 'HDD',
    'cooler': 'Cooling',
    'gabinete': 'Gabinete',
    'psu': 'PSU',
    'fans': 'Ventiladores',
  };

  final Map<String, String> displayNames = {
    'cpu': 'Cpu',
    'motherboard': 'Motherboard',
    'ram': 'Ram',
    'gpu': 'Gpu',
    'storage_primary': 'Storage Primary (SSD)',
    'storage_secondary': 'Storage Secondary (HDD)',
    'cooler': 'Cooler',
    'gabinete': 'Gabinete',
    'psu': 'Psu',
    'fans': 'Fans',
  };

  final Map<String, ComponentCard> selectedComponents = {};
  final Map<String, bool> expandedSections = {};
  final Map<String, TextEditingController> searchControllers = {};
  final Map<String, TextEditingController> minPriceControllers = {};
  final Map<String, TextEditingController> maxPriceControllers = {};
  final Map<String, String> selectedBrands = {};
  final Map<String, bool> showFilters = {};

  final currencyFormatter = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    _chatApi = BuildsChatApi('http://localhost:8000');

    for (var typeKey in apiCategoryMap.keys) {
      expandedSections[typeKey] = false;
      searchControllers[typeKey] = TextEditingController();
      minPriceControllers[typeKey] = TextEditingController();
      maxPriceControllers[typeKey] = TextEditingController();
      selectedBrands[typeKey] = '';
      showFilters[typeKey] = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchControllers.values.forEach((controller) => controller.dispose());
    minPriceControllers.values.forEach((controller) => controller.dispose());
    maxPriceControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _refreshComponentList(String typeKey) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final String apiCategory = apiCategoryMap[typeKey]!;
      final search = searchControllers[typeKey]?.text.toLowerCase();
      final minPrice = double.tryParse(
        minPriceControllers[typeKey]?.text ?? '',
      );
      final maxPriceText = maxPriceControllers[typeKey]?.text ?? '';
      final maxPrice = maxPriceText.isEmpty
          ? null
          : double.tryParse(maxPriceText);
      final brand = selectedBrands[typeKey];

      setState(() {
        _componentFutures[typeKey] = _apiClient.fetchComponents(
          category: apiCategory,
          pageSize: 50,
          search: (search != null && search.isNotEmpty) ? search : null,
          minPrice: (minPrice != null && minPrice > 0) ? minPrice : null,
          maxPrice: maxPrice,
          brand: (brand != null && brand.isNotEmpty) ? brand : null,
        );
      });
    });
  }

  Future<void> _handleCreateBuild(bool isPublic) async {
    final buildDetails = await _showNameAndTypeDialog();
    if (buildDetails == null) return;

    setState(() => _isSaving = true);

    try {
      final List<BuildComponentCreate> componentsToCreate = selectedComponents
          .entries
          .map((entry) {
            final category = entry.key;
            final comp = entry.value;
            return BuildComponentCreate(
              componentId: comp.id,
              category: category,
              name: comp.name,
              imageUrl: comp.imageUrl,
              priceAtBuildTime: comp.price ?? 0.0,
            );
          })
          .toList();

      final buildData = BuildCreate(
        name: buildDetails['name']!,
        useType: buildDetails['useType']!,
        isPublic: isPublic,
        components: componentsToCreate,
        description: "",
        imageUrl: "",
      );

      await _apiClient.createBuild(buildData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Build "${buildData.name}" ${isPublic ? "publicada" : "guardada"} con éxito.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/my-builds');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la build: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<Map<String, String>?> _showNameAndTypeDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    String _selectedUseType = 'Gaming';

    final List<String> useTypes = [
      'Gaming',
      'Oficina',
      'Edición',
      'Programación',
      'Otro',
    ];

    return showDialog<Map<String, String>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1C),
              title: Text(
                'Detalles de la Build',
                style: TextStyle(color: Colors.white),
              ),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Build',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'El nombre es requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedUseType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Uso',
                      ),
                      dropdownColor: const Color(0xFF1C1C1C),
                      items: useTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => _selectedUseType = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                ElevatedButton(
                  child: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pop({
                        'name': _nameController.text,
                        'useType': _selectedUseType,
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _runCompatibilityCheck() async {
    if (_isCheckingCompatibility) return;

    final cpu = selectedComponents['cpu']?.name;
    final motherboard = selectedComponents['motherboard']?.name;

    if (cpu == null || motherboard == null) {
      return;
    }

    if (mounted) setState(() => _isCheckingCompatibility = true);

    try {
      final componentsToVerify = {
        'cpu': cpu,
        'motherboard': motherboard,
        'ram': selectedComponents['ram']?.name,
        'gpu': selectedComponents['gpu']?.name,
      };

      final response = await _apiClient.checkCompatibility(componentsToVerify);

      if (!mounted) return;

      if (!response.compatible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Advertencia: ${response.reason}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 8),
            showCloseIcon: true,
            closeIconColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    response.reason,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al contactar el servicio de validación: $e'),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingCompatibility = false);
      }
    }
  }

  void _showSummaryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMobileSummary(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    final isMobile = size.width <= 600;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 12 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header adaptativo
                      _buildHeader(theme, isMobile),
                      SizedBox(height: isMobile ? 16 : 32),

                      // Lista de componentes
                      Column(
                        children: apiCategoryMap.keys.map((typeKey) {
                          return _buildComponentSection(typeKey, isMobile);
                        }).toList(),
                      ),

                      // Espacio adicional en móvil para el FAB
                      if (isMobile) const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Sidebar solo en desktop
              if (isDesktop) SizedBox(width: 350, child: _buildSidebar()),
            ],
          ),

          // FAB flotante en móvil/tablet
          if (!isDesktop)
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildFloatingActionButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crear Nueva Build',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 24 : 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona los componentes para tu nueva configuración.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.grey[400],
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    final hasSelection = selectedComponents.isNotEmpty;
    final count = selectedComponents.length;

    return FloatingActionButton.extended(
      onPressed: hasSelection ? _showSummaryBottomSheet : null,
      backgroundColor: hasSelection
          ? Theme.of(context).primaryColor
          : Colors.grey[800],
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart),
          if (count > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      label: const Text('Ver Resumen'),
    );
  }

  Widget _buildMobileSummary() {
    final theme = Theme.of(context);
    final hasSelection = selectedComponents.isNotEmpty;
    final double totalPrice = selectedComponents.values.fold(
      0.0,
      (sum, comp) => sum + (comp.price ?? 0.0),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1C),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Resumen de la Build',
                      style: theme.textTheme.titleLarge?.copyWith(
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

              // Lista de componentes
              Expanded(
                child: !hasSelection
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No hay componentes seleccionados",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: selectedComponents.entries.map((entry) {
                          final typeKey = entry.key;
                          final comp = entry.value;
                          final displayName =
                              displayNames[typeKey] ?? typeKey.toUpperCase();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2A2A2A),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Imagen
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
                                          icons[typeKey] ?? Icons.help_outline,
                                          color: Colors.grey[600],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
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
                                      const SizedBox(height: 4),
                                      Text(
                                        comp.price != null
                                            ? currencyFormatter.format(
                                                comp.price,
                                              )
                                            : "N/A",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Botón eliminar
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red[400],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      selectedComponents.remove(typeKey);
                                    });
                                    if (selectedComponents.isEmpty) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              // Footer con acciones
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF101010),
                  border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Precio Total:',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${currencyFormatter.format(totalPrice)} MXN',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Botón Chat
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BuildsChatSheet(api: _chatApi),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Chatea con Yarbis'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botón Guardar
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: hasSelection && !_isSaving
                              ? () {
                                  Navigator.pop(context);
                                  _handleCreateBuild(false);
                                }
                              : null,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save, size: 18),
                          label: Text(
                            _isSaving ? 'Guardando...' : 'Guardar Build',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botón Publicar
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: hasSelection && !_isSaving
                              ? () {
                                  Navigator.pop(context);
                                  _handleCreateBuild(true);
                                }
                              : null,
                          icon: const Icon(Icons.public, size: 18),
                          label: const Text('Publicar Build'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[300],
                            side: BorderSide(
                              color: hasSelection
                                  ? theme.primaryColor.withOpacity(0.5)
                                  : Colors.grey[800]!,
                            ),
                            disabledForegroundColor: Colors.grey[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComponentSection(String typeKey, bool isMobile) {
    final isExpanded = expandedSections[typeKey] ?? false;
    final displayName = displayNames[typeKey] ?? typeKey.toUpperCase();
    final selectedComp = selectedComponents[typeKey];

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () {
                  setState(() {
                    bool newExpandedState = !isExpanded;
                    expandedSections[typeKey] = newExpandedState;
                    if (newExpandedState) {
                      _refreshComponentList(typeKey);
                    }
                  });
                },
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Row(
                    children: [
                      Icon(
                        icons[typeKey] ?? Icons.help_outline,
                        color: const Color(0xFFC7384D),
                        size: isMobile ? 20 : 24,
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                            if (selectedComp != null && !isExpanded)
                              Text(
                                selectedComp.name,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: isMobile ? 11 : 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_more,
                          color: const Color(0xFFA0A0A0),
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenido expandible
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  height: isExpanded ? null : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilters(typeKey, isMobile),
                        SizedBox(height: isMobile ? 12 : 20),
                        FutureBuilder<PaginatedComponentsResponse>(
                          future: _componentFutures[typeKey],
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Error: ${snapshot.error}',
                                    style: TextStyle(color: Colors.red[300]),
                                  ),
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Presiona "Expandir" para buscar...',
                                  ),
                                ),
                              );
                            }

                            final components = snapshot.data!.components;

                            if (components.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                ),
                                child: Center(
                                  child: Text(
                                    "No hay componentes que coincidan.",
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: components.length,
                              itemBuilder: (context, index) {
                                return _buildComponentCard(
                                  typeKey,
                                  components[index],
                                  isMobile,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(String typeKey, bool isMobile) {
    final theme = Theme.of(context);
    final showFiltersForType = showFilters[typeKey] ?? false;

    final List<String> brandItems = [
      '',
      'Intel',
      'AMD',
      'NVIDIA',
      'Gigabyte',
      'MSI',
      'ASUS',
      'Corsair',
      'Samsung',
      'Kingston',
      'Western Digital',
      'Seagate',
      'EVGA',
      'Noctua',
      'Be Quiet!',
      'NZXT',
      'Thermaltake',
      'Cooler Master',
      'Lian Li',
      'HP',
      'Dell',
      'Lenovo',
      'Acer',
      'Razer',
    ];

    final List<String> brandLabels = [
      'Todas las Marcas',
      'Intel',
      'AMD',
      'NVIDIA',
      'Gigabyte',
      'MSI',
      'ASUS',
      'Corsair',
      'Samsung',
      'Kingston',
      'Western Digital',
      'Seagate',
      'EVGA',
      'Noctua',
      'Be Quiet!',
      'NZXT',
      'Thermaltake',
      'Cooler Master',
      'Lian Li',
      'HP',
      'Dell',
      'Lenovo',
      'Acer',
      'Razer',
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda siempre visible
          _buildFilterTextField(
            controller: searchControllers[typeKey],
            hintText: 'Buscar componente...',
            onChanged: (_) => _refreshComponentList(typeKey),
            icon: Icons.search,
          ),
          const SizedBox(height: 8),

          // Botón para mostrar más filtros
          TextButton.icon(
            onPressed: () {
              setState(() {
                showFilters[typeKey] = !showFiltersForType;
              });
            },
            icon: Icon(
              showFiltersForType ? Icons.filter_list_off : Icons.filter_list,
              size: 18,
            ),
            label: Text(
              showFiltersForType ? 'Ocultar filtros' : 'Más filtros',
              style: const TextStyle(fontSize: 13),
            ),
            style: TextButton.styleFrom(
              foregroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),

          // Filtros adicionales (colapsables)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              height: showFiltersForType ? null : 0,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterTextField(
                          controller: minPriceControllers[typeKey],
                          hintText: 'Min',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _refreshComponentList(typeKey),
                          icon: Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterTextField(
                          controller: maxPriceControllers[typeKey],
                          hintText: 'Max',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _refreshComponentList(typeKey),
                          icon: Icons.money_off,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterDropdown(
                    theme: theme,
                    label: 'Marca',
                    value: selectedBrands[typeKey]!,
                    items: brandItems,
                    itemLabels: brandLabels,
                    onChanged: (value) {
                      setState(() {
                        selectedBrands[typeKey] = value ?? '';
                      });
                      _refreshComponentList(typeKey);
                    },
                    minWidth: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Diseño para tablet/desktop (horizontal)
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 200,
          child: _buildFilterTextField(
            controller: searchControllers[typeKey],
            hintText: 'Buscar...',
            onChanged: (_) => _refreshComponentList(typeKey),
            icon: Icons.search,
          ),
        ),
        SizedBox(
          width: 100,
          child: _buildFilterTextField(
            controller: minPriceControllers[typeKey],
            hintText: 'Min',
            keyboardType: TextInputType.number,
            onChanged: (_) => _refreshComponentList(typeKey),
            icon: Icons.attach_money,
          ),
        ),
        SizedBox(
          width: 100,
          child: _buildFilterTextField(
            controller: maxPriceControllers[typeKey],
            hintText: 'Max',
            keyboardType: TextInputType.number,
            onChanged: (_) => _refreshComponentList(typeKey),
            icon: Icons.money_off,
          ),
        ),
        _buildFilterDropdown(
          theme: theme,
          label: 'Marca',
          value: selectedBrands[typeKey]!,
          items: brandItems,
          itemLabels: brandLabels,
          onChanged: (value) {
            setState(() {
              selectedBrands[typeKey] = value ?? '';
            });
            _refreshComponentList(typeKey);
          },
          minWidth: 150,
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required ThemeData theme,
    required String label,
    required String value,
    required List<String> items,
    required List<String> itemLabels,
    required ValueChanged<String?> onChanged,
    double minWidth = 150,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  theme.inputDecorationTheme.fillColor ?? Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF1C1C1C),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.secondary,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
                items: List.generate(items.length, (index) {
                  return DropdownMenuItem(
                    value: items[index],
                    child: Text(
                      itemLabels[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTextField({
    required TextEditingController? controller,
    String hintText = '',
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    IconData? icon,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.grey[300], fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.grey[500], size: 18)
              : null,
          filled: true,
          fillColor:
              Theme.of(context).inputDecorationTheme.fillColor ??
              Colors.black.withOpacity(0.4),
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFC7384D)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildComponentCard(
    String typeKey,
    ComponentCard comp,
    bool isMobile,
  ) {
    final bool isSelected = selectedComponents[typeKey] == comp;
    final theme = Theme.of(context);
    const keyComponents = ['cpu', 'motherboard', 'ram', 'gpu'];

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withOpacity(0.15)
            : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(
          color: isSelected ? theme.primaryColor : const Color(0xFF3A3A3A),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          onTap: () async {
            setState(() {
              if (isSelected) {
                selectedComponents.remove(typeKey);
              } else {
                selectedComponents[typeKey] = comp;
              }
            });

            if (keyComponents.contains(typeKey)) {
              await _runCompatibilityCheck();
            }
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: isMobile
                ? _buildMobileCardContent(comp, isSelected, typeKey, theme)
                : _buildDesktopCardContent(comp, isSelected, typeKey, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardContent(
    ComponentCard comp,
    bool isSelected,
    String typeKey,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                comp.imageUrl ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comp.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Marca: ${comp.brand ?? "N/A"}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comp.price != null
                        ? currencyFormatter.format(comp.price)
                        : "N/A",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Icono de selección
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? theme.primaryColor : Colors.grey[600],
              size: 28,
            ),
          ],
        ),

        // Links en la parte inferior
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/component-detail',
                    arguments: comp.id,
                  );
                },
                icon: const Icon(Icons.info_outline, size: 14),
                label: const Text('Detalles', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (comp.link != null && comp.store != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(comp.link!);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: Text(
                    comp.store!,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[400],
                    side: BorderSide(color: Colors.grey[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopCardContent(
    ComponentCard comp,
    bool isSelected,
    String typeKey,
    ThemeData theme,
  ) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            comp.imageUrl ?? '',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comp.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Marca: ${comp.brand ?? "N/A"}',
                style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 13),
              ),
              Text(
                'Precio: ${comp.price != null ? currencyFormatter.format(comp.price) : "N/A"} MXN',
                style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildLink(
                    context,
                    text: 'Ver componente',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/component-detail',
                        arguments: comp.id,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  if (comp.link != null && comp.store != null)
                    _buildLink(
                      context,
                      text: 'Ver en ${comp.store!}',
                      onTap: () async {
                        final uri = Uri.tryParse(comp.link!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          isSelected ? Icons.check_circle : Icons.add_circle_outline,
          color: isSelected ? theme.primaryColor : Colors.grey[600],
          size: 24,
        ),
      ],
    );
  }

  Widget _buildLink(
    BuildContext context, {
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final theme = Theme.of(context);
    final bool hasSelection = selectedComponents.isNotEmpty;
    final double totalPrice = selectedComponents.values.fold(
      0.0,
      (sum, comp) => sum + (comp.price ?? 0.0),
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C).withOpacity(0.8),
        border: const Border(left: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              'Resumen de la Build',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          Expanded(
            child: !hasSelection
                ? Center(
                    child: Text(
                      "Selecciona componentes...",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: selectedComponents.entries.map((entry) {
                      final typeKey = entry.key;
                      final comp = entry.value;
                      final displayName =
                          displayNames[typeKey] ?? typeKey.toUpperCase();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icons[typeKey] ?? Icons.help_outline,
                              color: theme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  Text(
                                    comp.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              comp.price != null
                                  ? currencyFormatter.format(comp.price)
                                  : "N/A",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: "Quitar $displayName",
                              onPressed: () {
                                setState(() {
                                  selectedComponents.remove(typeKey);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF101010),
              border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Precio Total:',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    Text(
                      '${currencyFormatter.format(totalPrice)} MXN',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BuildsChatSheet(api: _chatApi),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chatea con Yarbis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: hasSelection && !_isSaving
                      ? () => _handleCreateBuild(false)
                      : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar Build'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[800],
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: hasSelection && !_isSaving
                      ? () => _handleCreateBuild(true)
                      : null,
                  icon: _isSaving
                      ? Container(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey[300],
                          ),
                        )
                      : const Icon(Icons.public, size: 18),
                  label: Text(_isSaving ? 'Publicando...' : 'Publicar Build'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[300],
                    side: BorderSide(
                      color: hasSelection
                          ? theme.primaryColor.withOpacity(0.5)
                          : Colors.grey[800]!,
                    ),
                    disabledForegroundColor: Colors.grey[700],
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
