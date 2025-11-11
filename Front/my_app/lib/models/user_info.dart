// lib/models/user_info.dart

class UserInfo {
  final String userId;
  final String? userUsername;

  UserInfo({required this.userId, this.userUsername});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'] as String,
      userUsername: json['user_username'] as String?,
    );
  }
}
