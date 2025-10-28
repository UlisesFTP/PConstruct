import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Para AuthProvider y ApiClient
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/core/api/api_client.dart'; // Necesario para AppTopBar
import 'package:my_app/models/posts.dart'; // Necesario para AppTopBar
import 'package:my_app/models/search_results.dart'; // Necesario para AppTopBar

// Importa los widgets que extrajiste
import 'app_sidebar.dart';
import 'app_drawer.dart';
import 'app_top_bar.dart';
// Importa los modales si son necesarios globalmente
// import 'package:my_app/core/widgets/create_post_modal.dart';
// import 'package:my_app/core/widgets/comments_modal.dart';

class MainLayout extends StatefulWidget {
  final Widget child; // El contenido de la página actual (Feed, Profile, etc.)

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarVisible = false; // Estado del sidebar movido aquí

  // Estado y lógica de búsqueda (movidos aquí desde FeedPage)
  final OverlayPortalController _tooltipController = OverlayPortalController();
  SearchResults? _searchResults;
  bool _isSearching = false;
  Timer? _debounce;
  final ScrollController _internalScrollController =
      ScrollController(); // Para el scroll de búsqueda

  @override
  void dispose() {
    _debounce?.cancel();
    _internalScrollController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  // --- LÓGICA DE BÚSQUEDA (COPIADA DE FeedPage) ---
  Future<void> _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        /* ... lógica para ocultar ... */
        return;
      }
      if (mounted) setState(() => _isSearching = true);
      _tooltipController.show();
      try {
        final apiClient = Provider.of<ApiClient>(context, listen: false);
        final results = await apiClient.search(query);
        if (mounted) setState(() => _searchResults = results);
      } catch (e) {
        /* ... manejo de error ... */
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  // --- LÓGICA DE SCROLL (COPIADA DE FeedPage) ---
  // Necesitamos una forma de acceder a las postKeys que ahora estarán en FeedPageContent
  // Esto es más complejo. Por ahora, dejaremos el scroll pendiente
  // y nos enfocaremos en la estructura del layout.
  void _scrollToPost(Post selectedPost) async {
    print(
      "Scroll To Post llamado en MainLayout para post ${selectedPost.id} - ¡FUNCIONALIDAD PENDIENTE!",
    );
    // TODO: Implementar comunicación entre MainLayout y la página hija (FeedPageContent)
    // para obtener la GlobalKey y realizar el scroll.
  }
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.username ?? 'Invitado';
    const double sidebarWidth = 256.0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop ? const AppDrawer() : null, // Usa el Drawer extraído
      body: Stack(
        children: [
          // --- CONTENIDO PRINCIPAL (Animado) ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: isDesktop && _isSidebarVisible ? sidebarWidth : 0,
            top: 0,
            bottom: 0,
            right: 0,
            child: Column(
              children: [
                // --- AppTopBar ahora es parte del Layout ---
                AppTopBar(
                  isDesktop: isDesktop,
                  userName: userName,
                  onProfilePressed: () {
                    if (isDesktop) {
                      _toggleSidebar();
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                  },
                  // Pasamos la lógica de búsqueda
                  onSearchChanged: _onSearchChanged,
                  searchOverlayController: _tooltipController,
                  searchResults: _searchResults,
                  isSearching: _isSearching,
                  onPostSelected: _scrollToPost,
                  // Conecta con la función (pendiente)
                ),
                // --- Aquí se inserta el contenido de la página actual ---
                Expanded(
                  child: widget.child, // <-- USA EL PARÁMETRO child
                ),
              ],
            ),
          ),

          // --- SIDEBAR (Animado) ---
          if (isDesktop)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _isSidebarVisible ? 0 : -sidebarWidth,
              top: 0,
              bottom: 0,
              width: sidebarWidth,
              child: const AppSidebar(), // Usa el Sidebar extraído
            ),
        ],
      ),
      // El FloatingActionButton podría necesitar ser condicional o parte de la página hija
      // floatingActionButton: FloatingActionButton.extended( ... ), // <-- Considera moverlo
    );
  }
}
