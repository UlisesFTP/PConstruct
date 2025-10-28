import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'package:my_app/models/search_results.dart';
import 'package:my_app/models/posts.dart'; // Needed for Function(Post post)

class SearchResultsOverlay extends StatelessWidget {
  final SearchResults? results;
  final bool isLoading;
  final VoidCallback onClose;
  final Function(Post post) onPostSelected;

  const SearchResultsOverlay({
    super.key,
    this.results,
    required this.isLoading,
    required this.onClose,
    required this.onPostSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(30, 30, 30, 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (results == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Ingresa al menos 3 caracteres para buscar.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (results!.posts.isEmpty && results!.users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No se encontraron resultados.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resultados de búsqueda',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Expanded(
          child: Material(
            // <-- Añade este Material
            type: MaterialType.transparency,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                if (results!.posts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Publicaciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ...results!.posts.map(
                    (post) => ListTile(
                      title: Text(
                        post.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        post.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      leading: const Icon(Icons.article, color: Colors.grey),
                      onTap: () {
                        print("1. Click en ListTile (SearchResultsOverlay)");
                        onClose();
                        onPostSelected(post);
                        // Aquí puedes navegar a la publicación
                      },
                    ),
                  ),
                  const Divider(color: Colors.grey),
                ],
                if (results!.users.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Usuarios',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ...results!.users.map(
                    (user) => ListTile(
                      title: Text(
                        user.username,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        user.name ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      leading: const Icon(Icons.person, color: Colors.grey),
                      onTap: () {
                        onClose();

                        // Aquí puedes navegar al perfil del usuario
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
