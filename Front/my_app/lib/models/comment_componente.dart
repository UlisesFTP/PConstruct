// lib/models/comment_componente.dart
import 'user_info.dart';

class CommentComponente {
  final int id;
  final String content;
  final DateTime createdAt;
  final UserInfo user; // Objeto de usuario anidado

  CommentComponente({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.user,
  });

  factory CommentComponente.fromJson(Map<String, dynamic> json) {
    return CommentComponente(
      id: json['id'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
