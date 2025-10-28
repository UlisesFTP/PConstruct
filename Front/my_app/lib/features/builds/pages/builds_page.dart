import 'package:flutter/material.dart';
import 'dart:ui'; // Necesario para BackdropFilter si lo usas en las tarjetas

// Modelo simple para los datos de la build (puedes moverlo a models/ si prefieres)
class CommunityBuild {
  final String authorName;
  final String authorAvatarUrl;
  final String timeAgo;
  final String title;
  final String description;
  final String imageUrl;
  final int likes;
  // Añade más campos si los necesitas (componentes, etc.)

  CommunityBuild({
    required this.authorName,
    required this.authorAvatarUrl,
    required this.timeAgo,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.likes,
  });
}

class BuildsPage extends StatefulWidget {
  const BuildsPage({super.key});

  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  // <-- START OF STATE CLASS
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cpuController = TextEditingController();
  final TextEditingController _gpuController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _ramController = TextEditingController();
  String _selectedUseType = 'Todos';

  // --- DATOS MOCK ---
  final List<CommunityBuild> communityBuilds = [
    CommunityBuild(
      authorName: 'Carlos Dev',
      authorAvatarUrl: 'https://randomuser.me/api/portraits/men/45.jpg',
      timeAgo: 'hace 2 horas',
      title: 'Mi nuevo setup para desarrollo y gaming!',
      description:
          'Después de meses de investigación y gracias a las recomendaciones '
          'de la plataforma, ¡finalmente armé mi PC! Aquí les comparto los '
          'componentes y una foto del resultado final. ¡El rendimiento es increíble!',
      imageUrl: 'https://cdn.mos.cms.futurecdn.net/3mB4dZrRtg8gzDrM8Pvn2R.jpg',
      likes: 128,
    ),
    CommunityBuild(
      authorName: 'Ana Gamer',
      authorAvatarUrl: 'https://randomuser.me/api/portraits/women/33.jpg',
      timeAgo: 'hace 1 día',
      title: 'Build económica para 1080p Ultra',
      description:
          'Quería algo potente sin gastar una fortuna. ¡Esta combinación de Ryzen 5 y RX 6600 funciona de maravilla!',
      imageUrl:
          'https://images.pexels.com/photos/777001/pexels-photo-777001.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500', // Placeholder
      likes: 95,
    ),
  ];
  // --- FIN DATOS MOCK ---

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
    // context is available here
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
                                  controller:
                                      _searchController, // Access state variable
                                  decoration: _inputDecoration(
                                    hintText: 'Buscar builds...',
                                  ), // Call method within state
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              communityBuilds.length, // Access state variable
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: _buildBuildCard(
                                communityBuilds[index],
                              ), // Call method within state
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (showSidebar) _buildSidebar(), // Call method within state
          ],
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

  // --- WIDGETS INTERNOS (NOW INSIDE THE STATE CLASS) ---

  Widget _buildBuildCard(CommunityBuild build) {
    // This method now correctly belongs to the State class
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(build.authorAvatarUrl),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          build.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          build.timeAgo,
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
                Text(
                  build.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  build.description,
                  style: const TextStyle(color: Color(0xFFE0E0E0)),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    build.imageUrl,
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.whatshot,
                            color: Color(0xFFC7384D),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            build.likes.toString(),
                            style: const TextStyle(color: Color(0xFFA0A0A0)),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          /* TODO */
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

  Widget _buildSidebar() {
    // This method now correctly belongs to the State class
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
    // This method now correctly belongs to the State class
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
    // This method now correctly belongs to the State class
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
} // <-- END OF STATE CLASS
