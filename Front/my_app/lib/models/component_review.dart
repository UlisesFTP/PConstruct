// lib/models/component_review.dart
import 'user_info.dart';
import 'package:my_app/models/comment_componente.dart';

class ComponentReview {
  final int id;
  final int rating;
  final String? title;
  final String content;
  final DateTime createdAt;
  final UserInfo user;
  final List<CommentComponente> comments;

  ComponentReview({
    required this.id,
    required this.rating,
    this.title,
    required this.content,
    required this.createdAt,
    required this.user,
    required this.comments,
  });

  factory ComponentReview.fromJson(Map<String, dynamic> json) {
    // Parsea la lista de comentarios de forma segura
    var commentsList = <CommentComponente>[];
    if (json['comments'] != null) {
      commentsList = (json['comments'] as List<dynamic>)
          .map(
            (commentJson) =>
                CommentComponente.fromJson(commentJson as Map<String, dynamic>),
          )
          .toList();
    }

    return ComponentReview(
      id: json['id'] as int,
      rating: json['rating'] as int,
      title: json['title'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      // Parsea el usuario de forma segura
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>?),
      comments: commentsList,
    );
  }
}
