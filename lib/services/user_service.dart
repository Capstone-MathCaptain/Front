import 'dart:convert';
import 'dart:developer';
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
}
