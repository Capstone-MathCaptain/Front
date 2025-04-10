import 'dart:convert';
import 'dart:developer'; // 로그 프레임워크 사용
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class ApiHelper {
  static const String baseUrl = "http://192.168.87.178:8080";
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

    // 토큰 유효성 확인 및 갱신
    if (includeToken) {
      await checkAndRefreshToken();
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      if (includeToken && token != null) 'Authorization': 'Bearer $token',
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

      log('📥 응답 상태 코드: ${response.statusCode}');

      // 응답 로깅 (응답 크기가 큰 경우 일부만 로깅)
      if (response.bodyBytes.length > 1000) {
        final preview = utf8.decode(response.bodyBytes.sublist(0, 1000));
        log(
          '📥 응답 본문 (처음 1000바이트): $preview... (총 ${response.bodyBytes.length} 바이트)',
        );
      } else {
        try {
          final decodedBody = utf8.decode(response.bodyBytes);
          log('📥 응답 본문: $decodedBody');
        } catch (e) {
          log('📥 응답 본문 디코딩 실패: $e');
        }
      }

      return response;
    } catch (e) {
      log('❌ HTTP 요청 실패: $e');
      rethrow;
    }
  }

  static Future<String?> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString("refresh_token");

    if (refreshToken == null) {
      return null;
    }

    var headers = {
      "Content-Type": "application/json",
      "Authorization-refresh": "Bearer $refreshToken",
    };

    try {
      final response = await http.get(Uri.parse(refreshUrl), headers: headers);

      if (response.statusCode == 200) {
        final responseData = response.headers['authorization'];
        String? newAccessToken = responseData;

        if (newAccessToken != null) {
          await prefs.setString("access_token", newAccessToken);
          return newAccessToken;
        }
      }
    } catch (e) {}

    return null;
  }

  static Future<bool> checkAndRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final String? refreshToken = prefs.getString("refresh_token");

    if (refreshToken == null) {
      return false;
    }

    try {
      final url = Uri.parse("$baseUrl/auth/refresh");
      final headers = {
        "Content-Type": "application/json",
        "Authorization-refresh": "Bearer $refreshToken",
      };

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        final newToken = response.headers['authorization'];
        if (newToken != null) {
          await prefs.setString("access_token", newToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        bool refreshed = await checkAndRefreshToken();
        if (refreshed) {
          final newAccessToken = prefs.getString('access_token');
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              if (newAccessToken != null)
                'Authorization': 'Bearer $newAccessToken',
            },
          );
          if (retryResponse.statusCode == 200) {
            return json.decode(retryResponse.body);
          }
        }
        throw Exception('Authentication failed: ${response.statusCode}');
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
