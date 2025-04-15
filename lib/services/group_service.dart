import 'dart:convert';
import 'dart:developer';
import 'api_helper.dart';

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
  static Future<bool> createGroup({
    required String groupName,
    required String category,
    required int minDailyHours,
    required int minWeeklyDays,
    required int leaderDailyGoal,
    required int leaderWeeklyGoal,
    required List<String> hashtags,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "groupName": groupName,
        "category": category,
        "min_daily_hours": minDailyHours,
        "min_weekly_days": minWeeklyDays,
        "group_point": 0,
        "hashtags": hashtags,
        "group_image_url": "default_url",
        "personalDailyGoal": leaderDailyGoal,
        "personalWeeklyGoal": leaderWeeklyGoal,
      };

      final response = await ApiHelper.sendRequest(
        endpoint: "/group",
        method: "POST",
        body: requestBody,
      );
      final decodedData = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(decodedData);

      if (response.statusCode == 200 && responseData["status"] == true) {
        log("✅ 그룹 생성 성공: $responseData");
        return true;
      } else {
        log("❌ 그룹 생성 실패: ${response.statusCode},${responseData['message']}");
        throw Exception(responseData["message"] ?? "그룹 생성 실패");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  /// ✅ 특정 그룹 정보 불러오기 (기존 fetchGroupDetails를 이동)
  static Future<Map<String, dynamic>> fetchGroupDetails(int groupId) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/group/detail/$groupId",
        method: "GET",
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      } else {
        throw Exception("그룹 세부 정보를 불러오는 데 실패했습니다.");
      }
    } catch (e) {
      log("❌ 그룹 세부 정보 불러오기 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  /// ✅ 특정 그룹 멤버 정보 불러오기
  static Future<List<dynamic>> fetchGroupMembers(int groupId) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/group/detail/$groupId/members",
        method: "GET",
      );

      if (response.statusCode == 200) {
        final List<dynamic> membersData = jsonDecode(response.body)['data'];
        log("✅ 그룹 멤버 데이터 가져오기 성공: ${membersData.length}명");
        return membersData;
      } else {
        log("❌ 그룹 멤버 데이터 불러오기 실패: ${response.statusCode}");
        throw Exception("그룹 멤버 정보를 불러오지 못했습니다.");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCategoryGroup(
    String category,
  ) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/group/total?category=$category",
        method: "GET",
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        log("✅ [$category] 그룹 데이터 가져오기 성공: ${data.length}개 그룹");
        return data.cast<Map<String, dynamic>>();
      } else {
        log("❌ 카테고리별 그룹 데이터 불러오기 실패: ${response.statusCode}");
        throw Exception(
          "카테고리별 그룹 정보를 불러오지 못했습니다. 상태코드: ${response.statusCode}",
        );
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  //모든 그룹 조회(찾기)
  static Future<List<dynamic>> fetchAllGroups() async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/group/total",
        method: "GET",
      );
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body)['data'];
        log("✅ 모든 그룹 조회 성공: ${responseData.length}개 그룹");
        return responseData;
      } else if (response.statusCode == 400) {
        throw Exception("오류 처리: ${jsonDecode(response.body)['message']}");
      } else if (response.statusCode == 404) {
        throw Exception("해당 그룹이 없습니다");
      } else {
        throw Exception("모든 그룹 조회 실패: ${response.statusCode}");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
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
}
