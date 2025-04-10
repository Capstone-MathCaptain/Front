import 'dart:developer';

class User {
  final int userId;
  final String nickname;
  final String email;
  final String? profileImage;

  User({
    required this.userId,
    required this.nickname,
    required this.email,
    this.profileImage,
  });

  // id getter 추가 (이전 코드와의 호환성 유지)
  int get id => userId;

  factory User.fromJson(Map<String, dynamic> json) {
    log('User.fromJson 호출됨: $json');

    // ID 필드 처리 로직 - 가능한 모든 키 확인
    int userId = 0;
    if (json.containsKey('id')) {
      userId = json['id'] ?? 0;
      log('id 필드 사용: $userId');
    } else if (json.containsKey('userId')) {
      userId = json['userId'] ?? 0;
      log('userId 필드 사용: $userId');
    } else if (json.containsKey('user_id')) {
      userId = json['user_id'] ?? 0;
      log('user_id 필드 사용: $userId');
    } else {
      log('⚠️ ID 필드를 찾을 수 없음, 기본값 0 사용');
    }

    return User(
      userId: userId,
      nickname: json['nickname'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
    );
  }

  // User 클래스에 toJson 메서드 추가
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'email': email,
      'profileImage': profileImage,
    };
  }
}
