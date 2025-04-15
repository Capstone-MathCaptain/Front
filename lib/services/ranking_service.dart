import 'dart:convert';
import 'dart:developer';
import 'api_helper.dart';

class RankingService {
  //랭킹 조회
  static Future<RankingPageResponse> fetchRanking(int page) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/ranking/$page",
        method: "GET",
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(response.body)['data'];
        log("✅ 랭킹 조회 성공: ${responseData['content'].length}개 항목");
        return RankingPageResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        throw Exception("오류 처리: ${jsonDecode(response.body)['message']}");
      } else if (response.statusCode == 404) {
        throw Exception("해당 그룹이 없습니다");
      } else {
        throw Exception("랭킹 조회 실패: ${response.statusCode}");
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
}

class RankingPageResponse {
  final List<RankingItem> items;
  final PageInfo pageInfo;

  RankingPageResponse({required this.items, required this.pageInfo});

  factory RankingPageResponse.fromJson(Map<String, dynamic> json) {
    return RankingPageResponse(
      items:
          (json['content'] as List)
              .map((item) => RankingItem.fromJson(item))
              .toList(),
      pageInfo: PageInfo.fromJson(json['pageable']),
    );
  }
}

class RankingItem {
  final int groupId;
  final String groupName;
  final int groupPoint;
  final int ranking;

  RankingItem({
    required this.groupId,
    required this.groupName,
    required this.groupPoint,
    required this.ranking,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) {
    return RankingItem(
      groupId: json['groupId'],
      groupName: json['groupName'],
      groupPoint: json['groupPoint'],
      ranking: json['ranking'],
    );
  }
}

class PageInfo {
  final int totalPages;
  final int totalElements;
  final int size;
  final int number;

  PageInfo({
    required this.totalPages,
    required this.totalElements,
    required this.size,
    required this.number,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      totalPages: json['totalPages'],
      totalElements: json['totalElements'],
      size: json['size'],
      number: json['number'],
    );
  }
}
