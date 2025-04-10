import 'dart:developer';

class Group {
  final int groupId;
  final String groupName;
  final String category;
  final List<String> hashtags;
  final int minDailyHours;
  final int minWeeklyDays;
  final int leaderId;
  final String leaderName;
  final int groupPoint;
  final int groupRanking;
  final bool? disturbMode;
  final String? createdDate;
  final String? groupImageUrl;

  Group({
    required this.groupId,
    required this.groupName,
    required this.category,
    required this.hashtags,
    required this.minDailyHours,
    required this.minWeeklyDays,
    required this.leaderId,
    required this.leaderName,
    this.groupPoint = 0,
    this.groupRanking = 0,
    this.disturbMode,
    this.createdDate,
    this.groupImageUrl,
  });

  int get id => groupId;

  factory Group.fromJson(Map<String, dynamic> json) {
    log('Group.fromJson - 수신된 그룹 데이터 키: ${json.keys.toList()}');

    final int groupId = json['groupId'] ?? json['id'] ?? 0;
    log('Group.fromJson - 그룹: ${json['groupName']}, 그룹ID: $groupId');

    bool? disturbMode;
    if (json['disturb_mode'] != null) {
      if (json['disturb_mode'] is bool) {
        disturbMode = json['disturb_mode'];
      } else if (json['disturb_mode'] is String) {
        disturbMode = json['disturb_mode'].toLowerCase() == 'true';
      } else if (json['disturb_mode'] is num) {
        disturbMode = json['disturb_mode'] > 0;
      }
    }

    return Group(
      groupId: groupId,
      groupName: json['groupName'] ?? '',
      category: json['category'] ?? '',
      hashtags: List<String>.from(json['hashtags'] ?? []),
      minDailyHours: json['minDailyHours'] ?? json['min_daily_hours'] ?? 0,
      minWeeklyDays: json['minWeeklyDays'] ?? json['min_weekly_days'] ?? 0,
      leaderId: json['leaderId'] ?? 0,
      leaderName: json['leaderName'] ?? '',
      groupPoint: json['groupPoint'] ?? 0,
      groupRanking: json['groupRanking'] ?? 0,
      disturbMode: disturbMode,
      createdDate: json['created_date']?.toString(),
      groupImageUrl: json['groupImageUrl']?.toString(),
    );
  }

  @override
  String toString() {
    return 'Group(groupId: $groupId, groupName: $groupName, category: $category, leaderId: $leaderId, leaderName: $leaderName, groupPoint: $groupPoint, groupRanking: $groupRanking)';
  }
}
