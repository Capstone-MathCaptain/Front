import 'dart:convert';
import 'dart:developer'; // 로그 프레임워크 사용
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  static const String baseUrl = "http://localhost:8080";
  static const String refreshUrl = "$baseUrl/refresh-token"; // 액세스 토큰 갱신 엔드포인트

  /// ✅ 액세스 토큰 가져오기
  static Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  /// ✅ API 요청을 보내는 메서드 (401 발생 시 자동으로 토큰 갱신 후 재시도)
  static Future<http.Response> sendRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    bool includeToken = true, // 🔹 기본값을 true로 설정
  }) async {
    String? accessToken = includeToken ? await _getAccessToken() : null;

    final headers = {
      "Content-Type": "application/json",
      if (includeToken && accessToken != null)
        "Authorization": "Bearer $accessToken",
    };

    final uri = Uri.parse("$baseUrl$endpoint");
    http.Response response;
    log("🚀 요청 URL: $uri");
    log("📌 요청 헤더: $headers");
    log("📌 요청 바디: ${jsonEncode(body)}");
    try {
      if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (method == 'POST') {
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
      } else {
        throw Exception("지원되지 않는 HTTP 메서드: $method");
      }

      if (includeToken && response.statusCode == 401) {
        log("401 오류 발생 - 토큰 갱신 시도");
        String? newAccessToken = await _refreshAccessToken();
        if (newAccessToken != null) {
          headers["Authorization"] = "Bearer $newAccessToken";

          if (method == 'GET') {
            response = await http.get(uri, headers: headers);
          } else if (method == 'POST') {
            response = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(body),
            );
          }
        }
      }

      return response;
    } catch (e) {
      log("네트워크 오류 발생: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  /// ✅ 액세스 토큰 갱신
  static Future<String?> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString("access_token");
    String? refreshToken = prefs.getString("refresh_token");

    if (accessToken == null || refreshToken == null) {
      log("토큰이 존재하지 않음 - 로그인 필요");
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(refreshUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "Authorization-refresh": "Bearer $refreshToken",
        },
      );

      if (response.statusCode == 200) {
        String? newAccessToken = response.headers['authorization'];

        if (newAccessToken != null) {
          await prefs.setString("access_token", newAccessToken);
          log("새로운 액세스 토큰 저장 완료");
          return newAccessToken;
        }
      } else {
        log("토큰 갱신 실패: ${response.statusCode}");
      }
    } catch (e) {
      log("토큰 갱신 요청 중 오류 발생: $e", error: e);
    }

    return null;
  }
}
