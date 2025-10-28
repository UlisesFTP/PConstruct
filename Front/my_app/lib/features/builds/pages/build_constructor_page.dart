import 'package:flutter/material.dart';
import 'dart:ui'; // For potential BackdropFilter if needed later

// Renamed local Component model to avoid conflict with lib/models/component.dart
class BuildComponentChoice {
  final String name;
  final int price;
  final String brand;
  final String img;
  final Map<String, String> links;

  BuildComponentChoice({
    required this.name,
    required this.price,
    required this.brand,
    required this.img,
    required this.links,
  });
}

class BuildConstructorPage extends StatefulWidget {
  // Removed const from constructor as controllers make it non-constant
  BuildConstructorPage({super.key});

  @override
  State<BuildConstructorPage> createState() => _BuildConstructorPageState();
}

class _BuildConstructorPageState extends State<BuildConstructorPage> {
  // --- MOCK DATA ---
  // Using the renamed model BuildComponentChoice
  final Map<String, List<BuildComponentChoice>> buildComponents = {
    'cpu': [
      BuildComponentChoice(
        name: 'Intel Core i9-14900K',
        price: 13500,
        brand: 'Intel',
        img: 'https://via.placeholder.com/100',
        links: {'amazon': '#', 'ml': '#', 'cyber': '#'},
      ),
      BuildComponentChoice(
        name: 'AMD Ryzen 9 7950X',
        price: 11000,
        brand: 'AMD',
        img: 'https://via.placeholder.com/100',
        links: {'amazon': '#', 'ml': '#', 'cyber': '#'},
      ),
    ],
    'gpu': [
      BuildComponentChoice(
        name: 'RTX 4090',
        price: 35000,
        brand: 'NVIDIA',
        img: 'https://via.placeholder.com/100',
        links: {'amazon': '#', 'ml': '#', 'cyber': '#'},
      ),
      BuildComponentChoice(
        name: 'RX 7900 XTX',
        price: 21000,
        brand: 'AMD',
        img: 'https://via.placeholder.com/100',
        links: {'amazon': '#', 'ml': '#', 'cyber': '#'},
      ),
    ],
    'motherboard': [
      BuildComponentChoice(
        name: 'MSI B760',
        price: 4500,
        brand: 'MSI',
        img: 'https://via.placeholder.com/100',
        links: {'amazon': '#', 'ml': '#', 'cyber': '#'},
      ),
      BuildComponentChoice(
        name: 'ASUS ROG STRIX B760',
        price: 5000,
        brand: 'ASUS',
        img: 'https://via.placeholder.com/100',
        links: {'amazon': '#', 'ml': '#', 'cyber': '#'},
      ),
    ],
    'ram': [
      BuildComponentChoice(
        name: 'Corsair Vengeance 32GB',
        price: 3000,
        brand: 'Corsair',
        img: 'https://via.placeholder.com/100',
        links: {'amazon': '#', 'ml': '#', 'cyber': '#'},
      ),
      BuildComponentChoice(
        name: 'G.Skill Trident Z 32GB',
        price: 3200,
        brand: 'G.Skill',
        img: 'https://via.placeholder.com/100',
        links: {'amazon': '#', 'ml': '#', 'cyber': '#'},
      ),
    ],
    'storage_primary': [
      BuildComponentChoice(
        name: 'Samsung 980 Pro 1TB',
        price: 2500,
        brand: 'Samsung',
        img: 'https://via.placeholder.com/100',
        links: {'amazon': '#', 'ml': '#', 'cyber': '#'},
      ),
    ],
    'cooler': [
      BuildComponentChoice(
        name: 'Cooler Master Hyper 212',
        price: 800,
        brand: 'Cooler Master',
        img: 'https://via.placeholder.com/100',
        links: {'amazon': '#', 'ml': '#', 'cyber': '#'},
      ),
    ],
    // Add other categories like case, psu, etc. if needed
  };

  final Map<String, IconData> icons = {
    'cpu': Icons.memory,
    'gpu': Icons.developer_board_outlined, // Changed icon
    'motherboard': Icons.developer_board,
    'ram': Icons.memory_outlined, // Changed icon
    'storage_primary': Icons.save, // Changed icon
    'storage_secondary': Icons.save_alt, // Changed icon
    'cooler': Icons.ac_unit,
    'case': Icons.desktop_windows_outlined, // Changed icon
    'psu': Icons.power,
    'fans': Icons.wind_power, // Changed icon
    // Peripherals might not belong in the core build constructor?
    'headphones': Icons.headphones,
    'network_cards': Icons.router,
    'monitors': Icons.monitor,
    'keyboard': Icons.keyboard,
    'mouse': Icons.mouse,
    'os': Icons.computer,
    'ups': Icons.battery_charging_full,
  };
  // --- END MOCK DATA ---

  // Component Types to display in order
  // Added some common missing ones
  final List<String> componentOrder = [
    'cpu',
    'motherboard',
    'ram',
    'gpu',
    'storage_primary',
    'storage_secondary',
    'cooler',
    'case',
    'psu',
    'fans',
    'os',
  ];

  // State variables
  final Map<String, BuildComponentChoice> selectedComponents = {};
  final Map<String, bool> expandedSections = {};
  final Map<String, TextEditingController> searchControllers = {};
  final Map<String, TextEditingController> minPriceControllers = {};
  final Map<String, TextEditingController> maxPriceControllers = {};
  final Map<String, String> selectedBrands = {};

  @override
  void initState() {
    super.initState();
    // Initialize state for component types defined in componentOrder
    for (var type in componentOrder) {
      // Use componentOrder
      expandedSections[type] = false;
      searchControllers[type] = TextEditingController();
      minPriceControllers[type] = TextEditingController();
      maxPriceControllers[type] = TextEditingController();
      selectedBrands[type] = '';
      // Initialize mock data if missing for types in componentOrder
      if (!buildComponents.containsKey(type)) {
        buildComponents[type] =
            []; // Add empty list for types without mock data yet
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    searchControllers.values.forEach((controller) => controller.dispose());
    minPriceControllers.values.forEach((controller) => controller.dispose());
    maxPriceControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Calculate total price
  int get totalPrice {
    return selectedComponents.values.fold(0, (sum, comp) => sum + comp.price);
  }

  // Filter components for a section based on search, price, brand
  List<BuildComponentChoice> getFilteredComponents(String type) {
    final components = buildComponents[type] ?? [];
    final search = searchControllers[type]?.text.toLowerCase() ?? '';
    final minPrice = int.tryParse(minPriceControllers[type]?.text ?? '') ?? 0;
    final maxPriceText = maxPriceControllers[type]?.text ?? '';
    final maxPrice = maxPriceText.isEmpty
        ? 9999999 // Use a very large number instead of infinity
        : int.tryParse(maxPriceText) ?? 9999999;
    final brand = selectedBrands[type] ?? '';

    return components.where((comp) {
      final matchesSearch = comp.name.toLowerCase().contains(search);
      final matchesPrice = comp.price >= minPrice && comp.price <= maxPrice;
      final matchesBrand = brand.isEmpty || comp.brand == brand;
      return matchesSearch && matchesPrice && matchesBrand;
    }).toList();
  }

  // Get unique brands for a component type
  Set<String> getBrands(String type) {
    return (buildComponents[type] ?? []).map((c) => c.brand).toSet();
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width >
        900; // Adjusted breakpoint for sidebar
    final theme = Theme.of(context);

    // No Scaffold, return the content directly
    return Row(
      // Use Row for main layout + sidebar on desktop
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Constructor Area
        Expanded(
          // flex: isDesktop ? 2 : 1, // Adjust flex ratio if needed
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Crear Nueva Build', // Updated Title
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
                  'Selecciona los componentes para tu nueva configuración.', // Subtitle
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[400],
                      ) ??
                      TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(height: 32),
                // Component Sections List
                Column(
                  // Generate sections directly within the Column
                  children: componentOrder.map((type) {
                    return _buildComponentSection(type);
                  }).toList(),
                ),
                // ... componentOrder.map((type) => _buildComponentSection(type)), // Map through ordered list
              ],
            ),
          ),
        ),

        // Sidebar Summary (Only on Desktop)
        if (isDesktop)
          SizedBox(
            width: 350, // Fixed width for sidebar
            // Tries to size child to intrinsic height
            child: _buildSidebar(),
          ),
        // If not desktop, consider showing summary in a different way (e.g., bottom sheet, separate page)
      ],
    );
  }

  // --- HELPER WIDGETS (INSIDE STATE CLASS) ---

  // Builds a collapsible section for a component type
  Widget _buildComponentSection(String type) {
    final isExpanded = expandedSections[type] ?? false;
    final displayName = type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' '); // Capitalize words
    final selectedComp = selectedComponents[type];
    final filteredList = getFilteredComponents(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // Use theme surface color with opacity for glassmorphism base
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ClipRRect(
        // Clip for BackdropFilter effect
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          // Apply blur effect
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(
            children: [
              // Header Row (Icon, Name, Selected Item / Expand Icon)
              InkWell(
                onTap: () {
                  setState(() {
                    expandedSections[type] = !isExpanded;
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
                            icons[type] ??
                                Icons.help_outline, // Use help icon as fallback
                            color: const Color(0xFFC7384D),
                          ),
                          const SizedBox(width: 12), // Increased spacing
                          Text(
                            displayName,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ) ??
                                const TextStyle(
                                  color: Colors.white, // White text for title
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                          ),
                        ],
                      ),
                      // Show selected component name or expand icon
                      if (selectedComp != null && !isExpanded)
                        Expanded(
                          // Allow text to wrap/ellipsis if needed
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                            ), // Add padding
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
                          turns: isExpanded ? 0.5 : 0, // Rotate arrow up/down
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
              // Collapsible Content Area
              AnimatedSize(
                // Animate size change
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  // Use height constraint trick for animation
                  height: isExpanded ? null : 0,
                  clipBehavior: Clip.hardEdge, // Clip content during animation
                  decoration: const BoxDecoration(
                    // Add a subtle top border when expanded
                    border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16,
                    ), // Adjusted padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilters(type),
                        const SizedBox(height: 20), // Increased space
                        // Message if no components available/filtered
                        if (filteredList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                "No hay componentes que coincidan.",
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true, // Crucial
                            physics:
                                const NeverScrollableScrollPhysics(), // Crucial
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              // Build the card directly here
                              return _buildComponentCard(
                                type,
                                filteredList[index],
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

  // Builds the filter row for a component section
  Widget _buildFilters(String type) {
    final theme = Theme.of(context);
    List<String> brandItems = ['']..addAll(getBrands(type)); // Add 'All' option

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end, // Align items vertically
      children: [
        // Search Field
        SizedBox(
          width: 200,
          child: _buildFilterTextField(
            controller: searchControllers[type],
            hintText: 'Buscar...',
            onChanged: (_) => setState(() {}), // Trigger rebuild on change
            icon: Icons.search,
          ),
        ),
        // Min Price
        SizedBox(
          width: 100,
          child: _buildFilterTextField(
            controller: minPriceControllers[type],
            hintText: 'Min \$',
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            icon: Icons.attach_money,
          ),
        ),
        // Max Price
        SizedBox(
          width: 100,
          child: _buildFilterTextField(
            controller: maxPriceControllers[type],
            hintText: 'Max \$',
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            icon: Icons.money_off, // Different icon for max
          ),
        ),
        // Brand Dropdown
        Container(
          constraints: const BoxConstraints(
            minWidth: 150,
          ), // Ensure minimum width
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 40, // Match TextField height
          decoration: BoxDecoration(
            color:
                theme.inputDecorationTheme.fillColor ??
                Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedBrands[type], // Use state variable
              isDense: true,
              dropdownColor: const Color(0xFF1C1C1C), // Darker dropdown
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
              items: brandItems
                  .map(
                    (brand) => DropdownMenuItem(
                      value: brand,
                      child: Text(brand.isEmpty ? 'Todas las Marcas' : brand),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedBrands[type] = value ?? ''; // Update state
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // Helper for creating styled TextFields used in filters
  Widget _buildFilterTextField({
    required TextEditingController? controller,
    String hintText = '',
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    IconData? icon,
  }) {
    return SizedBox(
      height: 40, // Consistent height for filter inputs
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 14,
        ), // Input text style
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
          ), // Use theme color on focus
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ), // Adjusted padding
          isDense: true,
        ),
      ),
    );
  }

  // Builds a card showing a single component choice
  Widget _buildComponentCard(String type, BuildComponentChoice comp) {
    final bool isSelected =
        selectedComponents[type] == comp; // Check if selected
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withOpacity(0.15)
            : Colors.black.withOpacity(0.2), // Highlight if selected
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.primaryColor
              : const Color(0xFF3A3A3A), // Highlight border
        ),
      ),
      child: Material(
        // Wrap with Material for InkWell effect
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedComponents.remove(type); // Deselect if tapped again
              } else {
                selectedComponents[type] = comp; // Select this component
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    comp.img,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain, // Contain fits components better
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
                // Name, Brand, Price
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
                      ), // Slightly smaller
                      const SizedBox(height: 4),
                      Text(
                        'Marca: ${comp.brand}',
                        style: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Precio: \$${comp.price} MXN',
                        style: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Links (optional - consider showing them differently, maybe on hover/tap)
                // Wrap( ... ) // Kept original links for now

                // Selection Indicator (Checkmark)
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

  // Builds the sidebar summarizing the selected components and total price
  Widget _buildSidebar() {
    final theme = Theme.of(context);
    final bool hasSelection = selectedComponents.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C).withOpacity(0.8),
        border: const Border(left: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Column(
        children: [
          // Header
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

          // List of selected components
          Expanded(
            child: !hasSelection
                ? Center(
                    child: Text(
                      "Selecciona componentes...",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView(
                    // <-- Apply fixes here
                    padding: const EdgeInsets.all(24),
                    children: selectedComponents.entries.map((entry) {
                      // ... (rest of the map function remains the same) ...
                      final type = entry.key;
                      final comp = entry.value;
                      final displayName = type
                          .replaceAll('_', ' ')
                          .split(' ')
                          .map(
                            (word) => word[0].toUpperCase() + word.substring(1),
                          )
                          .join(' ');
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
                              icons[type] ?? Icons.help_outline,
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
                            // Price of the selected component
                            Text(
                              "\$${comp.price}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Optional: Remove button
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
                                  selectedComponents.remove(type);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // Footer with Total Price and Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF101010), // Darker footer background
              border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
            ),
            child: Column(
              children: [
                // Total Price Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Precio Total:',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    Text(
                      '\$$totalPrice MXN',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Action Buttons
                ElevatedButton.icon(
                  onPressed: hasSelection
                      ? () {
                          /* TODO: Save Build Logic */
                        }
                      : null, // Disable if no selection
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Guardar Build'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.grey[800], // Style for disabled state
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  // Changed to OutlinedButton for secondary action
                  onPressed: hasSelection
                      ? () {
                          /* TODO: Publish Build Logic */
                        }
                      : null, // Disable if no selection
                  icon: const Icon(Icons.public, size: 18),
                  label: const Text('Publicar Build'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[300],
                    side: BorderSide(
                      color: hasSelection
                          ? theme.primaryColor.withOpacity(0.5)
                          : Colors.grey[800]!,
                    ), // Border color changes
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
} // --- END OF STATE CLASS ---
