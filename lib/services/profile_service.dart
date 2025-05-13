import 'dart:convert';
import 'dart:developer';
import 'api_helper.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/user/mypage",
        method: "GET",
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes); // ⭐ 인코딩 처리
        final Map<String, dynamic> responseData = jsonDecode(decoded)['data'];
        log("✅ 프로필 조회 성공");
        return responseData;
      } else if (response.statusCode == 400) {
        throw Exception("오류 처리: ${jsonDecode(response.body)['message']}");
      } else if (response.statusCode == 404) {
        throw Exception("리소스를 찾을 수 없음");
      } else {
        throw Exception("프로필 조회 실패: ${response.statusCode}");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }
}
