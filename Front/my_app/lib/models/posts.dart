// Puedes crear un nuevo archivo, ej: 'models/post.dart'

class Post {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likesCount;
  final String? authorUsername; // Datos enriquecidos
  final String? authorAvatarUrl; // Datos enriquecidos
  final bool isLikedByUser;
  final int commentsCount;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.likesCount,
    this.authorUsername,
    this.authorAvatarUrl,
    required this.isLikedByUser,
    required this.commentsCount,
  });

  // Factory constructor para crear un Post desde un mapa JSON
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      authorUsername: json['author_username'],
      authorAvatarUrl: json['author_avatar_url'],
      isLikedByUser: json['is_liked_by_user'] ?? false,
      commentsCount: json['comments_count'] ?? 0,
    );
  }
}
