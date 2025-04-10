import 'dart:developer';

class Recruitment {
  final int recruitmentId;
  final int recruitGroupId;
  final String authorName;
  final String recruitGroupName;
  final String title;
  final String content;
  final String category;
  final String recruitmentStatus;
  final String createdAt;
  final String updatedAt;

  Recruitment({
    required this.recruitmentId,
    required this.recruitGroupId,
    required this.authorName,
    required this.recruitGroupName,
    required this.title,
    required this.category,
    required this.content,
    required this.recruitmentStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Recruitment.fromJson(Map<String, dynamic> json) {
    log('🔄 모집글 데이터 변환 시작');
    log('🔍 JSON 키 확인: ${json.keys.toList()}');
    log('📦 원본 데이터: ${json.toString()}');

    // 1. 그룹명(recruitGroupName)에서 그룹 ID 추출 시도
    // 모집글 목록에는 ID가 없지만, 그룹명으로 매핑할 수 있음
    int extractGroupIdFromName(String? groupName) {
      if (groupName == null || groupName.isEmpty) return 0;

      // 그룹명으로 ID 매핑 (실제 그룹명 => ID 매핑)
      Map<String, int> groupNameToId = {
        'testGroup1': 1,
        'testGroup2': 2,
        'testGroup3': 3,
        'testgruop': 4,
        'test': 5,
        'workout': 6,
        'readingbook': 7,
        'library': 8,
      };

      // 매핑된 ID 반환
      if (groupNameToId.containsKey(groupName)) {
        final id = groupNameToId[groupName]!;
        log('✅ 그룹명 "$groupName"에서 그룹 ID 추출: $id');
        return id;
      }

      log('⚠️ 그룹명 "$groupName"에 대한 ID 매핑 없음');
      return 0;
    }

    // 2. recruitmentId 추출 시도
    int? extractedRecruitmentId;

    // 서버 응답에는 기본적으로 recruitmentId가 없음
    // 대신 각 모집글을 조회할 때는 API 경로에 ID가 포함됨 (/recruitment/{id})
    if (json.containsKey('id') && json['id'] != null) {
      extractedRecruitmentId =
          json['id'] is int ? json['id'] : int.tryParse(json['id'].toString());
      log('✅ id 필드에서 모집글 ID 추출: $extractedRecruitmentId');
    }
    // 로컬에서 추가된 필드로 ID를 추출 (있을 경우)
    else if (json.containsKey('recruitmentId') &&
        json['recruitmentId'] != null) {
      extractedRecruitmentId =
          json['recruitmentId'] is int
              ? json['recruitmentId']
              : int.tryParse(json['recruitmentId'].toString());
      log('✅ recruitmentId 필드에서 모집글 ID 추출: $extractedRecruitmentId');
    }

    // 3. recruitGroupId 추출 시도 - 이 ID는 모집글과 연결된 그룹 ID
    int? extractedGroupId;

    // 직접적인 recruitGroupId 필드 확인
    if (json.containsKey('recruitGroupId') && json['recruitGroupId'] != null) {
      extractedGroupId =
          json['recruitGroupId'] is int
              ? json['recruitGroupId']
              : int.tryParse(json['recruitGroupId'].toString());
      log('✅ recruitGroupId 필드에서 그룹 ID 추출: $extractedGroupId');
    }
    // groupId 필드 확인
    else if (json.containsKey('groupId') && json['groupId'] != null) {
      extractedGroupId =
          json['groupId'] is int
              ? json['groupId']
              : int.tryParse(json['groupId'].toString());
      log('✅ groupId 필드에서 그룹 ID 추출: $extractedGroupId');
    }
    // 중첩된 객체에서 검사
    else if (json.containsKey('group') &&
        json['group'] is Map<String, dynamic>) {
      final groupData = json['group'] as Map<String, dynamic>;
      if (groupData.containsKey('id')) {
        extractedGroupId =
            groupData['id'] is int
                ? groupData['id']
                : int.tryParse(groupData['id'].toString());
        log('✅ group.id 필드에서 그룹 ID 추출: $extractedGroupId');
      } else if (groupData.containsKey('groupId')) {
        extractedGroupId =
            groupData['groupId'] is int
                ? groupData['groupId']
                : int.tryParse(groupData['groupId'].toString());
        log('✅ group.groupId 필드에서 그룹 ID 추출: $extractedGroupId');
      }
    }

    // 그룹명에서 그룹 ID 추출 (다른 방법이 실패한 경우)
    if (extractedGroupId == null || extractedGroupId == 0) {
      final groupName = json['recruitGroupName'];
      extractedGroupId = extractGroupIdFromName(groupName);
    }

    // ID가 없는 경우 임시값 사용
    // 모집글 ID는 기본값 0, 그룹 ID는 extractGroupIdFromName에서 추출한 값 또는 0
    final recruitmentId = extractedRecruitmentId ?? 0;
    final recruitGroupId = extractedGroupId ?? 0;

    if (recruitmentId <= 0) {
      log('⚠️ 유효한 모집글 ID를 찾을 수 없음, 그룹명: ${json['recruitGroupName']}');
    }

    log(
      '📊 최종 변환 결과: 모집글ID=$recruitmentId, 그룹ID=$recruitGroupId, 제목=${json['title'] ?? "제목 없음"}',
    );

    return Recruitment(
      recruitmentId: recruitmentId,
      recruitGroupId: recruitGroupId,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorName: json['authorName'] ?? '',
      recruitGroupName: json['recruitGroupName'] ?? '',
      recruitmentStatus: json['recruitmentStatus'] ?? 'RECRUITING',
      category: json['category'] ?? 'STUDY',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recruitmentId': recruitmentId,
      'recruitGroupId': recruitGroupId,
      'title': title,
      'content': content,
      'authorName': authorName,
      'recruitGroupName': recruitGroupName,
      'recruitmentStatus': recruitmentStatus,
      'category': category,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() {
    return 'Recruitment{recruitmentId: $recruitmentId, recruitGroupId: $recruitGroupId, title: $title, authorName: $authorName, recruitGroupName: $recruitGroupName, category: $category, recruitmentStatus: $recruitmentStatus}';
  }
}
