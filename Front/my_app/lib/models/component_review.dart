// lib/models/component_review.dart
// (Reemplaza el contenido de review.dart o crea un archivo nuevo)

import 'package:my_app/models/user_info.dart';
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
    var commentsList = (json['comments'] as List<dynamic>)
        .map(
          (commentJson) =>
              CommentComponente.fromJson(commentJson as Map<String, dynamic>),
        )
        .toList();

    return ComponentReview(
      id: json['id'] as int,
      rating: json['rating'] as int,
      title: json['title'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
      comments: commentsList,
    );
  }
}
