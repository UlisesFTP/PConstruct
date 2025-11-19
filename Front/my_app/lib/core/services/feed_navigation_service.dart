// lib/core/services/feed_navigation_service.dart
import 'dart:async';
import 'package:my_app/models/posts.dart';

class FeedNavigationService {
  // Stream broadcast para enviar eventos a quien esté escuchando (FeedPage)
  static final StreamController<Post> _controller =
      StreamController<Post>.broadcast();

  static Stream<Post> get onPostSelected => _controller.stream;

  // Función para emitir el evento
  static void navigateToPost(Post post) {
    _controller.add(post);
  }

  static void dispose() {
    _controller.close();
  }
}
