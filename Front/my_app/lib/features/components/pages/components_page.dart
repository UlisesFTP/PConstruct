// lib/features/components/pages/components_page.dart

import 'package:flutter/material.dart';
import 'dart:ui';
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
  late Future<PaginatedComponentsResponse> _componentsFuture;
  late ApiClient _apiClient;

  // --- ¡NUEVO ESTADO PARA PAGINACIÓN! ---
  int _currentPage = 1;
  int _totalItems = 0;
  final int _pageSize = 50; // Mostraremos 50 por página
  // ------------------------------------

  // Estados de los filtros
  String selectedCategoria = '';
  String selectedMarca = '';
  RangeValues budgetRange = const RangeValues(0, 200000);

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    _fetchData(page: 1); // Carga la primera página

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.12, end: 0.18).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  // --- FUNCIÓN DE CARGA DE DATOS (MODIFICADA) ---
  void _fetchData({required int page}) {
    setState(() {
      _currentPage = page; // Actualiza la página actual
      _componentsFuture = _apiClient.fetchComponents(
        page: _currentPage,
        pageSize: _pageSize,
        category: selectedCategoria.isNotEmpty ? selectedCategoria : null,
        brand: selectedMarca.isNotEmpty ? selectedMarca : null,
        minPrice: (budgetRange.start > 0) ? budgetRange.start : null,
        maxPrice: (budgetRange.end < 200000) ? budgetRange.end : null,
        sortBy: "price_asc",
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Gradiente animado
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
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
              // Título
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

              // Sección de filtros
              _buildFiltersSection(theme),
              const SizedBox(height: 32),

              // --- FUTURE BUILDER (MODIFICADO) ---
              FutureBuilder<PaginatedComponentsResponse>(
                future: _componentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(64.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(theme, snapshot.error.toString());
                  }

                  if (!snapshot.hasData || snapshot.data!.components.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  // ¡Datos reales!
                  final response = snapshot.data!;
                  final components = response.components;
                  // Actualiza el total de items
                  _totalItems = response.totalItems;
                  final totalPages = (_totalItems / _pageSize).ceil();

                  return Column(
                    children: [
                      // Cuadrícula de componentes
                      _buildComponentsGrid(components, isDesktop, (component) {
                        Navigator.pushNamed(
                          context,
                          '/component-detail',
                          arguments: component.id,
                        );
                      }),
                      const SizedBox(height: 32),
                      // --- ¡NUEVO WIDGET DE PAGINACIÓN! ---
                      _buildPaginationControls(totalPages),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ¡NUEVO WIDGET DE CONTROLES DE PAGINACIÓN! ---
  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 1)
      return const SizedBox.shrink(); // No mostrar si solo hay 1 página

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón Anterior
        ElevatedButton(
          onPressed: _currentPage <= 1
              ? null
              : () {
                  _fetchData(page: _currentPage - 1);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            disabledBackgroundColor: Colors.grey[800],
          ),
          child: const Text(
            'Anterior',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),

        // Indicador de página
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Página $_currentPage / $totalPages',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Botón Siguiente
        ElevatedButton(
          onPressed: _currentPage >= totalPages
              ? null
              : () {
                  _fetchData(page: _currentPage + 1);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            disabledBackgroundColor: Colors.grey[800],
          ),
          child: const Text(
            'Siguiente',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    return _GlassmorphismCard(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.start,
        children: [
          // Filtro de Categoría
          _buildFilterDropdown(
            theme: theme,
            label: 'Categoría',
            value: selectedCategoria,
            // --- ¡INICIO DE CORRECCIÓN! ---
            // Nombres que coinciden con la DB del scraper
            items: [
              '',
              'CPU',
              'GPU',
              'Motherboard',
              'PSU',
              'RAM',
              'SSD',
              'HDD',
              'Gabinete',
              'Cooling',
              'Ventiladores',
              'Laptop',
              'Laptop_Gamer',
            ],
            // Etiquetas amigables para el usuario
            itemLabels: [
              'Todas',
              'CPU',
              'GPU',
              'Motherboard',
              'PSU',
              'RAM',
              'Almacenamiento (SSD)',
              'Almacenamiento (HDD)',
              'Gabinete',
              'Enfriamiento',
              'Ventiladores',
              'Laptop',
              'Laptop Gamer',
            ],
            // --- FIN DE CORRECCIÓN! ---
            onChanged: (value) {
              setState(() => selectedCategoria = value ?? '');
              _fetchData(page: 1); // Reinicia a la página 1 al filtrar
            },
            minWidth: 180,
          ),

          // Filtro de Marca
          _buildFilterDropdown(
            theme: theme,
            label: 'Marca',
            value: selectedMarca,
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
            ],
            onChanged: (value) {
              setState(() => selectedMarca = value ?? '');
              _fetchData(page: 1); // Reinicia a la página 1 al filtrar
            },
            minWidth: 150,
          ),

          // Filtro de Presupuesto
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ¡INICIO DE CORRECCIÓN! ---
                Text(
                  'Presupuesto (MXN): \$${budgetRange.start.toInt()} - \$${budgetRange.end.toInt()}',
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
                  ),
                  child: RangeSlider(
                    values: budgetRange,
                    min: 0,
                    max: 200000,
                    divisions: 50, // 25000 / 50 = 500 pesos por división
                    labels: RangeLabels(
                      '\$${budgetRange.start.toInt()}',
                      '\$${budgetRange.end.toInt()}',
                    ),
                    onChanged: (values) => setState(() => budgetRange = values),
                    onChangeEnd: (values) =>
                        _fetchData(page: 1), // Reinicia a página 1
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

  // (Widget _buildComponentsGrid se mantiene igual)
  Widget _buildComponentsGrid(
    List<ComponentCard> components,
    bool isDesktop,
    Function(ComponentCard) onTapped,
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
        childAspectRatio: 1.1, // Ajustado para incluir la imagen
      ),
      itemCount: components.length,
      itemBuilder: (context, index) {
        final component = components[index];
        return InkWell(
          onTap: () => onTapped(component),
          borderRadius: BorderRadius.circular(12.0),
          child: ComponentCardWidget(component: component),
        );
      },
    );
  }

  // (Widget _buildEmptyState se mantiene igual)
  Widget _buildEmptyState(ThemeData theme) {
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

  // (Widget _buildErrorState se mantiene igual)
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
              error,
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

// (Widget ComponentCardWidget se mantiene igual)
class ComponentCardWidget extends StatelessWidget {
  final ComponentCard component;

  const ComponentCardWidget({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- ¡INICIO DE CORRECCIÓN ESTÉTICA! ---
          if (component.imageUrl != null)
            // 1. Añadimos ClipRRect para redondear las esquinas
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                // 2. Fondo sutil para que 'contain' se vea bien
                color: Colors.black.withOpacity(0.2),
                height: 120, // Altura fija
                width: double.infinity,
                child: Image.network(
                  component.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  // 3. ¡CAMBIO PRINCIPAL!
                  fit: BoxFit.contain, // En lugar de BoxFit.cover
                  // Placeholder mientras carga
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                  },
                  // Error si no puede cargar
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.broken_image,
                    color: Colors.grey[700],
                    size: 48,
                  ),
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8.0), // Redondear también
              ),
              child: Icon(
                Icons.no_photography,
                color: Colors.grey[700],
                size: 48,
              ),
            ),

          const SizedBox(height: 16),
          // --- FIN DE CORRECCIÓN! ---

          // Info Superior
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                component.category,
                style:
                    theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ) ??
                    TextStyle(color: theme.colorScheme.secondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                component.name,
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
                component.brand ?? 'Sin marca',
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
