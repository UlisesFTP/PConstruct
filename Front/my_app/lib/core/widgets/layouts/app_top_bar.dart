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
  // Nuevos parámetros para la búsqueda
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
    required this.onSearchChanged,
    required this.searchOverlayController,
    this.searchResults,
    required this.isSearching,
    required this.onPostSelected,
    // Eliminado: required Null Function() onMenuPressed, // Ya no es necesario
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              IconButton(
                // Cambiado de Icons.menu a Icons.account_circle para consistencia
                icon: const Icon(Icons.account_circle, size: 30),
                color: const Color(0xFFE0E0E0),
                onPressed: onProfilePressed, // Usa la función correcta
              ),
              if (isDesktop) ...[
                const SizedBox(width: 40),
                const TopNavLinks(),
              ],
              const SizedBox(width: 24),
              Expanded(
                child: CustomSearchBar(
                  onPostSelected: (Post post) {
                    print("3. Callback recibido en AppTopBar");
                    onPostSelected(post);
                  },
                  onChanged: onSearchChanged,
                  overlayController: searchOverlayController,
                  results: searchResults,
                  isSearching: isSearching,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.notifications, size: 24),
                color: const Color(0xFFA0A0A0),
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
