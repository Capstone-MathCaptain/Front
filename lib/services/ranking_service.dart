import 'dart:convert';
import 'dart:developer';
import 'package:capstone/models/ranking.dart';
import 'package:capstone/services/api_helper.dart';

class RankingService {
  /// 랭킹 목록 조회 - 페이지 번호를 받아 해당 페이지의 랭킹 정보 조회
  static Future<Map<String, dynamic>> getRankings(int page) async {
    log('📊 랭킹 조회 시작 - 페이지: $page');

    // 토큰 갱신 시도
    try {
      await ApiHelper.checkAndRefreshToken();
      log('✅ 토큰 갱신 완료');
    } catch (e) {
      log('❌ 토큰 갱신 실패: $e');
      // 토큰 오류가 있더라도 계속 진행 (게스트 모드 대응)
    }

    try {
      // API 요청
      final response = await ApiHelper.sendRequest(
        endpoint: '/ranking/$page',
        method: 'GET',
      );

      log('📥 랭킹 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 응답 본문 디코딩
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(responseBody);

        log('✅ 랭킹 조회 성공');

        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'];

          // 랭킹 그룹 리스트 파싱
          List<RankingGroup> rankingGroups = [];
          if (data['content'] is List) {
            final List<dynamic> groupsData = data['content'];
            log('📊 ${groupsData.length}개의 그룹 랭킹 정보 발견');

            rankingGroups =
                groupsData
                    .map((groupData) => RankingGroup.fromJson(groupData))
                    .toList();

            // 디버깅을 위한 로그
            if (rankingGroups.isEmpty) {
              log('⚠️ 랭킹 정보가 없거나 비어 있습니다.');
            } else {
              // 포인트가 모두 0인지 확인
              bool allZeroPoints = rankingGroups.every(
                (group) => group.groupPoint == 0,
              );
              if (allZeroPoints) {
                log('⚠️ 모든 그룹의 포인트가 0입니다. 서버에서 제공한 랭킹 순서를 그대로 사용합니다.');
              }

              for (int i = 0; i < rankingGroups.length; i++) {
                final group = rankingGroups[i];
                log(
                  '  ${i + 1}. 서버 랭킹: ${group.ranking}위, 그룹명: ${group.groupName} (점수: ${group.groupPoint})',
                );
              }
            }
          }

          // 페이지 정보 파싱
          RankingPageInfo? pageInfo;
          if (data is Map) {
            try {
              // Map<dynamic, dynamic>을 Map<String, dynamic>으로 변환
              final Map<String, dynamic> pageData = Map<String, dynamic>.from(
                data,
              );
              pageInfo = RankingPageInfo.fromJson(pageData);
              log(
                '📄 페이지 정보: ${pageInfo.pageNumber + 1}/${pageInfo.totalPages} (총 항목: ${pageInfo.totalElements})',
              );
            } catch (e) {
              log('⚠️ 페이지 정보 파싱 실패: $e');
              // 페이지 정보 파싱 실패 시 기본값 사용
              pageInfo = RankingPageInfo(
                pageNumber: page,
                pageSize: 10,
                totalPages: 1,
                totalElements: rankingGroups.length,
                isFirst: page == 0,
                isLast: true,
                numberOfElements: rankingGroups.length,
              );
            }
          } else {
            log('⚠️ 페이지 정보가 없습니다. 기본값을 사용합니다.');
            pageInfo = RankingPageInfo(
              pageNumber: page,
              pageSize: 10,
              totalPages: 1,
              totalElements: rankingGroups.length,
              isFirst: page == 0,
              isLast: true,
              numberOfElements: rankingGroups.length,
            );
          }

          // 결과 반환
          return {'rankingGroups': rankingGroups, 'pageInfo': pageInfo};
        } else {
          log('❌ 랭킹 조회 실패: ${responseData['message'] ?? "응답 데이터가 유효하지 않습니다."}');
          return _generateDummyRankings(page);
        }
      } else {
        log('❌ 랭킹 조회 실패: 상태 코드 ${response.statusCode}');
        return _generateDummyRankings(page);
      }
    } catch (e) {
      log('❌ 랭킹 조회 오류: $e');
      return _generateDummyRankings(page);
    }
  }

  /// 더미 랭킹 데이터 생성
  static Map<String, dynamic> _generateDummyRankings(int page) {
    log('🔧 더미 랭킹 데이터 생성');

    List<RankingGroup> dummyGroups = [
      RankingGroup(
        groupId: 1,
        groupName: '스터디 그룹 A',
        groupPoint: 100,
        ranking: 1,
      ),
      RankingGroup(groupId: 2, groupName: '독서 모임', groupPoint: 80, ranking: 2),
      RankingGroup(groupId: 3, groupName: '운동 동아리', groupPoint: 70, ranking: 3),
      RankingGroup(groupId: 4, groupName: '코딩 스터디', groupPoint: 50, ranking: 4),
      RankingGroup(groupId: 5, groupName: '영어 회화반', groupPoint: 40, ranking: 5),
    ];

    RankingPageInfo pageInfo = RankingPageInfo(
      pageNumber: page,
      pageSize: 10,
      totalPages: 1,
      totalElements: 5,
      isFirst: page == 0,
      isLast: true,
      numberOfElements: 5,
    );

    return {'rankingGroups': dummyGroups, 'pageInfo': pageInfo};
  }
}
