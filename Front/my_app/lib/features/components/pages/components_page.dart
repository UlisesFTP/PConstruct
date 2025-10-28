// lib/features/components/pages/components_page.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:my_app/models/component.dart'; // Importa el nuevo modelo
import 'package:my_app/core/theme/app_theme.dart'; // Para estilos consistentes

class ComponentsPage extends StatefulWidget {
  const ComponentsPage({super.key});

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage>
    with SingleTickerProviderStateMixin {
  // Necesario para la animación

  // Datos de ejemplo (mantenidos de tu código)
  final List<Component> allComponents = [
    Component(
      id: 1,
      name: 'NVMe 1TB Samsung 980',
      categoria: 'Almacenamiento',
      marca: 'Samsung',
      uso: 'gaming',
      price: 3200,
      stores: ['Amazon', 'Mercado Libre'],
    ),
    Component(
      id: 2,
      name: 'Intel Core i5-13600K',
      categoria: 'CPU',
      marca: 'Intel',
      uso: 'gaming',
      price: 6900,
      stores: ['Amazon'],
    ),
    Component(
      id: 3,
      name: 'Gigabyte B660 Motherboard',
      categoria: 'Motherboard',
      marca: 'Gigabyte',
      uso: 'oficina',
      price: 2800,
      stores: ['Mercado Libre'],
    ),
    Component(
      id: 4,
      name: 'Corsair 16GB DDR4',
      categoria: 'RAM',
      marca: 'Corsair',
      uso: 'gaming',
      price: 1200,
      stores: ['Amazon', 'Newegg'],
    ),
    Component(
      id: 5,
      name: 'MSI GTX 1660 Super',
      categoria: 'GPU',
      marca: 'MSI',
      uso: 'gaming',
      price: 5400,
      stores: ['Amazon'],
    ),
    Component(
      id: 6,
      name: 'HP 500W PSU',
      categoria: 'PSU',
      marca: 'HP',
      uso: 'oficina',
      price: 900,
      stores: ['Mercado Libre'],
    ),
  ];
  // TODO: Reemplazar con FutureBuilder cuando tengamos endpoint

  // Estados de los filtros
  String searchQuery = '';
  String selectedUso = '';
  String selectedCategoria = '';
  String selectedMarca = '';
  double budgetMax = 25000;

  // Controlador de animación (mantenido de tu código)
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.12, end: 0.18).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Lógica de filtrado (mantenida de tu código)
  List<Component> get filteredComponents {
    return allComponents.where((component) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!component.name.toLowerCase().contains(query) &&
            !component.marca.toLowerCase().contains(query) &&
            !component.categoria.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (selectedUso.isNotEmpty && component.uso != selectedUso) return false;
      if (selectedCategoria.isNotEmpty &&
          component.categoria != selectedCategoria)
        return false;
      if (selectedMarca.isNotEmpty && component.marca != selectedMarca)
        return false;
      if (component.price > budgetMax) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;
    final filteredList = filteredComponents;
    final theme = Theme.of(context); // Obtenemos el tema

    // No usamos Scaffold, devolvemos el contenido
    return Stack(
      children: [
        // Gradiente animado de fondo
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
        // Contenido principal con SingleChildScrollView
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 24, // Padding ajustado
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Alinea título a la izquierda
            children: [
              // Título de la página (más prominente)
              Padding(
                padding: EdgeInsets.only(
                  bottom: 24.0,
                  left: isDesktop ? 0 : 0,
                ), // Ajuste padding título
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
              _buildFiltersSection(theme), // Pasamos el tema
              const SizedBox(height: 32), // Aumentamos espacio
              // Resultados o estado vacío
              if (filteredList.isEmpty)
                _buildEmptyState(theme) // Pasamos el tema
              else
                _buildComponentsGrid(filteredList, isDesktop, (component) {
                  // Navega a la página de detalle con el ID
                  Navigator.pushNamed(
                    context,
                    '/component-detail',
                    arguments: component.id, // Pasamos el ID como argumento
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // Widget para la sección de filtros
  Widget _buildFiltersSection(ThemeData theme) {
    return _GlassmorphismCard(
      // Reutilizamos el estilo de tarjeta
      child: Wrap(
        // Usamos Wrap para que los filtros se ajusten
        spacing: 16, // Espacio horizontal
        runSpacing: 16, // Espacio vertical
        alignment: WrapAlignment.start, // Alineación
        children: [
          // Filtro de Uso
          _buildFilterDropdown(
            theme: theme,
            label: 'Uso',
            value: selectedUso,
            items: ['', 'gaming', 'oficina'],
            itemLabels: ['Todos', 'Gaming', 'Oficina'],
            onChanged: (value) => setState(() => selectedUso = value ?? ''),
            minWidth: 150, // Ancho mínimo
          ),

          // Filtro de Categoría
          _buildFilterDropdown(
            theme: theme,
            label: 'Categoría',
            value: selectedCategoria,
            items: [
              '',
              'CPU',
              'GPU',
              'Motherboard',
              'PSU',
              'RAM',
              'Almacenamiento',
              'Tarjeta red',
              'Gabinete',
            ],
            itemLabels: [
              'Todas',
              'CPU',
              'GPU',
              'Motherboard',
              'PSU',
              'RAM',
              'Almacenamiento',
              'Tarjeta red',
              'Gabinete',
            ],
            onChanged: (value) =>
                setState(() => selectedCategoria = value ?? ''),
            minWidth: 180,
          ),

          // Filtro de Marca
          _buildFilterDropdown(
            theme: theme,
            label: 'Marca',
            value: selectedMarca,
            items: [
              '',
              'Lenovo',
              'Gigabyte',
              'HP',
              'Dell',
              'ASUS',
              'MSI',
              'Samsung',
              'Intel',
              'Corsair',
            ],
            itemLabels: [
              'Todas',
              'Lenovo',
              'Gigabyte',
              'HP',
              'Dell',
              'ASUS',
              'MSI',
              'Samsung',
              'Intel',
              'Corsair',
            ],
            onChanged: (value) => setState(() => selectedMarca = value ?? ''),
            minWidth: 150,
          ),

          // Filtro de Presupuesto (Slider)
          // Usamos Flexible para que tome el espacio restante si es necesario
          ConstrainedBox(
            // Para darle un ancho mínimo y máximo
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presupuesto (MXN) ≤ \$${budgetMax.toInt()}',
                  style:
                      theme.textTheme.labelMedium?.copyWith(
                        // Estilo de etiqueta
                        color: theme.colorScheme.secondary,
                      ) ??
                      TextStyle(
                        color: theme.colorScheme.secondary,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 4), // Menos espacio
                SliderTheme(
                  // Aplicamos el tema primario al Slider
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: theme.primaryColor,
                    inactiveTrackColor: theme.dividerColor.withOpacity(0.5),
                    thumbColor: theme.primaryColor,
                    overlayColor: theme.primaryColor.withOpacity(0.2),
                    trackHeight: 2.0, // Track más delgado
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8.0,
                    ), // Pulgar más pequeño
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16.0,
                    ), // Overlay más pequeño
                  ),
                  child: Slider(
                    value: budgetMax,
                    min: 100,
                    max: 25000,
                    divisions: 249, // Mantenemos divisiones
                    label:
                        '\$${budgetMax.toInt()}', // Etiqueta opcional al arrastrar
                    onChanged: (value) => setState(() => budgetMax = value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper para Dropdowns de filtro
  Widget _buildFilterDropdown({
    required ThemeData theme,
    required String label,
    required String value,
    required List<String> items,
    required List<String> itemLabels,
    required ValueChanged<String?> onChanged,
    double minWidth = 150, // Ancho mínimo por defecto
  }) {
    return ConstrainedBox(
      // Para controlar el ancho
      constraints: BoxConstraints(minWidth: minWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize
            .min, // Para que la columna no ocupe más alto del necesario
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
          // Dropdown con estilo mejorado
          Container(
            height: 48, // Altura fija para alinear con TextFields
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  theme.inputDecorationTheme.fillColor ??
                  Colors.grey.shade900, // Color de fondo del tema
              borderRadius: BorderRadius.circular(
                12,
              ), // Borde redondeado del tema
              border: Border.all(
                color: Colors.transparent,
              ), // Sin borde visible inicial
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: theme.cardColor.withOpacity(
                  0.95,
                ), // Fondo del dropdown (puede ser cardColor)
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.colorScheme.secondary,
                ), // Color del icono
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ), // Estilo del texto seleccionado
                items: List.generate(items.length, (index) {
                  return DropdownMenuItem(
                    value: items[index],
                    child: Text(
                      itemLabels[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ), // Estilo de los items
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

  // Widget para la cuadrícula de componentes
  Widget _buildComponentsGrid(
    List<Component> components,
    bool isDesktop,
    Function(Component) onTapped,
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
        // --- MODIFICACIÓN AQUÍ: Envolvemos en InkWell ---
        return InkWell(
          onTap: () {
            // Modifica el onTap para usar Navigator.pushNamed directamente
            Navigator.pushNamed(
              context,
              '/component-detail',
              arguments: components[index], // <-- PASA EL OBJETO COMPLETO
            );
          },
          borderRadius: BorderRadius.circular(12.0),
          child: ComponentCard(component: components[index]),
        );
        // --- FIN MODIFICACIÓN ---
      },
    );
  }

  // Widget para estado vacío
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 64,
          horizontal: 32,
        ), // Más padding
        child: Column(
          // Usamos columna para icono y texto
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron componentes', // Texto más claro
              style:
                  theme.textTheme.titleMedium?.copyWith(
                    // titleMedium para mensaje principal
                    color: theme.colorScheme.secondary,
                  ) ??
                  TextStyle(color: theme.colorScheme.secondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros o la búsqueda.', // Texto secundario
              style:
                  theme.textTheme.bodySmall?.copyWith(
                    // bodySmall
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

// --- TARJETA DE COMPONENTE (Estilo ajustado) ---
class ComponentCard extends StatelessWidget {
  final Component component;

  const ComponentCard({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassmorphismCard(
      // Reutilizamos el estilo de tarjeta base
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Para empujar precio/tiendas abajo
        children: [
          // Info Superior (Categoría, Nombre, Marca)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                component.categoria,
                style:
                    theme.textTheme.bodySmall?.copyWith(
                      // bodySmall para categoría
                      color: theme.colorScheme.secondary,
                    ) ??
                    TextStyle(color: theme.colorScheme.secondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                component.name,
                style:
                    theme.textTheme.titleMedium?.copyWith(
                      // titleMedium para nombre
                      color: Colors.white,
                      fontWeight: FontWeight.bold, // Negrita
                    ) ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 16, // Tamaño base
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2, // Permitir 2 líneas
                overflow: TextOverflow.ellipsis, // Cortar si es más largo
              ),
              const SizedBox(height: 4),
              Text(
                component.marca,
                style:
                    theme.textTheme.bodyMedium?.copyWith(
                      // bodyMedium para marca
                      color: theme.colorScheme.secondary,
                    ) ??
                    TextStyle(color: theme.colorScheme.secondary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16), // Espacio entre info y precio/tiendas
          // Info Inferior (Precio, Tiendas)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${component.price.toStringAsFixed(0)} MXN', // Añadir MXN
                style:
                    theme.textTheme.headlineSmall?.copyWith(
                      // headlineSmall para precio
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ) ??
                    TextStyle(
                      color: theme.primaryColor,
                      fontSize: 20, // Ligeramente más grande
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Disponible en: ${component.stores.join(', ')}',
                style:
                    theme.textTheme.bodySmall?.copyWith(
                      // bodySmall para tiendas
                      color: theme.colorScheme.secondary.withOpacity(
                        0.8,
                      ), // Más sutil
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

// --- WIDGET HELPER REUTILIZADO ---
// Tarjeta Glassmorphism (Padding estandarizado)
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
                    .withOpacity(0.7), // Usa cardColor o surface
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.all(24.0), // Padding estándar
          child: child,
        ),
      ),
    );
  }
}
