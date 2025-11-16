import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/posts.dart';
import 'package:my_app/models/search_results.dart';
import 'app_sidebar.dart';
import 'app_drawer.dart';
import 'app_top_bar.dart';
import 'package:my_app/core/widgets/layouts/sidebar_menu_item.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarVisible = false;

  // Estado de búsqueda
  final OverlayPortalController _tooltipController = OverlayPortalController();
  SearchResults? _searchResults;
  bool _isSearching = false;
  Timer? _debounce;
  final ScrollController _internalScrollController = ScrollController();

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
        final apiClient = Provider.of<ApiClient>(context, listen: false);
        final results = await apiClient.search(query);
        if (mounted) setState(() => _searchResults = results);
      } catch (e) {
        if (mounted) {
          setState(() => _searchResults = null);
        }
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _scrollToPost(Post selectedPost) async {
    print("Scroll To Post llamado para post ${selectedPost.id}");
    // TODO: Implementar scroll
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;

    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.username ?? 'Invitado';
    final avatarUrl = authProvider.user?.avatarUrl;
    const double sidebarWidth = 256.0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: !isDesktop ? const AppDrawer() : null,
      body: Stack(
        children: [
          // Contenido principal
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: isDesktop && _isSidebarVisible ? sidebarWidth : 0,
            top: 0,
            bottom: isMobile ? 65 : 0, // Espacio para bottom nav en móvil
            right: 0,
            child: Column(
              children: [
                AppTopBar(
                  isDesktop: isDesktop,
                  userName: userName,
                  avatarUrl: avatarUrl,
                  onProfilePressed: () {
                    if (isDesktop) {
                      _toggleSidebar();
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                  },
                  onSearchChanged: _onSearchChanged,
                  searchOverlayController: _tooltipController,
                  searchResults: _searchResults,
                  isSearching: _isSearching,
                  onPostSelected: _scrollToPost,
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),

          // Sidebar (solo desktop)
          if (isDesktop)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _isSidebarVisible ? 0 : -sidebarWidth,
              top: 0,
              bottom: 0,
              width: sidebarWidth,
              child: const AppSidebar(),
            ),

          // Bottom Navigation Bar (solo móvil)
          if (isMobile)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const MobileBottomNav(),
            ),
        ],
      ),
    );
  }
}
