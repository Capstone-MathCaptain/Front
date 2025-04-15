import 'dart:convert';
import 'dart:developer'; // 로그 프레임워크 사용
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  static const String baseUrl = "http://15.165.32.175:8080";
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
    bool includeToken = true,
  }) async {
    log('🔄 API 요청 시작: $method $endpoint');
    String? accessToken = includeToken ? await _getAccessToken() : null;

    final uri = Uri.parse('$baseUrl$endpoint');
    var headers = {
      'Content-Type': 'application/json',
      if (includeToken && accessToken != null)
        'Authorization': 'Bearer $accessToken',
    };

    log('🔗 요청 URL: $uri');
    log('🔑 헤더: $headers');
    if (body != null) {
      log('📦 요청 본문: ${json.encode(body)}');
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        default:
          throw Exception('지원하지 않는 HTTP 메서드: $method');
      }
      //401 발생 경우 토큰 갱신 시도
      if (includeToken &&
          (response.statusCode == 401 || response.statusCode == 403)) {
        log("${response.statusCode}오류 발생 - 토큰 갱신 시도");
        String? newAccessToken = await _refreshAccessToken();
        if (newAccessToken != null) {
          headers["Authorization"] = "Bearer $newAccessToken";
          headers = {
            "Content-Type": "application/json",
            "Authorization": "Bearer $newAccessToken",
          };
          if (method == 'GET') {
            response = await http.get(uri, headers: headers);
            log("재요청(GET) 완료");
          } else if (method == 'POST') {
            response = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(body),
            );
            log("재요청(POST) 완료");
          }
        }
      }
      return response;
    } catch (e) {
      log('❌ HTTP 요청 실패: $e');
      rethrow;
    }
  }

  //액세스 토큰 갱신 함수
  static Future<String?> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString("refresh_token");
    String? accessToken = prefs.getString("access_token");

    if (accessToken == null || refreshToken == null) {
      log("토큰이 존재하지 않음 - 로그인 필요");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(refreshUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "Authorization-refresh": "Bearer $refreshToken",
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.headers['authorization'];
        String? newAccessToken = responseData;

        if (newAccessToken != null) {
          await prefs.setString("access_token", newAccessToken);
          log("새로운 토큰 갱신 성공");
          return newAccessToken;
        } else {
          log("토큰 갱신 실패: ${response.statusCode}");
        }
      }
    } catch (e) {
      log("토큰 갱신 실패: $e", error: e);
    }

    return null;
  }
}
