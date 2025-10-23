import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async'; // Para el Timer de debouncing
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/posts.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/models/search_results.dart';
import 'package:my_app/core/widgets/create_post_modal.dart';
import 'package:my_app/core/widgets/comments_modal.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart'
    as iframe_player;
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    as mobile_player;

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<Post>> _postsFuture;
  final Map<int, GlobalKey> _postKeys = {};

  bool _isSidebarVisible = false;
  final ScrollController _scrollController = ScrollController();

  // Estado para la búsqueda (se mantiene igual)
  final OverlayPortalController _tooltipController = OverlayPortalController();
  SearchResults? _searchResults;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // ✅ OBTENEMOS EL API CLIENT DEL PROVIDER
    // Usamos 'listen: false' porque estamos en initState, que solo se ejecuta una vez.
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _postsFuture = apiClient.getPosts();
    print("FeedPage initState: Cargando posts...");
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  void _scrollToPost(Post selectedPost) async {
    print("4. Función _scrollToPost ejecutada en FeedPage");
    // Busca la GlobalKey asociada al ID del post seleccionado
    final postKey = _postKeys[selectedPost.id];

    // Si encontramos la key y tiene un contexto asociado (está renderizada)
    if (postKey != null && postKey.currentContext != null) {
      print("✅ Encontrado post ${selectedPost.id}, haciendo scroll...");
      // Espera un breve momento para asegurar que el layout esté listo
      await Future.delayed(const Duration(milliseconds: 50));

      // Pide a Flutter que asegure que este widget sea visible
      Scrollable.ensureVisible(
        postKey.currentContext!,
        duration: const Duration(milliseconds: 500), // Duración de la animación
        curve: Curves.easeInOut, // Curva de animación
        alignment:
            0.5, // Alinea cerca de la parte superior (0.0 = arriba, 1.0 = abajo)
      );
    } else {
      print(
        "Error: No se encontró la key o el contexto para el post ${selectedPost.id}",
      );
      // Podría pasar si el post buscado no está actualmente cargado en el feed
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        if (mounted) {
          setState(() {
            _searchResults = null;
            _isSearching = false;
          });
          _tooltipController.hide();
        }
        return;
      }

      if (mounted) setState(() => _isSearching = true);
      _tooltipController.show();

      try {
        // ✅ OBTENEMOS EL API CLIENT DEL PROVIDER
        final apiClient = Provider.of<ApiClient>(context, listen: false);
        final results = await apiClient.search(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
          });
        }
      } catch (e) {
        print("Error en la búsqueda: $e");
        if (mounted) {
          setState(() {
            _searchResults = null;
          });
        }
        _tooltipController.hide();
      } finally {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  // ✅ CORREGIDO: Función para recargar los posts
  Future<void> _refreshPosts() async {
    // Obtenemos la instancia más fresca del apiClient para recargar
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    setState(() {
      _postsFuture = apiClient.getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;
    // Aquí puedes usar 'watch' si quieres que la UI reaccione a cambios del authProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.username ?? 'Invitado';

    const double sidebarWidth = 256.0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop ? const AppDrawer() : null,
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(
              milliseconds: 300,
            ), // Duración de la animación
            curve: Curves.easeInOut, // Tipo de animación
            left: isDesktop && _isSidebarVisible
                ? sidebarWidth
                : 0, // Posición izquierda
            top: 0,
            bottom: 0,
            right: 0,
            child: Column(
              children: [
                AppTopBar(
                  isDesktop: isDesktop,
                  userName: userName,
                  onProfilePressed: () {
                    if (isDesktop) {
                      // <-- If IS desktop
                      _toggleSidebar(); // <-- Toggle the sidebar
                    } else {
                      // <-- If NOT desktop (i.e., mobile)
                      _scaffoldKey.currentState
                          ?.openDrawer(); // <-- Open the drawer
                    }
                  },
                  onSearchChanged: _onSearchChanged,
                  searchOverlayController: _tooltipController,
                  searchResults: _searchResults,
                  isSearching: _isSearching,
                  onPostSelected: _scrollToPost,
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshPosts, // Usamos la función corregida
                    color: Theme.of(context).primaryColor,
                    backgroundColor: const Color(0xFF1A1A1C),
                    child: FutureBuilder<List<Post>>(
                      future: _postsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Error al cargar las publicaciones: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasData) {
                          final posts = snapshot.data!;

                          // --- ASEGÚRATE DE LIMPIAR Y RELLENAR LAS KEYS ---
                          _postKeys.clear();
                          for (var post in posts) {
                            _postKeys[post.id] = GlobalKey();
                          }
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'Aún no hay publicaciones. ¡Sé el primero!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        final posts = snapshot.data!;
                        return ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32 : 24,
                            vertical: isDesktop ? 32 : 24,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 672,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 32.0),
                                  // --- ASIGNA LA KEY AL PostCard ---
                                  child: PostCard(
                                    key:
                                        _postKeys[post
                                            .id], // <-- ASIGNA LA KEY AQUÍ
                                    post: post,
                                  ),
                                  // --------------------------------
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              // Si está visible, 'left' es 0. Si no, 'left' es -sidebarWidth (fuera de pantalla)
              left: _isSidebarVisible ? 0 : -sidebarWidth,
              top: 0,
              bottom: 0,
              width: sidebarWidth, // Ancho fijo
              child: const AppSidebar(), // Tu widget de Sidebar
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        // ✅ CORRECCIÓN FINAL: Llamada al modal
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF1A1A1C),
            // El 'context' que se pasa aquí SÍ tiene acceso a los providers
            // globales que definimos en main.dart (ApiClient y AuthProvider).
            builder: (modalContext) {
              // El CreatePostModal ahora leerá el ApiClient por sí mismo
              // usando Provider.of<ApiClient>(modalContext).
              return CreatePostModal(onPostCreated: _refreshPosts);
            },
          );
        },
        backgroundColor: const Color(0xFFC7384D),
        elevation: 8,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Crear Publicación",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// --- ACTUALIZACIÓN DE COMPONENTES ---

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
                icon: const Icon(Icons.account_circle, size: 30),
                color: const Color(0xFFE0E0E0),
                onPressed: onProfilePressed,
              ),
              if (isDesktop) ...[
                const SizedBox(width: 40),
                const TopNavLinks(),
              ],
              const SizedBox(width: 24),
              Expanded(
                child: CustomSearchBar(
                  onPostSelected: (Post post) {
                    // <-- Cambia a función anónima
                    print(
                      "3. Callback recibido en AppTopBar",
                    ); // <-- AÑADE ESTE PRINT
                    onPostSelected(post); // Llama al callback original
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

class CustomSearchBar extends StatefulWidget {
  final Function(String) onChanged;
  final OverlayPortalController overlayController;
  final SearchResults? results;
  final bool isSearching;
  final Function(Post post) onPostSelected;

  const CustomSearchBar({
    super.key,
    required this.onChanged,
    required this.overlayController,
    this.results,
    required this.isSearching,
    required this.onPostSelected,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: widget.overlayController,
      overlayChildBuilder: (BuildContext context) {
        return Positioned(
          top: 80,
          left: MediaQuery.of(context).size.width * 0.1,
          width: MediaQuery.of(context).size.width * 0.8,
          child: SearchResultsOverlay(
            results: widget.results,
            isLoading: widget.isSearching,
            onPostSelected: (Post post) {
              // <-- Cambia a función anónima
              print(
                "2. Callback recibido en CustomSearchBar",
              ); // <-- AÑADE ESTE PRINT
              widget.onPostSelected(post); // Llama al callback original
            },

            onClose: () {
              widget.overlayController.hide();
              _focusNode.unfocus();
            },
          ),
        );
      },
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            widget.overlayController.hide();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: const BoxConstraints(maxWidth: 512),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isFocused ? const Color(0xFFC7384D) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFFC7384D).withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Buscar publicaciones, usuarios, componentes...",
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

// ... (el resto de los widgets como AppSidebar, AppDrawer, SidebarMenuItem, TopNavLinks, NavLink, PostCard se mantienen igual)
// --- COMPONENTES DE LA INTERFAZ (Widgets Reutilizables) ---

class _SidebarContent extends StatelessWidget {
  const _SidebarContent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.2,
                colors: [
                  const Color(0xFFC7384D).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2.5),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/img/PCLogoBlanco.png',
                      height: 180, // Aumenta este valor según necesites
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SidebarMenuItem(
                      icon: Icons.person_outline,
                      text: 'Usuario',
                      onTap: () {
                        // <-- AÑADE EL onTap
                        Navigator.pop(
                          context,
                        ); // Cierra el drawer si está abierto
                        Navigator.pushNamed(
                          context,
                          '/profile',
                        ); // Navega a la ruta
                      },
                    ),
                    SidebarMenuItem(
                      icon: Icons.build_outlined,
                      text: 'Mis builds',
                    ),
                    SidebarMenuItem(
                      icon: Icons.article_outlined,
                      text: 'Mis publicaciones',
                    ),
                    SidebarMenuItem(
                      icon: Icons.settings_outlined,
                      text: 'Configuración',
                    ),
                  ],
                ),
              ),
              const SidebarMenuItem(icon: Icons.logout, text: 'Cerrar sesión'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 256,
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withOpacity(0.6),
            border: Border(
              right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
          ),
          child: const _SidebarContent(),
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121212).withOpacity(0.8),
            ),
            child: const _SidebarContent(),
          ),
        ),
      ),
    );
  }
}

class SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;
    final inactiveColor = Colors.grey[400];

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Material(
        color: isHovered ? activeColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.onTap,

          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isHovered ? activeColor : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: isHovered ? activeColor : inactiveColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  widget.text,
                  style: TextStyle(
                    color: isHovered ? activeColor : inactiveColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

class TopNavLinks extends StatelessWidget {
  const TopNavLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        NavLink(text: "Feed", isActive: true),
        SizedBox(width: 32),
        NavLink(text: "Componentes"),
        SizedBox(width: 32),
        NavLink(text: "Builds"),
        SizedBox(width: 32),
        NavLink(text: "Benchmarks"),
      ],
    );
  }
}

class NavLink extends StatefulWidget {
  final String text;
  final bool isActive;

  const NavLink({super.key, required this.text, this.isActive = false});

  @override
  State<NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<NavLink> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive || isHovered
        ? const Color(0xFFC7384D)
        : const Color(0xFFA0A0A0);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: InkWell(
        onTap: () {},
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              style: TextStyle(
                color: color,
                fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: widget.isActive || isHovered ? 20 : 0,
              color: const Color(0xFFC7384D),
            ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int localLikesCount;
  late bool isLiked; // Estado local para cambiar el color del icono
  bool isLoadingLike = false; // Para prevenir doble-tap

  @override
  void initState() {
    super.initState();
    localLikesCount = widget.post.likesCount;
    isLiked = widget.post.isLikedByUser;
    // NOTA: Para saber si el usuario YA le ha dado like, necesitaríamos
    // que el backend nos envíe esa info en el 'GET /posts/'.
    // Por ahora, asumimos que no le ha dado like al cargar.
  }

  void _handleLike() async {
    if (isLoadingLike) return; // Prevenir doble tap mientras carga

    setState(() {
      isLoadingLike = true;
      // Actualización optimista de la UI
      if (isLiked) {
        localLikesCount--;
        isLiked = false;
      } else {
        localLikesCount++;
        isLiked = true;
      }
    });

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);

      // Llama a la API correcta según el estado anterior
      if (!isLiked) {
        // Si el estado AHORA es false, significa que ANTES era true
        await apiClient.unlikePost(widget.post.id);
      } else {
        // Si el estado AHORA es true, significa que ANTES era false
        await apiClient.likePost(widget.post.id);
      }

      // Si todo va bien, solo termina la carga
      if (mounted) {
        setState(() {
          isLoadingLike = false;
        });
      }
    } catch (e) {
      // Si la API falla, revertimos la UI al estado anterior
      if (mounted) {
        setState(() {
          if (isLiked) {
            // Si el estado optimista era true, revertimos a false
            localLikesCount--;
            isLiked = false;
          } else {
            // Si el estado optimista era false, revertimos a true
            localLikesCount++;
            isLiked = true;
          }
          isLoadingLike = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al ${isLiked ? 'quitar' : 'añadir'} reacción: $e',
            ),
          ),
        );
      }
    }
  }

  Widget _buildMedia(String url) {
    // Usamos el conversor de 'youtube_player_flutter' que funciona en ambos
    final String? videoId = mobile_player.YoutubePlayer.convertUrlToId(url);

    if (videoId != null) {
      // Si es un video, decidimos qué reproductor usar
      if (kIsWeb) {
        // --- CÓDIGO PARA WEB ---
        final _controller = iframe_player.YoutubePlayerController.fromVideoId(
          videoId: videoId, // <-- Ahora sí está en el lugar correcto
          autoPlay: false, // <-- Y este también
          params: const iframe_player.YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            // 'autoPlay' se movió arriba
          ),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: iframe_player.YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          ),
        );
      } else {
        // --- CÓDIGO PARA ANDROID / iOS ---
        final _controller = mobile_player.YoutubePlayerController(
          initialVideoId: videoId,
          flags: const mobile_player.YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: mobile_player.YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            aspectRatio: 16 / 9,
          ),
        );
      }
    } else {
      // Si no es un video, es una imagen (esta lógica se mantiene)
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // ... (tu errorBuilder se mantiene igual)
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No se pudo cargar la imagen',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcula el tiempo transcurrido de forma legible
    final timeAgoString = timeago.format(widget.post.createdAt, locale: 'es');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(28, 28, 28, 0.7),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.post.authorAvatarUrl != null
                        ? NetworkImage(widget.post.authorAvatarUrl!)
                        : null,
                    child: widget.post.authorAvatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.authorUsername ?? 'Usuario',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgoString,
                        style: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.post.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.post.content,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              if (widget.post.imageUrl != null &&
                  widget.post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildMedia(
                  widget.post.imageUrl!,
                ), // Llama a la nueva función condicional
              ],
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _handleLike, // <-- Llama a la función
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked
                                ? Icons.whatshot
                                : Icons.whatshot_outlined, // Icono dinámico
                            color: isLiked
                                ? const Color(0xFFC7384D)
                                : const Color(0xFFA0A0A0), // Color dinámico
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localLikesCount
                                .toString(), // <-- Usa el contador local
                            style: TextStyle(
                              color: isLiked
                                  ? const Color(0xFFC7384D)
                                  : const Color(0xFFA0A0A0),
                              fontSize: 15,
                              fontWeight: isLiked
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // --- FIN DE LA MODIFICACIÓN ---
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled:
                            true, // Para que el modal respete el teclado
                        backgroundColor: const Color(
                          0xFF1A1A1C,
                        ), // Color del modal
                        builder: (modalContext) {
                          // Pasamos el postId al modal
                          return CommentsModal(postId: widget.post.id);
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Color(0xFFA0A0A0),
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Comentarios",
                            style: TextStyle(
                              color: Color(0xFFA0A0A0),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
