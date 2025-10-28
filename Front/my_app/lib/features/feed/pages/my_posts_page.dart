import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/posts.dart';
import 'package:my_app/core/widgets/create_post_modal.dart';
import 'package:my_app/providers/auth_provider.dart';

// --- INICIO DE CORRECCIÓN: Importar reproductores y kIsWeb ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart'
    as iframe_player;
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    as mobile_player;
// --- FIN DE CORRECCIÓN ---

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
      _postsFuture = apiClient.getPosts();
    });
  }

  void _openCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1C),
      builder: (modalContext) => CreatePostModal(onPostCreated: _refreshPosts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Stack(
      children: [
        // ... (Gradientes se mantienen igual) ...
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  const Color(0xFFC7384D).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomRight,
                radius: 1.2,
                colors: [
                  const Color(0xFFC7384D).withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Contenido principal
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 24,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... (Header con título y botón se mantiene igual) ...
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mis Publicaciones',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _openCreatePostModal,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Crear Publicación',
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

                  // Lista de publicaciones
                  FutureBuilder<List<Post>>(
                    future: _postsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Aún no tienes publicaciones.'),
                        );
                      }

                      final myPosts = snapshot.data!;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myPosts.length,
                        itemBuilder: (context, index) {
                          final post = myPosts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: MyPostCard(
                              post: post,
                              currentUserAvatar: authProvider
                                  .user
                                  ?.email, // TODO: Cambiar por avatarUrl
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// TARJETA DE PUBLICACIÓN
class MyPostCard extends StatefulWidget {
  final Post post;
  final String? currentUserAvatar;

  const MyPostCard({super.key, required this.post, this.currentUserAvatar});

  @override
  State<MyPostCard> createState() => _MyPostCardState();
}

class _MyPostCardState extends State<MyPostCard> {
  // --- INICIO DE CORRECCIÓN: Copiar _buildMedia de FeedPage ---
  Widget _buildMedia(String url) {
    // Usamos el conversor de 'youtube_player_flutter'
    final String? videoId = mobile_player.YoutubePlayer.convertUrlToId(url);

    if (videoId != null) {
      // Si es un video, decidimos qué reproductor usar
      if (kIsWeb) {
        // --- CÓDIGO PARA WEB ---
        final _controller = iframe_player.YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
          params: const iframe_player.YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
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
      // Si no es un video, es una imagen
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No se pudo cargar el medio', // Mensaje genérico
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          },
        ),
      );
    }
  }
  // --- FIN DE CORRECCIÓN ---

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (Header con avatar y menú se mantiene igual) ...
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  widget.post.authorAvatarUrl != null
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
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "hace 2 horas", // TODO: Calcular timeago
                                  style: const TextStyle(
                                    color: Color(0xFFA0A0A0),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Color(0xFFA0A0A0),
                          ),
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Editar',
                                    style: TextStyle(color: Color(0xFFE0E0E0)),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                            } else if (value == 'delete') {}
                          },
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
                  ],
                ),
              ),

              // --- INICIO DE CORRECCIÓN: Usar _buildMedia ---
              if (widget.post.imageUrl != null &&
                  widget.post.imageUrl!.isNotEmpty)
                Padding(
                  // Añadimos padding si el medio no es una imagen (para que no toque los bordes)
                  padding:
                      (mobile_player.YoutubePlayer.convertUrlToId(
                            widget.post.imageUrl!,
                          ) !=
                          null)
                      ? const EdgeInsets.symmetric(horizontal: 24)
                      : EdgeInsets.zero,
                  child: _buildMedia(widget.post.imageUrl!),
                ),
              // --- FIN DE CORRECCIÓN ---

              // ... (Acciones de like/comentario se mantienen igual) ...
              Container(
                padding: const EdgeInsets.all(24),
                decoration:
                    widget.post.imageUrl != null &&
                        widget.post.imageUrl!.isNotEmpty
                    ? const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                        ),
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Row(
                            children: [
                              Icon(
                                widget.post.isLikedByUser
                                    ? Icons.whatshot
                                    : Icons.whatshot_outlined,
                                color: widget.post.isLikedByUser
                                    ? const Color(0xFFC7384D)
                                    : const Color(0xFFA0A0A0),
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.post.likesCount.toString(),
                                style: TextStyle(
                                  color: widget.post.isLikedByUser
                                      ? Colors.white
                                      : const Color(0xFFA0A0A0),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        InkWell(
                          onTap: () {},
                          child: Row(
                            children: [
                              const Icon(
                                Icons.comment,
                                color: Color(0xFFA0A0A0),
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "0", // TODO: Añadir contador de comentarios
                                style: const TextStyle(
                                  color: Color(0xFFA0A0A0),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        false // TODO: Usar variable isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: false
                            ? const Color(0xFFC7384D)
                            : const Color(0xFFA0A0A0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
