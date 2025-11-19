import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/post_card.dart';
import 'dart:ui';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/posts.dart';
import 'package:my_app/core/widgets/create_post_modal.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:math';

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
  int _currentSeed = 0;

  @override
  void initState() {
    super.initState();
    _currentSeed = Random().nextInt(100000);
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _postsFuture = apiClient.getPosts(seed: _currentSeed, sortBy: 'popular');
    _loadPosts();
    _connectWebSocket();
  }

  void _loadPosts() {
    print("FeedPage: Cargando posts vía HTTP...");
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    setState(() {
      // ¡IMPORTANTE!
      // Generamos NUEVA semilla al refrescar. Esto cambia el orden en el backend.
      _currentSeed = Random().nextInt(100000);

      _postsFuture = apiClient.getPosts(
        seed: _currentSeed,
        sortBy: 'popular', // Asegúrate de pedir 'popular' para ver el algoritmo
      );

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
