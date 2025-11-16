// lib/features/components/pages/components_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Paginación
  int _currentPage = 1;
  int _totalItems = 0;
  final int _pageSize = 50;

  // Filtros
  String selectedCategoria = '';
  String selectedMarca = '';
  RangeValues budgetRange = const RangeValues(0, 200000);
  String sortBy = 'price_asc';

  // Animación
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Control de filtros en móvil
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<ApiClient>(context, listen: false);
    _fetchData(page: 1);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.12, end: 0.18).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _fetchData({required int page}) {
    setState(() {
      _currentPage = page;
      _componentsFuture = _apiClient.fetchComponents(
        page: _currentPage,
        pageSize: _pageSize,
        category: selectedCategoria.isNotEmpty ? selectedCategoria : null,
        brand: selectedMarca.isNotEmpty ? selectedMarca : null,
        minPrice: (budgetRange.start > 0) ? budgetRange.start : null,
        maxPrice: (budgetRange.end < 200000) ? budgetRange.end : null,
        sortBy: sortBy,
      );
    });
  }

  void _resetFilters() {
    setState(() {
      selectedCategoria = '';
      selectedMarca = '';
      budgetRange = const RangeValues(0, 200000);
      sortBy = 'price_asc';
    });
    _fetchData(page: 1);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;
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

        // Contenido
        CustomScrollView(
          slivers: [
            // Header sticky
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: isMobile ? 140 : 160,
              pinned: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  return FlexibleSpaceBar(
                    background: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            border: const Border(
                              bottom: BorderSide(
                                color: Color(0xFF2A2A2A),
                                width: 1,
                              ),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : (isTablet ? 24 : 32),
                            vertical: 12,
                          ),
                          child: SafeArea(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Componentes',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isMobile ? 22 : 28,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            FutureBuilder<
                                              PaginatedComponentsResponse
                                            >(
                                              future: _componentsFuture,
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Text(
                                                    '${snapshot.data!.totalItems} productos',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFFA0A0A0,
                                                      ),
                                                      fontSize: isMobile
                                                          ? 12
                                                          : 13,
                                                    ),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Botón de filtros en móvil
                                      if (isMobile)
                                        IconButton(
                                          onPressed: () {
                                            setState(
                                              () =>
                                                  _showFilters = !_showFilters,
                                            );
                                          },
                                          icon: Stack(
                                            children: [
                                              Icon(
                                                _showFilters
                                                    ? Icons.filter_alt
                                                    : Icons.filter_alt_outlined,
                                                color: Colors.white,
                                              ),
                                              if (_hasActiveFilters())
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: theme.primaryColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          tooltip: 'Filtros',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Ordenamiento rápido
                                  _buildQuickSort(theme, isMobile),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Contenido principal
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : (isTablet ? 24 : 32),
                vertical: 16,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Filtros (colapsables en móvil)
                  if (isMobile && _showFilters || !isMobile) ...[
                    _buildFiltersSection(theme, isMobile, isTablet),
                    const SizedBox(height: 24),
                  ],

                  // Grid de componentes
                  FutureBuilder<PaginatedComponentsResponse>(
                    future: _componentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingSkeleton(isMobile, isTablet);
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState(
                          theme,
                          snapshot.error.toString(),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.components.isEmpty) {
                        return _buildEmptyState(theme);
                      }

                      final response = snapshot.data!;
                      final components = response.components;
                      _totalItems = response.totalItems;
                      final totalPages = (_totalItems / _pageSize).ceil();

                      return Column(
                        children: [
                          _buildComponentsGrid(
                            components,
                            isMobile,
                            isTablet,
                            isDesktop,
                          ),
                          const SizedBox(height: 32),
                          _buildPaginationControls(totalPages, isMobile),
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return selectedCategoria.isNotEmpty ||
        selectedMarca.isNotEmpty ||
        budgetRange.start > 0 ||
        budgetRange.end < 200000;
  }

  Widget _buildQuickSort(ThemeData theme, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SortChip(
            label: 'Precio: Menor a Mayor',
            isSelected: sortBy == 'price_asc',
            onTap: () {
              setState(() => sortBy = 'price_asc');
              _fetchData(page: 1);
            },
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Precio: Mayor a Menor',
            isSelected: sortBy == 'price_desc',
            onTap: () {
              setState(() => sortBy = 'price_desc');
              _fetchData(page: 1);
            },
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Más Recientes',
            isSelected: sortBy == 'newest',
            onTap: () {
              setState(() => sortBy = 'newest');
              _fetchData(page: 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme, bool isMobile, bool isTablet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: _GlassmorphismCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: theme.primaryColor,
                      size: isMobile ? 20 : 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filtros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_hasActiveFilters())
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpiar'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2A2A2A)),
            const SizedBox(height: 16),

            // Filtros en layout responsive
            if (isMobile)
              Column(
                children: [
                  _buildCategoryFilter(theme),
                  const SizedBox(height: 16),
                  _buildBrandFilter(theme),
                  const SizedBox(height: 16),
                  _buildBudgetFilter(theme),
                ],
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildCategoryFilter(theme),
                  _buildBrandFilter(theme),
                  _buildBudgetFilter(theme),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    return _FilterDropdown(
      theme: theme,
      label: 'Categoría',
      value: selectedCategoria,
      icon: Icons.category_outlined,
      items: const [
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
      itemLabels: const [
        'Todas las categorías',
        'CPU',
        'GPU',
        'Motherboard',
        'PSU',
        'RAM',
        'SSD',
        'HDD',
        'Gabinete',
        'Enfriamiento',
        'Ventiladores',
        'Laptop',
        'Laptop Gamer',
      ],
      onChanged: (value) {
        setState(() => selectedCategoria = value ?? '');
        _fetchData(page: 1);
      },
    );
  }

  Widget _buildBrandFilter(ThemeData theme) {
    return _FilterDropdown(
      theme: theme,
      label: 'Marca',
      value: selectedMarca,
      icon: Icons.business_outlined,
      items: const [
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
      itemLabels: const [
        'Todas las marcas',
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
        _fetchData(page: 1);
      },
    );
  }

  Widget _buildBudgetFilter(ThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 350),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Presupuesto',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${budgetRange.start.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} MXN',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$${budgetRange.end.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} MXN',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: theme.primaryColor,
                    inactiveTrackColor: theme.dividerColor.withOpacity(0.5),
                    thumbColor: theme.primaryColor,
                    overlayColor: theme.primaryColor.withOpacity(0.2),
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: RangeSlider(
                    values: budgetRange,
                    min: 0,
                    max: 200000,
                    divisions: 50,
                    onChanged: (values) => setState(() => budgetRange = values),
                    onChangeEnd: (values) => _fetchData(page: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isMobile, bool isTablet) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.2 : 0.85,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _SkeletonCard(),
    );
  }

  Widget _buildComponentsGrid(
    List<ComponentCard> components,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.2 : 0.85,
      ),
      itemCount: components.length,
      itemBuilder: (context, index) {
        final component = components[index];
        return ComponentCardWidget(
          component: component,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/component-detail',
              arguments: component.id,
            );
          },
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalPages, bool isMobile) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Primer página
          IconButton(
            onPressed: _currentPage <= 1 ? null : () => _fetchData(page: 1),
            icon: const Icon(Icons.first_page),
            color: Colors.white,
            disabledColor: Colors.grey[700],
            tooltip: 'Primera página',
          ),

          // Página anterior
          IconButton(
            onPressed: _currentPage <= 1
                ? null
                : () => _fetchData(page: _currentPage - 1),
            icon: const Icon(Icons.chevron_left),
            color: Colors.white,
            disabledColor: Colors.grey[700],
            tooltip: 'Anterior',
          ),

          // Indicador de página
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              isMobile
                  ? '$_currentPage / $totalPages'
                  : 'Página $_currentPage de $totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // Página siguiente
          IconButton(
            onPressed: _currentPage >= totalPages
                ? null
                : () => _fetchData(page: _currentPage + 1),
            icon: const Icon(Icons.chevron_right),
            color: Colors.white,
            disabledColor: Colors.grey[700],
            tooltip: 'Siguiente',
          ),

          // Última página
          IconButton(
            onPressed: _currentPage >= totalPages
                ? null
                : () => _fetchData(page: totalPages),
            icon: const Icon(Icons.last_page),
            color: Colors.white,
            disabledColor: Colors.grey[700],
            tooltip: 'Última página',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No se encontraron componentes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Intenta ajustar los filtros o el presupuesto.',
              style: TextStyle(color: const Color(0xFFA0A0A0), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Limpiar filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error al cargar componentes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchData(page: _currentPage),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGETS AUXILIARES
// ==========================================

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.2)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : const Color(0xFF2A2A2A),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.primaryColor : Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;
  final List<String> items;
  final List<String> itemLabels;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    required this.items,
    required this.itemLabels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
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
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: List.generate(items.length, (index) {
                  return DropdownMenuItem(
                    value: items[index],
                    child: Text(
                      itemLabels[index],
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
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _GlassmorphismCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen skeleton
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              // Categoría skeleton
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
              // Nombre skeleton
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const Spacer(),
              // Precio skeleton
              Container(
                width: 100,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// COMPONENT CARD WIDGET (MEJORADO)
// ==========================================

class ComponentCardWidget extends StatefulWidget {
  final ComponentCard component;
  final VoidCallback onTap;

  const ComponentCardWidget({
    super.key,
    required this.component,
    required this.onTap,
  });

  @override
  State<ComponentCardWidget> createState() => _ComponentCardWidgetState();
}

class _ComponentCardWidgetState extends State<ComponentCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: _GlassmorphismCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del componente
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.black.withOpacity(0.2),
                        child: widget.component.imageUrl != null
                            ? Image.network(
                                widget.component.imageUrl!,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                          : null,
                                      color: theme.primaryColor,
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey[700],
                                      size: 48,
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.memory,
                                  color: Colors.grey[700],
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                    // Badge de categoría
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.component.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Información del componente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      Text(
                        widget.component.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Marca
                      if (widget.component.brand != null)
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 14,
                              color: const Color(0xFFA0A0A0),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.component.brand!,
                                style: const TextStyle(
                                  color: Color(0xFFA0A0A0),
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      const Spacer(),

                      const Divider(color: Color(0xFF2A2A2A), height: 16),

                      // Precio y tienda
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.component.price != null) ...[
                                  Text(
                                    NumberFormat().format(
                                      widget.component.price!.round(),
                                    ),
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'MXN',
                                    style: TextStyle(
                                      color: theme.primaryColor.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ] else
                                  const Text(
                                    'Precio no disponible',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Icono de tienda
                          if (widget.component.store != null)
                            Tooltip(
                              message: widget.component.store!,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF2A2A2A),
                                  ),
                                ),
                                child: Icon(
                                  Icons.store,
                                  size: 18,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                        ],
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
}

// ==========================================
// GLASSMORPHISM CARD
// ==========================================

class _GlassmorphismCard extends StatelessWidget {
  final Widget child;

  const _GlassmorphismCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
