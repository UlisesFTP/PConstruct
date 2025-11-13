import 'package:flutter/material.dart';
import 'dart:ui'; // Para BackdropFilter
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/component.dart';
import 'package:my_app/models/build.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Para el Debouncer
import 'package:my_app/core/widgets/builds_chat.dart';
import 'package:my_app/core/api/builds_chat_api.dart';

class BuildConstructorPage extends StatefulWidget {
  BuildConstructorPage({super.key});

  @override
  State<BuildConstructorPage> createState() => _BuildConstructorPageState();
}

class _BuildConstructorPageState extends State<BuildConstructorPage> {
  // --- API y Estado de Carga ---
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

  // --- ¡INICIO DE LA CORRECCIÓN! ---

  // 1. Mapa de "claves" a "categorías de API" (como en components_page.dart)
  final Map<String, String> apiCategoryMap = {
    'cpu': 'CPU',
    'motherboard': 'Motherboard',
    'ram': 'RAM',
    'gpu': 'GPU',
    'storage_primary': 'SSD', // Asumimos que primario es SSD
    'storage_secondary': 'HDD', // Asumimos que secundario es HDD
    'cooler': 'Cooling',
    'gabinete': 'Gabinete',
    'psu': 'PSU',
    'fans': 'Ventiladores',
    // 'os': 'OS', // Tu API de componentes probablemente no tenga "OS"
  };

  // 2. Mapa de "claves" a "nombres para mostrar"
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
    // 'os': 'Os',
  };

  // 3. ❌ Eliminamos la lista antigua
  // final List<String> componentOrder = [ ... ];

  // --- FIN DE LA CORRECCIÓN ---

  final Map<String, ComponentCard> selectedComponents = {};
  final Map<String, bool> expandedSections = {};
  final Map<String, TextEditingController> searchControllers = {};
  final Map<String, TextEditingController> minPriceControllers = {};
  final Map<String, TextEditingController> maxPriceControllers = {};
  final Map<String, String> selectedBrands = {};

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

    // 4. Usamos las claves del nuevo mapa
    for (var typeKey in apiCategoryMap.keys) {
      expandedSections[typeKey] = false;
      searchControllers[typeKey] = TextEditingController();
      minPriceControllers[typeKey] = TextEditingController();
      maxPriceControllers[typeKey] = TextEditingController();
      selectedBrands[typeKey] = '';
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

  // --- ¡LÓGICA DE CARGA DE DATOS ACTUALIZADA! ---
  void _refreshComponentList(String typeKey) {
    // 'type' ahora es 'typeKey'
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // 5. Obtenemos la categoría de API real
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
          // 6. Enviamos la categoría correcta (ej: "CPU")
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

  // ... (El resto de funciones _handleCreateBuild, _showNameAndTypeDialog, _runCompatibilityCheck no cambian) ...
  // --- Lógica de Guardado (Sin cambios) ---
  Future<void> _handleCreateBuild(bool isPublic) async {
    // ... (Tu código _handleCreateBuild se mantiene igual) ...
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

  // --- Diálogo de Nombre y Tipo (Sin cambios) ---
  Future<Map<String, String>?> _showNameAndTypeDialog() async {
    // ... (Tu código de _showNameAndTypeDialog se mantiene igual) ...
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    String _selectedUseType = 'Gaming'; // Valor por defecto

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

  // --- Función de Validación de Gemini (Sin cambios) ---
  Future<void> _runCompatibilityCheck() async {
    // ... (Tu código de _runCompatibilityCheck se mantiene igual) ...
    if (_isCheckingCompatibility) return;

    final cpu = selectedComponents['cpu']?.name;
    final motherboard = selectedComponents['motherboard']?.name;

    if (cpu == null || motherboard == null) {
      print("Saltando verificación: Faltan CPU o Motherboard.");
      return;
    }

    print("Ejecutando verificación de compatibilidad...");
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear Nueva Build',
                  style:
                      theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ) ??
                      const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona los componentes para tu nueva configuración.',
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[400],
                      ) ??
                      TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(height: 32),
                Column(
                  // 7. ¡Iteramos sobre las claves del nuevo mapa!
                  children: apiCategoryMap.keys.map((typeKey) {
                    return _buildComponentSection(typeKey);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        if (isDesktop) SizedBox(width: 350, child: _buildSidebar()),
      ],
    );
  }

  // --- ¡SECCIÓN DE COMPONENTES ACTUALIZADA! ---
  Widget _buildComponentSection(String typeKey) {
    // 'type' ahora es 'typeKey'
    final isExpanded = expandedSections[typeKey] ?? false;

    // 8. Usamos el mapa de nombres para mostrar
    final displayName = displayNames[typeKey] ?? typeKey.toUpperCase();

    final selectedComp = selectedComponents[typeKey];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                      // 9. Pasamos el typeKey a la función
                      _refreshComponentList(typeKey);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            icons[typeKey] ?? Icons.help_outline,
                            color: const Color(0xFFC7384D),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            displayName, // <-- Usamos el nombre de mostrar
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ) ??
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                          ),
                        ],
                      ),
                      if (selectedComp != null && !isExpanded)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              selectedComp.name,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                      else
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Icons.expand_more,
                            color: Color(0xFFA0A0A0),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Contenido Colapsable
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilters(typeKey), // <-- Pasamos typeKey
                        const SizedBox(height: 20),
                        FutureBuilder<PaginatedComponentsResponse>(
                          future:
                              _componentFutures[typeKey], // <-- Usamos typeKey
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
                                  typeKey, // <-- Pasamos typeKey
                                  components[index],
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

  // --- ¡FILTROS ACTUALIZADOS! ---
  Widget _buildFilters(String typeKey) {
    // 'type' ahora es 'typeKey'
    final theme = Theme.of(context);

    // ... (listas de marcas se mantienen igual) ...
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

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        // Search Field
        SizedBox(
          width: 200,
          child: _buildFilterTextField(
            controller: searchControllers[typeKey], // <-- Usamos typeKey
            hintText: 'Buscar...',
            onChanged: (_) =>
                _refreshComponentList(typeKey), // <-- Usamos typeKey
            icon: Icons.search,
          ),
        ),
        // Min Price
        SizedBox(
          width: 100,
          child: _buildFilterTextField(
            controller: minPriceControllers[typeKey], // <-- Usamos typeKey
            hintText: 'Min \$',
            keyboardType: TextInputType.number,
            onChanged: (_) =>
                _refreshComponentList(typeKey), // <-- Usamos typeKey
            icon: Icons.attach_money,
          ),
        ),
        // Max Price
        SizedBox(
          width: 100,
          child: _buildFilterTextField(
            controller: maxPriceControllers[typeKey], // <-- Usamos typeKey
            hintText: 'Max \$',
            keyboardType: TextInputType.number,
            onChanged: (_) =>
                _refreshComponentList(typeKey), // <-- Usamos typeKey
            icon: Icons.money_off,
          ),
        ),

        _buildFilterDropdown(
          theme: theme,
          label: 'Marca',
          value: selectedBrands[typeKey]!, // <-- Usamos typeKey
          items: brandItems,
          itemLabels: brandLabels,
          onChanged: (value) {
            setState(() {
              selectedBrands[typeKey] = value ?? ''; // <-- Usamos typeKey
            });
            _refreshComponentList(typeKey); // <-- Usamos typeKey
          },
          minWidth: 150,
        ),
      ],
    );
  }

  // --- ¡HELPER AÑADIDO! ---
  Widget _buildFilterDropdown({
    required ThemeData theme,
    required String label,
    required String value,
    required List<String> items,
    required List<String> itemLabels,
    required ValueChanged<String?> onChanged,
    double minWidth = 150,
  }) {
    // ... (Tu código _buildFilterDropdown se mantiene igual) ...
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style:
                theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ) ??
                TextStyle(color: theme.colorScheme.secondary, fontSize: 12),
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

  // Filter TextField (sin cambios)
  Widget _buildFilterTextField({
    required TextEditingController? controller,
    String hintText = '',
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    IconData? icon,
  }) {
    // ... (Tu widget _buildFilterTextField se mantiene igual) ...
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

  // --- Tarjeta de Componente (ACTUALIZADA) ---
  Widget _buildComponentCard(String typeKey, ComponentCard comp) {
    // 'type' ahora es 'typeKey'
    final bool isSelected =
        selectedComponents[typeKey] == comp; // <-- Usamos typeKey
    final theme = Theme.of(context);
    const keyComponents = ['cpu', 'motherboard', 'ram', 'gpu'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withOpacity(0.15)
            : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.primaryColor : const Color(0xFF3A3A3A),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            setState(() {
              if (isSelected) {
                selectedComponents.remove(typeKey); // <-- Usamos typeKey
              } else {
                selectedComponents[typeKey] = comp; // <-- Usamos typeKey
              }
            });

            if (keyComponents.contains(typeKey)) {
              // <-- Usamos typeKey
              await _runCompatibilityCheck();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
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
                        style: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Precio: ${comp.price != null ? currencyFormatter.format(comp.price) : "N/A"} MXN',
                        style: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 13,
                        ),
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
            ),
          ),
        ),
      ),
    );
  }

  // Helper para los links (sin cambios)
  Widget _buildLink(
    BuildContext context, {
    required String text,
    required VoidCallback onTap,
  }) {
    // ... (Tu código _buildLink se mantiene igual) ...
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

  // Sidebar (ACTUALIZADO)
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
              style:
                  theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ) ??
                  const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                      final typeKey = entry.key; // <-- Usamos typeKey
                      final comp = entry.value;

                      // 10. Usamos el mapa de nombres para mostrar
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
                              icons[typeKey] ??
                                  Icons.help_outline, // <-- Usamos typeKey
                              color: theme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName, // <-- Usamos el nombre de mostrar
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
                              tooltip: "Quitar ${displayName}",
                              onPressed: () {
                                setState(() {
                                  selectedComponents.remove(
                                    typeKey,
                                  ); // <-- Usamos typeKey
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
                // === Botón: Chatea con Yarbis ===
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
                      backgroundColor:
                          theme.primaryColor, // mismo estilo que Guardar
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: hasSelection && !_isSaving
                      ? () => _handleCreateBuild(false)
                      : null,
                  icon: _isSaving
                      ? Container(
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
