import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/layouts/top_nav_links.dart';
import 'package:my_app/models/posts.dart';
import 'package:my_app/models/search_results.dart';
import 'package:my_app/core/widgets/search/custom_search_bar.dart';

class AppTopBar extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onProfilePressed;
  final String userName;
  final String? avatarUrl;
  final Function(String) onSearchChanged;
  final Function(Post post) onPostSelected;
  final OverlayPortalController searchOverlayController;
  final SearchResults? searchResults;
  final bool isSearching;

  const AppTopBar({
    super.key,
    required this.isDesktop,
    required this.onProfilePressed,
    required this.userName,
    this.avatarUrl,
    required this.onSearchChanged,
    required this.searchOverlayController,
    this.searchResults,
    required this.isSearching,
    required this.onPostSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final hasProfileImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: const Border(
              bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 12 : 16,
          ),
          child: Row(
            children: [
              // Botón de menú/perfil
              IconButton(
                icon: hasProfileImage
                    ? CircleAvatar(
                        radius: isMobile ? 14 : 16,
                        backgroundImage: NetworkImage(avatarUrl!),
                        backgroundColor: Colors.grey.shade400,
                      )
                    : Icon(Icons.account_circle, size: isMobile ? 26 : 30),
                color: const Color(0xFFE0E0E0),
                onPressed: onProfilePressed,
                tooltip: 'Perfil',
              ),

              // Navegación: Desktop muestra links, Tablet/Mobile muestra iconos
              if (isDesktop) ...[
                const SizedBox(width: 40),
                const TopNavLinks(),
                const SizedBox(width: 24),
              ] else if (isTablet) ...[
                const SizedBox(width: 16),
                const Expanded(child: TopNavIcons(showLabels: false)),
                const SizedBox(width: 16),
              ],

              // Barra de búsqueda (en móvil es más compacta)
              if (isMobile) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: CustomSearchBar(
                    onPostSelected: onPostSelected,
                    onChanged: onSearchChanged,
                    overlayController: searchOverlayController,
                    results: searchResults,
                    isSearching: isSearching,
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: CustomSearchBar(
                      onPostSelected: onPostSelected,
                      onChanged: onSearchChanged,
                      overlayController: searchOverlayController,
                      results: searchResults,
                      isSearching: isSearching,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],

              // Notificaciones y nombre de usuario
              if (!isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 24),
                  color: const Color(0xFFA0A0A0),
                  onPressed: () {},
                  tooltip: 'Notificaciones',
                ),
                if (!isTablet) ...[
                  const SizedBox(width: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ] else ...[
                // En móvil, solo el icono de notificaciones
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined, size: 22),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC7384D),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  color: const Color(0xFFA0A0A0),
                  onPressed: () {},
                  tooltip: 'Notificaciones',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
