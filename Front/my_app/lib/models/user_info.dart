// lib/models/user_info.dart

class UserInfo {
  final String userId;
  final String? userUsername;

  UserInfo({required this.userId, this.userUsername});

  // Factory constructor a prueba de nulos
  factory UserInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return UserInfo(userId: '0', userUsername: 'Anónimo');
    }
    return UserInfo(
      userId: json['user_id'] as String,
      userUsername: json['user_username'] as String?,
    );
  }
}
