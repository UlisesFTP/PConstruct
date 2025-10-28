// lib/models/review.dart

class Review {
  final String userName;
  final String userAvatar;
  final String timeAgo;
  final int rating;
  final String comment;
  final int likes;
  final int dislikes;

  Review({
    required this.userName,
    required this.userAvatar,
    required this.timeAgo,
    required this.rating,
    required this.comment,
    required this.likes,
    required this.dislikes,
  });

  // TODO: Add factory constructor .fromJson() later
}
