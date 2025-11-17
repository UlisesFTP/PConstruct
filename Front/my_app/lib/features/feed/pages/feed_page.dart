import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/posts.dart';
import 'package:my_app/core/widgets/create_post_modal.dart';
import 'package:my_app/core/widgets/comments_modal.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart'
    as iframe_player;
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    as mobile_player;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:visibility_detector/visibility_detector.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late Future<List<Post>> _postsFuture;
  final Map<int, GlobalKey> _postKeys = {};
  final ScrollController _scrollController = ScrollController();
  WebSocketChannel? _channel;

  final String _webSocketUrl = 'ws://localhost:8000/posts/ws/feed';
  DateTime? _lastLoadTime;
  bool _showNewPostsButton = false;

  @override
  void initState() {
    super.initState();
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _postsFuture = apiClient.getPosts();
    _loadPosts();
    _connectWebSocket();
  }

  void _loadPosts() {
    print("FeedPage: Cargando posts vía HTTP...");
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    setState(() {
      _postsFuture = apiClient.getPosts();
      _lastLoadTime = DateTime.now();
      _showNewPostsButton = false;
    });
  }

  void _checkRefreshTimer() {
    if (_lastLoadTime == null) return;

    final now = DateTime.now();
    final difference = now.difference(_lastLoadTime!);

    if (difference.inMinutes >= 9) {
      print("FeedPage: Datos rancios (>= 9 min) detectados, recargando...");
      _loadPosts();
    }
  }

  void _connectWebSocket() {
    try {
      print("FeedPage: Conectando a WebSocket en $_webSocketUrl");
      _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));

      _channel!.stream.listen(
        (message) {
          print('WebSocket message received: $message');
          final data = jsonDecode(message);
          if (data['event'] == 'new_post') {
            setState(() {
              _showNewPostsButton = true;
            });
          }

          if (data['event'] == 'post_update' && data['action'] == 'edit') {
            _loadPosts();
          }

          if (data['event'] == 'post_delete') {
            _loadPosts();
          }
        },
        onDone: () {
          print('WebSocket channel cerrado (onDone)');
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
      );
    } catch (e) {
      print("Error al conectar al WebSocket: $e");
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToPostById(int postId) async {
    final postKey = _postKeys[postId];
    if (postKey != null && postKey.currentContext != null) {
      print("✅ FeedPage: Scroll requested for post $postId");
      await Future.delayed(const Duration(milliseconds: 50));
      Scrollable.ensureVisible(
        postKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    } else {
      print("❌ FeedPage: No key/context for post $postId");
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('feed_page_visibility'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 1.0) {
          print("FeedPage: Página visible. Comprobando temporizador...");
          _checkRefreshTimer();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _buildFloatingActionButton(),
        body: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }
            if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            }
            if (snapshot.hasData) {
              final posts = snapshot.data!;
              _postKeys.clear();
              for (var post in posts) {
                _postKeys[post.id] = GlobalKey();
              }

              return _buildPostsList(posts);
            }
            return _buildLoadingIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF1A1A1C),
          builder: (modalContext) => CreatePostModal(
            onPostCreated: () {
              print("Post creado. El feed se actualizará.");
            },
          ),
        );
      },
      backgroundColor: const Color.fromARGB(255, 197, 0, 66),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color.fromARGB(255, 197, 0, 69).withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.whatshot,
                    color: const Color.fromARGB(255, 197, 0, 69),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando contenido...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.withOpacity(0.7),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar los posts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 197, 0, 69),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(List<Post> posts) {
    return Stack(
      children: [
        RefreshIndicator(
          backgroundColor: const Color(0xFF1A1A1C),
          color: const Color.fromARGB(255, 197, 0, 69),
          onRefresh: () async {
            _loadPosts();
          },
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 8.0,
                    ),
                    child: PostCard(key: _postKeys[post.id], post: post),
                  ),
                ),
              );
            },
          ),
        ),
        if (_showNewPostsButton) _buildNewPostsButton(),
      ],
    );
  }

  Widget _buildNewPostsButton() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 197, 0, 66),
                    Color.fromARGB(255, 155, 0, 52),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  _loadPosts();
                  _scrollController.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.autorenew, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Nuevos Posts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int localLikesCount;
  late bool isLiked;
  bool isLoadingLike = false;

  @override
  void initState() {
    super.initState();
    localLikesCount = widget.post.likesCount;
    isLiked = widget.post.isLikedByUser;
  }

  void _handleLike() async {
    if (isLoadingLike) return;

    setState(() {
      isLoadingLike = true;
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

      if (!isLiked) {
        await apiClient.unlikePost(widget.post.id);
      } else {
        await apiClient.likePost(widget.post.id);
      }

      if (mounted) {
        setState(() {
          isLoadingLike = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isLiked) {
            localLikesCount--;
            isLiked = false;
          } else {
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMedia(String url) {
    final String? videoId = mobile_player.YoutubePlayer.convertUrlToId(url);

    if (videoId != null) {
      if (kIsWeb) {
        final _controller = iframe_player.YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
          params: const iframe_player.YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
          ),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: iframe_player.YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          ),
        );
      } else {
        final _controller = mobile_player.YoutubePlayerController(
          initialVideoId: videoId,
          flags: const mobile_player.YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: mobile_player.YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            aspectRatio: 16 / 9,
          ),
        );
      }
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  color: const Color.fromARGB(255, 197, 0, 69),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.grey.shade500,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No se pudo cargar la imagen',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
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
    final timeAgoString = timeago.format(widget.post.createdAt, locale: 'es');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Card(
          elevation: 8,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromRGBO(28, 28, 28, 0.8),
                      const Color.fromRGBO(28, 28, 28, 0.6),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con avatar e información del usuario
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(255, 197, 0, 69),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: widget.post.authorAvatarUrl != null
                                ? Image.network(
                                    widget.post.authorAvatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade800,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.grey.shade400,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey.shade800,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey.shade400,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post.authorUsername ?? 'Usuario',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeAgoString,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Título
                    Text(
                      widget.post.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Contenido
                    Text(
                      widget.post.content,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.6,
                        fontSize: 16,
                      ),
                    ),

                    // Media (imagen o video)
                    if (widget.post.imageUrl != null &&
                        widget.post.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildMedia(widget.post.imageUrl!),
                    ],

                    const SizedBox(height: 20),
                    Divider(
                      color: Colors.white.withOpacity(0.1),
                      height: 1,
                      thickness: 1,
                    ),
                    const SizedBox(height: 16),

                    // Botones de interacción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_buildLikeButton(), _buildCommentsButton()],
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

  Widget _buildLikeButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isLiked
            ? const Color.fromARGB(255, 197, 0, 69).withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLiked
              ? const Color.fromARGB(255, 197, 0, 69)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleLike,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isLiked ? Icons.whatshot : Icons.whatshot_outlined,
                    color: isLiked
                        ? const Color(0xFFC7384D)
                        : const Color(0xFFA0A0A0),
                    size: 22,
                    key: ValueKey<bool>(isLiked),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    localLikesCount.toString(),
                    style: TextStyle(
                      color: isLiked
                          ? const Color(0xFFC7384D)
                          : const Color(0xFFA0A0A0),
                      fontSize: 15,
                      fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                    ),
                    key: ValueKey<int>(localLikesCount),
                  ),
                ),
                if (isLoadingLike) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLiked
                            ? const Color(0xFFC7384D)
                            : const Color(0xFFA0A0A0),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF1A1A1C),
            builder: (modalContext) {
              return CommentsModal(postId: widget.post.id);
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Comentarios",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
