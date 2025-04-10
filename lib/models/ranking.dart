import 'dart:developer';

class RankingGroup {
  final int groupId;
  final String groupName;
  final int groupPoint;
  final int ranking;

  RankingGroup({
    required this.groupId,
    required this.groupName,
    required this.groupPoint,
    required this.ranking,
  });

  factory RankingGroup.fromJson(Map<String, dynamic> json) {
    log('🔄 랭킹 그룹 데이터 변환: ${json.toString()}');

    return RankingGroup(
      groupId: json['groupId'] ?? 0,
      groupName: json['groupName'] ?? '',
      groupPoint: json['groupPoint'] ?? 0,
      ranking: json['ranking'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupPoint': groupPoint,
      'ranking': ranking,
    };
  }

  @override
  String toString() {
    return 'RankingGroup{groupId: $groupId, groupName: $groupName, groupPoint: $groupPoint, ranking: $ranking}';
  }
}

class RankingPageInfo {
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isFirst;
  final bool isLast;
  final int numberOfElements;

  RankingPageInfo({
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isFirst,
    required this.isLast,
    required this.numberOfElements,
  });

  factory RankingPageInfo.fromJson(Map<String, dynamic> json) {
    return RankingPageInfo(
      pageNumber: json['number'] ?? 0,
      pageSize: json['size'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
      totalElements: json['totalElements'] ?? 0,
      isFirst: json['first'] ?? true,
      isLast: json['last'] ?? true,
      numberOfElements: json['numberOfElements'] ?? 0,
    );
  }
}
