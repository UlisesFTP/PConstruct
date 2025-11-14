import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/posts.dart';
import 'package:my_app/core/widgets/comments_modal.dart'; // Importar modal de comentarios
import 'package:my_app/core/widgets/edit_post_modal.dart'; // Importar nuevo modal de edición
import 'package:my_app/providers/auth_provider.dart';

// --- (Importaciones de reproductores de video) ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart'
    as iframe_player;
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    as mobile_player;

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    setState(() {
      // --- LÓGICA CORREGIDA ---
      // Llamamos al nuevo endpoint de ApiClient
      _postsFuture = apiClient.getMyPosts();
      // --- FIN DE LA CORRECCIÓN ---
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Fondo transparente
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C5A0)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar tus posts: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No has creado ninguna publicación.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final posts = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshPosts(),
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                // --- LÓGICA CORREGIDA ---
                // Pasamos el post real al card y
                // un callback para refrescar la lista
                return _MyPostCard(
                  post: posts[index],
                  onPostDeleted: _refreshPosts,
                  onPostUpdated: _refreshPosts,
                );
                // --- FIN DE LA CORRECCIÓN ---
              },
            ),
          );
        },
      ),
    );
  }
}

// --- WIDGET DEL POST CARD TOTALMENTE ACTUALIZADO ---
class _MyPostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onPostDeleted;
  final VoidCallback onPostUpdated;

  const _MyPostCard({
    required this.post,
    required this.onPostDeleted,
    required this.onPostUpdated,
  });

  @override
  State<_MyPostCard> createState() => _MyPostCardState();
}

class _MyPostCardState extends State<_MyPostCard> {
  mobile_player.YoutubePlayerController? _mobileYoutubeController;
  iframe_player.YoutubePlayerController? _iFrameYoutubeController;

  @override
  void initState() {
    super.initState();
    _initializePlayer(widget.post.content);
  }

  @override
  void didUpdateWidget(covariant _MyPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.content != oldWidget.post.content) {
      _initializePlayer(widget.post.content);
    }
  }

  void _initializePlayer(String content) {
    final videoId = _extractVideoId(content);
    if (videoId != null) {
      if (kIsWeb) {
        _iFrameYoutubeController = iframe_player.YoutubePlayerController(
          params: const iframe_player.YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            strictRelatedVideos: true,
          ),
        )..loadVideoById(videoId: videoId);
      } else {
        _mobileYoutubeController = mobile_player.YoutubePlayerController(
          initialVideoId: videoId,
          flags: const mobile_player.YoutubePlayerFlags(autoPlay: false),
        );
      }
    } else {
      _mobileYoutubeController?.dispose();
      _iFrameYoutubeController?.close();
      _mobileYoutubeController = null;
      _iFrameYoutubeController = null;
    }
  }

  String? _extractVideoId(String content) {
    if (content.isEmpty) return null;
    try {
      final regExp = RegExp(
        r".*(?:youtu.be/|v/|u/\w/|embed/|watch\?v=)([^#&?]*).*",
        caseSensitive: false,
      );
      final match = regExp.firstMatch(content);
      return (match != null && match.group(1)!.length == 11)
          ? match.group(1)
          : null;
    } catch (e) {
      return null;
    }
  }

  Widget _buildMedia(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.error, color: Colors.red));
        },
      ),
    );
  }

  // --- NUEVA FUNCIÓN: Mostrar modal de edición ---
  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1C),
      builder: (modalContext) {
        return EditPostModal(
          post: widget.post,
          onPostUpdated: () {
            // Llama al callback que refresca la lista
            widget.onPostUpdated();
          },
        );
      },
    );
  }

  // --- NUEVA FUNCIÓN: Mostrar diálogo de eliminación ---
  void _showDeleteDialog(BuildContext context) {
    final apiClient = Provider.of<ApiClient>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Publicación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este post? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await apiClient.deletePost(widget.post.id);
                Navigator.of(dialogContext).pop(); // Cierra el diálogo
                widget.onPostDeleted(); // Refresca la lista
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post eliminado con éxito')),
                );
              } catch (e) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar el post: $e')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mobileYoutubeController?.dispose();
    _iFrameYoutubeController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user; // Obtenemos el usuario logueado

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ClipRRect(
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
                          // Usamos el avatar del usuario logueado
                          backgroundImage: (user?.avatarUrl != null)
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: (user?.avatarUrl == null)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // Usamos el username del usuario logueado
                              user?.username ?? 'Mi Usuario',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(), // Ocupa espacio
                        // --- NUEVO: Botón de Editar ---
                        IconButton(
                          onPressed: () => _showEditModal(context),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFFA0A0A0),
                            size: 20,
                          ),
                        ),
                        // --- NUEVO: Botón de Eliminar ---
                        IconButton(
                          onPressed: () => _showDeleteDialog(context),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFA0A0A0),
                            size: 20,
                          ),
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
                    // ... (Manejo de contenido de texto)
                    if (_mobileYoutubeController == null &&
                        _iFrameYoutubeController == null)
                      Text(
                        widget.post.content,
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    // ... (Manejo de imagen)
                    if (widget.post.imageUrl != null &&
                        widget.post.imageUrl!.isNotEmpty &&
                        _mobileYoutubeController == null &&
                        _iFrameYoutubeController == null) ...[
                      const SizedBox(height: 16),
                      _buildMedia(widget.post.imageUrl!),
                    ],
                    // ... (Manejo de video)
                    if (_mobileYoutubeController != null && !kIsWeb)
                      mobile_player.YoutubePlayer(
                        controller: _mobileYoutubeController!,
                      ),
                    if (_iFrameYoutubeController != null && kIsWeb)
                      iframe_player.YoutubePlayer(
                        controller: _iFrameYoutubeController!,
                      ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2A2A2A), height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // --- LÓGICA DE LIKES (SOLO VISTA) ---
                        Row(
                          children: [
                            const Icon(
                              Icons.whatshot, // Icono estático
                              color: Color(0xFFA0A0A0),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.post.likesCount
                                  .toString(), // Contador real
                              style: const TextStyle(
                                color: Color(0xFFA0A0A0),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),

                        // --- LÓGICA DE COMENTARIOS (SOLO VISTA) ---
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: const Color(0xFF1A1A1C),
                              builder: (modalContext) {
                                return CommentsModal(
                                  postId: widget.post.id,
                                  // ¡Importante! Ocultamos la caja de texto
                                  canComment: false,
                                );
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
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Color(0xFFA0A0A0),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.post.commentsCount
                                      .toString(), // Contador real
                                  style: const TextStyle(
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
          ),
        ),
      ),
    );
  }
}
