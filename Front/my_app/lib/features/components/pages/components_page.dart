// lib/features/components/pages/components_page.dart

import 'package:flutter/material.dart';
import 'dart:ui';
// ¡Importamos los nuevos modelos y el ApiClient!
import 'package:my_app/models/component.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ComponentsPage extends StatefulWidget {
  const ComponentsPage({super.key});

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage>
    with SingleTickerProviderStateMixin {
  // --- ¡DATOS MOCK ELIMINADOS! ---
  // final List<Component> allComponents = [ ... ];

  // --- NUEVO ESTADO PARA DATOS REALES ---
  late Future<PaginatedComponentsResponse> _componentsFuture;
  late ApiClient _apiClient;

  // Estados de los filtros (se mantienen)
  String searchQuery = ''; // (Aún no lo conectamos, pero se puede)
  String selectedUso = ''; // (Tu API no filtra por 'uso', lo ignoraremos)
  String selectedCategoria = '';
  String selectedMarca = '';
  double budgetMax = 25000;

  // Animación (se mantiene)
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Obtiene el ApiClient del Provider
    _apiClient = Provider.of<ApiClient>(context, listen: false);

    // Inicia la primera carga de datos
    _fetchData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.12, end: 0.18).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  // --- NUEVA FUNCIÓN PARA OBTENER DATOS ---
  void _fetchData() {
    setState(() {
      _componentsFuture = _apiClient.fetchComponents(
        page: 1,
        pageSize: 50, // Pedimos 50 por ahora
        category: selectedCategoria.isNotEmpty ? selectedCategoria : null,
        brand: selectedMarca.isNotEmpty ? selectedMarca : null,
        maxPrice: budgetMax < 25000 ? budgetMax : null, // Solo si se ha movido
        // search: searchQuery.isNotEmpty ? searchQuery : null, // (Se puede añadir)
        sortBy: "price_asc",
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE FILTRADO (YA NO SE USA) ---
  // List<Component> get filteredComponents { ... }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Gradiente animado (se mantiene)
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            /* ... sin cambios ... */
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.6),
                  radius: 1.5,
                  colors: [
                    theme.primaryColor.withOpacity(_animation.value),
                    theme.primaryColor.withOpacity(_animation.value * 0.5),
                    theme.primaryColor.withOpacity(_animation.value * 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            );
          },
        ),
        // Contenido principal
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 24,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título (se mantiene)
              Padding(
                padding: EdgeInsets.only(bottom: 24.0, left: isDesktop ? 0 : 0),
                child: Text(
                  'Componentes',
                  style:
                      theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              // Sección de filtros (¡CONECTADA!)
              _buildFiltersSection(theme),
              const SizedBox(height: 32),

              // --- ¡NUEVO: FUTURE BUILDER! ---
              FutureBuilder<PaginatedComponentsResponse>(
                future: _componentsFuture,
                builder: (context, snapshot) {
                  // 1. Estado de Carga
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(64.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  // 2. Estado de Error
                  if (snapshot.hasError) {
                    return _buildErrorState(theme, snapshot.error.toString());
                  }

                  // 3. Estado Vacío
                  if (!snapshot.hasData || snapshot.data!.components.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  // 4. Estado con Datos
                  final components = snapshot.data!.components;
                  return _buildComponentsGrid(components, isDesktop, (
                    component,
                  ) {
                    // La navegación ya estaba correcta (pasa el ID)
                    Navigator.pushNamed(
                      context,
                      '/component-detail',
                      arguments: component.id,
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget para la sección de filtros (MODIFICADO)
  Widget _buildFiltersSection(ThemeData theme) {
    return _GlassmorphismCard(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.start,
        children: [
          // (Filtro 'Uso' eliminado porque la API no lo soporta)

          // Filtro de Categoría (CONECTADO)
          _buildFilterDropdown(
            theme: theme,
            label: 'Categoría',
            value: selectedCategoria,
            items: [
              '', 'CPU', 'GPU', 'Motherboard', 'PSU', 'RAM',
              'storage', // (la API usa 'storage', no 'Almacenamiento')
              'case', 'cooling', 'fan',
            ],
            itemLabels: [
              'Todas',
              'CPU',
              'GPU',
              'Motherboard',
              'PSU',
              'RAM',
              'Almacenamiento',
              'Gabinete',
              'Enfriamiento',
              'Ventiladores',
            ],
            onChanged: (value) {
              setState(() => selectedCategoria = value ?? '');
              _fetchData(); // ¡Vuelve a cargar los datos!
            },
            minWidth: 180,
          ),

          // Filtro de Marca (CONECTADO)
          _buildFilterDropdown(
            theme: theme,
            label: 'Marca',
            value: selectedMarca,
            // (Simplificado a las marcas de tu scraper)
            items: [
              '',
              'Intel',
              'AMD',
              'NVIDIA',
              'Gigabyte',
              'MSI',
              'ASUS',
              'Corsair',
              'Samsung',
            ],
            itemLabels: [
              'Todas',
              'Intel',
              'AMD',
              'NVIDIA',
              'Gigabyte',
              'MSI',
              'ASUS',
              'Corsair',
              'Samsung',
            ],
            onChanged: (value) {
              setState(() => selectedMarca = value ?? '');
              _fetchData(); // ¡Vuelve a cargar los datos!
            },
            minWidth: 150,
          ),

          // Filtro de Presupuesto (CONECTADO)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presupuesto (MXN) ≤ \$${budgetMax.toInt()}',
                  style:
                      theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ) ??
                      TextStyle(
                        color: theme.colorScheme.secondary,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: theme.primaryColor,
                    inactiveTrackColor: theme.dividerColor.withOpacity(0.5),
                    thumbColor: theme.primaryColor,
                    overlayColor: theme.primaryColor.withOpacity(0.2),
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16.0,
                    ),
                  ),
                  child: Slider(
                    value: budgetMax,
                    min: 100,
                    max: 25000,
                    divisions: 249,
                    label: '\$${budgetMax.toInt()}',
                    onChanged: (value) => setState(() => budgetMax = value),
                    // ¡Vuelve a cargar los datos AL SOLTAR el slider!
                    onChangeEnd: (value) => _fetchData(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // (Helper _buildFilterDropdown se mantiene igual)
  Widget _buildFilterDropdown({
    required ThemeData theme,
    required String label,
    required String value,
    required List<String> items,
    required List<String> itemLabels,
    required ValueChanged<String?> onChanged,
    double minWidth = 150,
  }) {
    // ... (sin cambios)
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
              border: Border.all(color: Colors.transparent),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: theme.cardColor.withOpacity(0.95),
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

  // Widget para la cuadrícula (MODIFICADO)
  // Ahora recibe List<ComponentCard>
  Widget _buildComponentsGrid(
    List<ComponentCard> components, // <-- ¡Modelo actualizado!
    bool isDesktop,
    Function(ComponentCard) onTapped, // <-- ¡Modelo actualizado!
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop
            ? 3
            : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: isDesktop
            ? 1.1
            : (MediaQuery.of(context).size.width > 600 ? 1.2 : 1.8),
      ),
      itemCount: components.length,
      itemBuilder: (context, index) {
        final component = components[index];
        return InkWell(
          onTap: () => onTapped(component), // Llama al handler
          borderRadius: BorderRadius.circular(12.0),
          child: ComponentCardWidget(
            component: component,
          ), // Usa el nuevo widget
        );
      },
    );
  }

  // (Widget _buildEmptyState se mantiene igual)
  Widget _buildEmptyState(ThemeData theme) {
    // ... (sin cambios)
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron componentes',
              style:
                  theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ) ??
                  TextStyle(color: theme.colorScheme.secondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros o la búsqueda.',
              style:
                  theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary.withOpacity(0.7),
                  ) ??
                  TextStyle(
                    color: theme.colorScheme.secondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- ¡NUEVO WIDGET DE ERROR! ---
  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: theme.primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar componentes',
              style:
                  theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ) ??
                  TextStyle(color: theme.colorScheme.secondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error, // Muestra el error real de la API
              style:
                  theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary.withOpacity(0.7),
                  ) ??
                  TextStyle(
                    color: theme.colorScheme.secondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// --- TARJETA DE COMPONENTE (MODIFICADA) ---
// (Renombrada a ComponentCardWidget para evitar conflicto con el modelo)
// Ahora usa el modelo ComponentCard
class ComponentCardWidget extends StatelessWidget {
  final ComponentCard component; // <-- ¡Modelo actualizado!

  const ComponentCardWidget({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Info Superior
          if (component.imageUrl != null)
            Image.network(
              component.imageUrl!,
              height: 120, // Altura fija para la imagen
              width: double.infinity,
              fit: BoxFit.cover,
              // Placeholder mientras carga
              loadingBuilder: (context, child, progress) {
                return progress == null
                    ? child
                    : Container(
                        height: 120,
                        color: Colors.grey[850],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
              },
              // Error si no puede cargar
              errorBuilder: (context, error, stackTrace) => Container(
                height: 120,
                color: Colors.grey[850],
                child: Icon(Icons.broken_image, color: Colors.grey[700]),
              ),
            )
          else
            Container(
              // Placeholder si no hay imagen
              height: 120,
              width: double.infinity,
              color: Colors.grey[850],
              child: Icon(Icons.no_photography, color: Colors.grey[700]),
            ),

          const SizedBox(height: 16), // Espacio entre imagen y texto
          // --- FIN DE CORRECCIÓN! --
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                component.category, // <-- Dato real
                style:
                    theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ) ??
                    TextStyle(color: theme.colorScheme.secondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                component.name, // <-- Dato real
                style:
                    theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ) ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                component.brand ?? 'Sin marca', // <-- Dato real
                style:
                    theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ) ??
                    TextStyle(color: theme.colorScheme.secondary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info Inferior
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // Maneja precio nulo
                component.price != null
                    ? '\$${component.price!.toStringAsFixed(0)} MXN'
                    : 'No disponible',
                style:
                    theme.textTheme.headlineSmall?.copyWith(
                      color: component.price != null
                          ? theme.primaryColor
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ) ??
                    TextStyle(
                      color: component.price != null
                          ? theme.primaryColor
                          : Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                // Maneja tienda nula
                'Disponible en: ${component.store ?? 'N/A'}',
                style:
                    theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary.withOpacity(0.8),
                    ) ??
                    TextStyle(
                      color: theme.colorScheme.secondary.withOpacity(0.8),
                      fontSize: 12,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// (Widget _GlassmorphismCard se mantiene igual)
class _GlassmorphismCard extends StatelessWidget {
  final Widget child;
  const _GlassmorphismCard({required this.child});

  @override
  Widget build(BuildContext context) {
    // ... (sin cambios)
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color:
                (theme.cardColor == Colors.transparent
                        ? theme.colorScheme.surface
                        : theme.cardColor)
                    .withOpacity(0.7),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: child,
        ),
      ),
    );
  }
}
