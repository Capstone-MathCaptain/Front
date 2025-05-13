import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_helper.dart';

class UserService {
  /// ✅ 사용자 이메일 찾기
  static Future<String?> findUserEmail(String name, String phone) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/user/find/email",
        method: "POST",
        body: {"userName": name, "phoneNumber": phone},
        includeToken: false, // 🔹 로그인 없이 사용 가능
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        log("✅ 이메일 찾기 성공: ${responseData['data']['email']}");
        return responseData['data']['email'];
      } else {
        log("❌ 이메일 찾기 실패: ${response.body}");
        return null;
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      return null;
    }
  }

  /// ✅ 사용자 비밀번호찾기(초기화메일 전송) (토큰 없이 요청)
  static Future<bool> findUserPassword(String name, String email) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/user/find/password",
        method: "POST",
        body: {"name": name, "email": email},
        includeToken: false, // 🔹 로그인 없이 사용 가능
      );

      if (response.statusCode == 200) {
        log("✅ 비밀번호 재설정 요청 성공");
        return true;
      } else {
        log("❌ 비밀번호 찾기 실패: ${response.body}");
        return false;
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      return false;
    }
  }

  /// ✅ 사용자 회원가입 (토큰 없이 요청)
  static Future<bool> signupUser({
    required String name,
    required String nickname,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/user/signup",
        method: "POST",
        body: {
          "name": name,
          "nickname": nickname,
          "email": email,
          "password": password,
          "phoneNumber": phoneNumber,
        },
        includeToken: false, // 🔹 로그인 없이 사용 가능
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userId = responseData['data']['userId'];

        // userId 저장
        await saveuserId(userId);

        log("✅ 회원가입 성공");
        return true;
      } else {
        log("❌ 회원가입 실패: ${response.body}");
        return false;
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      return false;
    }
  }

  // userId 저장 함수
  static Future<void> saveuserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
  }

  // userId 가져오기
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  static Future<Map<String, dynamic>> getUserInfo({required int userId}) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: '/user/$userId',
        method: 'GET',
      );
      final decodedData = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(decodedData);

      if (response.statusCode == 200 && responseData["status"] == true) {
        log('✅ 사용자 정보 조회 성공: ${responseData['data']}');
        return responseData['data'];
      } else if (response.statusCode == 400) {
        log('❌ 잘못된 요청: 필수 필드 누락 또는 잘못된 요청');
        throw Exception("필수 필드 누락 또는 잘못된 요청입니다.");
      } else if (response.statusCode == 404) {
        log('❌ 리소스를 찾을 수 없음: 해당 유저가 없습니다.');
        throw Exception("해당 유저가 없습니다.");
      } else {
        log(
          '사용자 정보 조회 실패. 응답: ${response.statusCode}, ${responseData['message']}',
        );
        throw Exception(responseData['message'] ?? "사용자 정보 조회 실패");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  /// ✅ 로그인 성공 시 userId 저장
  static Future<void> fetchAndSaveUserId() async {
    final userId = await getUserId();
    if (userId != null) {
      await saveuserId(userId);
    }
  }
}
