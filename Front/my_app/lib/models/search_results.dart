import 'package:my_app/models/posts.dart'; // Asegúrate de que la ruta a tu modelo Post sea correcta

class UserSummary {
  final int userId;
  final String username;
  final String? name;

  UserSummary({required this.userId, required this.username, this.name});

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      userId: json['user_id'],
      username: json['username'],
      name: json['name'],
    );
  }
}

class SearchResults {
  final List<Post> posts;
  final List<UserSummary> users;

  SearchResults({required this.posts, required this.users});

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    var postList = json['posts'] as List;
    var userList = json['users'] as List;

    return SearchResults(
      posts: postList.map((i) => Post.fromJson(i)).toList(),
      users: userList.map((i) => UserSummary.fromJson(i)).toList(),
    );
  }
}
