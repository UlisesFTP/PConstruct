import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'package:my_app/models/search_results.dart';
import 'package:my_app/models/posts.dart'; // Needed for Function(Post post)
import 'search_results_overlay.dart'; // Import the overlay

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
