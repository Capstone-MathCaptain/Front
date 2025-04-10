import 'dart:convert';
import 'dart:developer';
import 'api_helper.dart';
import 'package:capstone/models/group.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone/services/user_service.dart';

class GroupService {
  /// ✅ 사용자의 그룹 목록 불러오기 (API 호출)
  static Future<List<dynamic>> fetchUserGroups() async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/group",
        method: "GET",
      );
      final decodedData = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(decodedData)['data'];
        log("✅ 그룹 데이터 가져오기 성공: ${responseData.length}개 그룹");
        return responseData;
      } else {
        log("❌ 그룹 데이터 불러오기 실패: ${response.statusCode}");
        throw Exception("그룹 정보를 불러오지 못했습니다.");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  /// ✅ 그룹 생성 API 요청
  static Future<int?> createGroup({
    required String groupName,
    required String category,
    required int minDailyHours,
    required int minWeeklyDays,
    required int leaderDailyGoal,
    required int leaderWeeklyGoal,
    required List<String> hashtags,
    bool disturbMode = true,
    String groupImageUrl = "default_url",
  }) async {
    try {
      log("📝 그룹 생성 요청 시작: $groupName, $category, $hashtags");

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      log("현재 저장된 토큰: ${accessToken != null ? '있음' : '없음'}");

      final currentUser = await UserService.getCurrentUser();
      log("현재 사용자 정보: ${currentUser?.userId}, ${currentUser?.nickname}");

      // 서버에 보내는 요청 본문 확인 (API 명세서에 맞게 수정)
      final body = {
        "groupName": groupName,
        "category": category,
        "minDailyHours": minDailyHours,
        "minWeeklyDays": minWeeklyDays,
        "groupPoint": 0,
        "hashtags": hashtags,
        "disturb_mode": disturbMode,
        "groupImageUrl": groupImageUrl,
        "personalDailyGoal": leaderDailyGoal,
        "personalWeeklyGoal": leaderWeeklyGoal,
      };
      log("📤 요청 본문: $body");

      // 토큰 갱신 시도
      await ApiHelper.checkAndRefreshToken();

      final response = await ApiHelper.sendRequest(
        endpoint: "/group",
        method: "POST",
        body: body,
      );

      log("📥 응답 상태 코드: ${response.statusCode}");
      // UTF-8로 인코딩된 응답 본문을 올바르게 디코딩
      final String decodedBody = utf8.decode(response.bodyBytes);
      log("📥 응답 본문: $decodedBody");

      if (response.statusCode == 200) {
        final responseData = json.decode(decodedBody);
        log("📥 디코딩된 응답: $responseData");

        if (responseData['status'] == true) {
          final groupId = responseData['data']['groupId'];
          log("✅ 그룹 생성 성공: groupId=$groupId");
          return groupId;
        } else {
          log("❌ 그룹 생성 응답 status가 false: ${responseData['message']}");
          throw Exception("그룹 생성 실패: ${responseData['message']}");
        }
      } else {
        // 오류 응답도 UTF-8로 디코딩
        try {
          final errorData = json.decode(decodedBody);
          log("❌ 그룹 생성 실패: ${errorData['message']}");
          throw Exception("그룹 생성 실패: ${errorData['message']}");
        } catch (e) {
          log("❌ 그룹 생성 응답 코드 오류: ${response.statusCode}");
          throw Exception("그룹 생성 실패: 상태 코드 ${response.statusCode}");
        }
      }
    } catch (e) {
      log("❌ 그룹 생성 예외 발생: $e");
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  /// ✅ 그룹 찾기 API 요청 (아직 구현되지 않음)
  static Future<List<dynamic>> searchGroups({required String query}) async {
    log("🔍 그룹 검색 요청: $query");

    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/group/search",
        method: "GET",
        body: {"query": query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body)['data'];
        log("✅ 그룹 검색 결과: ${responseData.length}개 그룹");
        return responseData;
      } else {
        log("❌ 그룹 검색 실패: ${response.statusCode}");
        throw Exception("그룹을 찾을 수 없습니다.");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  static Future<List<Group>> getUserGroups() async {
    try {
      log("🔍 사용자 그룹 조회 시작");
      final response = await ApiHelper.get('/group');

      if (response['status'] == true) {
        final List<dynamic> groupsData = response['data'];
        log("✅ 사용자 그룹 조회 성공: ${groupsData.length}개 그룹");

        // 응답 데이터의 구조를 로그로 출력
        if (groupsData.isNotEmpty) {
          log("📦 첫 번째 그룹 데이터의 키: ${groupsData[0].keys.toList()}");
          log("📦 응답 데이터 구조: ${json.encode(groupsData[0])}");
        }

        // 각 그룹의 상세 정보 로깅
        if (groupsData.isNotEmpty) {
          log("📋 현재 생성된 그룹 목록:");
          for (var i = 0; i < groupsData.length; i++) {
            final group = groupsData[i];
            final groupId = group['groupId'] ?? group['id'] ?? '없음';

            log(
              "  ${i + 1}. 그룹명: ${group['groupName']} | ID: $groupId | "
              "카테고리: ${group['category']} | 그룹장: ${group['leaderName']}",
            );
          }
        } else {
          log("⚠️ 사용자에게 생성된 그룹이 없습니다.");
        }

        final groups = groupsData.map((data) => Group.fromJson(data)).toList();

        // 변환된 그룹 객체 내용 확인
        if (groups.isNotEmpty) {
          log("🔄 변환된 첫 번째 그룹 정보: ${groups[0].toString()}");
        }

        return groups;
      }

      log("⚠️ 서버 응답 status가 false");
      return [];
    } catch (e) {
      log('❌ 사용자 그룹 목록 조회 실패: $e');
      return [];
    }
  }

  void _printCurrentServerUrl() {
    log("현재 사용 중인 서버 URL: ${ApiHelper.baseUrl}");
  }
}
