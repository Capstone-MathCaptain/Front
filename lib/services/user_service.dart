import 'dart:convert';
import 'dart:developer';
import 'package:capstone/services/api_helper.dart';
import 'package:capstone/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        return responseData['data']['email'];
      } else {
        return null;
      }
    } catch (e) {
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
        return true;
      } else {
        return false;
      }
    } catch (e) {
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
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<User?> getCurrentUser() async {
    try {
      log('💡 getCurrentUser 호출 시작');

      // 토큰과 사용자 ID 가져오기
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final accessToken = prefs.getString('access_token');

      log(
        '로그인 상태 확인 - 액세스 토큰: ${accessToken != null ? "있음" : "없음"}, userId: $userId',
      );

      // 토큰이 없으면 로그인되지 않은 상태
      if (accessToken == null) {
        log('⚠️ 액세스 토큰 없음 - 로그인 필요');
        return null;
      }

      // userId가 없으면 사용할 수 없음
      if (userId == null) {
        log('⚠️ userId 값이 없음 - 로그인 필요');
        return null;
      }

      // 토큰 갱신 시도
      log('🔄 토큰 갱신 시도');
      await ApiHelper.checkAndRefreshToken();

      // 사용자 정보 요청 (토큰 갱신 후)
      log('📡 사용자 정보 요청 시작 - userId: $userId');

      try {
        // 서버 엔드포인트를 통해 사용자 정보 요청
        final response = await ApiHelper.sendRequest(
          endpoint: "/user/$userId",
          method: "GET",
          includeToken: true,
        );

        log('📥 응답 상태 코드: ${response.statusCode}');

        // 응답 성공 시 사용자 정보 파싱
        if (response.statusCode == 200) {
          // UTF-8로 인코딩된 응답 본문을 올바르게 디코딩
          final String decodedBody = utf8.decode(response.bodyBytes);
          log('📥 응답 본문: $decodedBody');

          final responseData = json.decode(decodedBody);

          if (responseData['status'] == true && responseData['data'] != null) {
            log('✅ 사용자 정보 조회 성공');
            final nickname = responseData['data']['nickname'] ?? '알 수 없음';
            final email = responseData['data']['email'] ?? '알 수 없음';
            log('👤 현재 로그인된 사용자 - 닉네임: $nickname, 이메일: $email');
            return User.fromJson(responseData['data']);
          } else {
            log('❌ 서버 응답 status가 false 또는 데이터 없음');
            return null;
          }
        } else if (response.statusCode == 401) {
          log('🔑 인증 오류 발생 - 토큰이 만료되었을 수 있음');
          return null;
        } else if (response.statusCode == 403) {
          log('🔒 접근 권한 없음 - 권한 문제');
          return null;
        } else {
          log('❌ 서버 응답 오류: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        log('❌ API 요청 실패: $e');
        return null;
      }
    } catch (e) {
      log('❌ getCurrentUser 오류: $e');
      return null;
    }
  }
}
