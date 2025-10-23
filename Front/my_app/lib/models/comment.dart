class Comment {
  final int id;
  final int userId;
  final int postId;
  final String content;
  final DateTime createdAt;
  final String? authorUsername;

  Comment({
    required this.id,
    required this.userId,
    required this.postId,
    required this.content,
    required this.createdAt,
    this.authorUsername,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userId: json['user_id'],
      postId: json['post_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      authorUsername: json['author_username'],
    );
  }
}
