// lib/features/builds/pages/my_builds_page.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:my_app/models/pc_build.dart'; // <-- Importa el nuevo modelo

class MyBuildsPage extends StatefulWidget {
  const MyBuildsPage({super.key});

  @override
  State<MyBuildsPage> createState() => _MyBuildsPageState();
}

class _MyBuildsPageState extends State<MyBuildsPage> {
  // Datos mock de tu ejemplo
  final List<PCBuild> builds = [
    PCBuild(
      name: 'Build "Titán Gamer"',
      createdDate: '15/07/2024',
      cpu: 'Intel Core i9-13900K',
      gpu: 'NVIDIA GeForce RTX 4090',
      ram: '32GB DDR5 6000MHz',
    ),
    PCBuild(
      name: 'Workstation "Creativa"',
      createdDate: '02/06/2024',
      cpu: 'AMD Ryzen 9 7950X',
      gpu: 'NVIDIA RTX 3060 Ti',
      ram: '64GB DDR5 5200MHz',
    ),
    PCBuild(
      name: 'Build "Presupuesto Consciente"',
      createdDate: '21/05/2024',
      cpu: 'AMD Ryzen 5 5600G',
      gpu: 'Gráficos Integrados',
      ram: '16GB DDR4 3200MHz',
    ),
  ];

  // TODO: Reemplazar esto con un FutureBuilder cuando tengamos el endpoint

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

    // No usamos Scaffold, solo el contenido
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 24,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y botón
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Builds',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navegar a la página de creación de build
                    },
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    label: const Text(
                      'Crear Nueva Build',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC7384D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Lista de builds
              ...builds.map((build) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: BuildCard(pcBuild: build),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

// TARJETA DE BUILD (Copiada de tu código)
class BuildCard extends StatelessWidget {
  final PCBuild pcBuild;
  const BuildCard({super.key, required this.pcBuild});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: const EdgeInsets.all(24.0),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContent(),
                    const SizedBox(height: 16),
                    _buildActions(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildContent()),
                    const SizedBox(width: 16),
                    _buildActions(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pcBuild.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Creada el: ${pcBuild.createdDate}',
          style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _buildSpec(Icons.memory, 'CPU:', pcBuild.cpu),
            _buildSpec(Icons.developer_board, 'GPU:', pcBuild.gpu),
            _buildSpec(Icons.dns, 'RAM:', pcBuild.ram),
          ],
        ),
      ],
    );
  }

  Widget _buildSpec(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFC7384D), size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            // Ver detalles
          },
          icon: const Icon(Icons.visibility, color: Color(0xFFE0E0E0)),
          tooltip: 'Ver detalles',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            // Editar build
          },
          icon: const Icon(Icons.edit, color: Color(0xFFE0E0E0)),
          tooltip: 'Editar build',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            // Eliminar build
          },
          icon: const Icon(Icons.delete, color: Color(0xFFE0E0E0)),
          tooltip: 'Eliminar build',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        ),
      ],
    );
  }
}
