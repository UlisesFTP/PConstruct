// lib/models/build_comment.dart
import 'package:my_app/models/user_info.dart';

class BuildComment {
  final String id; // Es un UUID String
  final String content;
  final DateTime createdAt;
  final UserInfo user; // Objeto anidado

  BuildComment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.user,
  });

  factory BuildComment.fromJson(Map<String, dynamic> json) {
    // El backend schema 'BuildCommentRead' es plano (user_id, user_name).
    // Construimos el objeto UserInfo manualmente.
    return BuildComment(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: UserInfo(
        userId: json['user_id'] as String,
        userUsername: json['user_name'] as String?,
      ),
    );
  }
}
