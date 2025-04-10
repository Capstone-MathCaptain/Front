import 'dart:developer';

class UserProfile {
  final int userId;
  final String userName;
  final String userTier;
  final int userPoint;
  final List<GroupCard> groupCards;

  UserProfile({
    required this.userId,
    required this.userName,
    required this.userTier,
    required this.userPoint,
    required this.groupCards,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    log('🔄 사용자 프로필 데이터 변환: ${json.toString()}');

    // 그룹 카드 정보 파싱
    List<GroupCard> cards = [];
    if (json['groupCards'] is List) {
      cards =
          (json['groupCards'] as List)
              .map((cardJson) => GroupCard.fromJson(cardJson))
              .toList();
    }

    return UserProfile(
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      userTier: json['userTier'] ?? 'BRONZE',
      userPoint: json['userPoint'] ?? 0,
      groupCards: cards,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userTier': userTier,
      'userPoint': userPoint,
      'groupCards': groupCards.map((card) => card.toJson()).toList(),
    };
  }
}

class GroupCard {
  final int groupId;
  final String groupName;
  final String groupImageUrl;
  final String groupRole;
  final int groupRanking;
  final int groupPoint;
  final Map<String, bool> userAchieve;
  final int userDailyGoal;
  final int userWeeklyGoal;

  GroupCard({
    required this.groupId,
    required this.groupName,
    required this.groupImageUrl,
    required this.groupRole,
    required this.groupRanking,
    required this.groupPoint,
    required this.userAchieve,
    required this.userDailyGoal,
    required this.userWeeklyGoal,
  });

  factory GroupCard.fromJson(Map<String, dynamic> json) {
    // 달성 정보 파싱
    Map<String, bool> achieve = {};
    if (json['userAchieve'] is Map) {
      final userAchieveData = json['userAchieve'] as Map;
      userAchieveData.forEach((key, value) {
        achieve[key.toString()] = value is bool ? value : false;
      });
    } else {
      // 기본 요일 값 설정
      achieve = {
        'MONDAY': false,
        'TUESDAY': false,
        'WEDNESDAY': false,
        'THURSDAY': false,
        'FRIDAY': false,
        'SATURDAY': false,
        'SUNDAY': false,
      };
    }

    return GroupCard(
      groupId: json['groupId'] ?? 0,
      groupName: json['groupName'] ?? '',
      groupImageUrl: json['groupImageUrl'] ?? '',
      groupRole: json['groupRole'] ?? 'MEMBER',
      groupRanking: json['groupRanking'] ?? 0,
      groupPoint: json['groupPoint'] ?? 0,
      userAchieve: achieve,
      userDailyGoal: json['userDailyGoal'] ?? 0,
      userWeeklyGoal: json['userWeeklyGoal'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupImageUrl': groupImageUrl,
      'groupRole': groupRole,
      'groupRanking': groupRanking,
      'groupPoint': groupPoint,
      'userAchieve': userAchieve,
      'userDailyGoal': userDailyGoal,
      'userWeeklyGoal': userWeeklyGoal,
    };
  }

  // 완료한 요일 개수 계산
  int getCompletedDays() {
    return userAchieve.values.where((v) => v == true).length;
  }

  // 주간 목표 달성 비율 계산 (0.0 ~ 1.0)
  double getWeeklyProgressRate() {
    final completed = getCompletedDays();
    return userWeeklyGoal > 0 ? completed / userWeeklyGoal : 0.0;
  }
}
