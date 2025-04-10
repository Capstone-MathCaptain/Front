import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone/screens/home_screen.dart';
import 'api_helper.dart';

class AuthService {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// ✅ 로그인 요청 (토큰만 저장, userGroups 불러오지 않음)
  static Future<void> login(
    BuildContext context,
    String id,
    String password,
  ) async {
    if (id.isEmpty || password.isEmpty) {
      _showSnackBar("아이디와 비밀번호를 입력해주세요.");
      return;
    }

    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/login",
        method: "POST",
        body: {'email': id, 'password': password},
        includeToken: false,
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        // 토큰 저장
        final accessToken = response.headers['authorization'] ?? "";
        final refreshToken = response.headers['authorization-refresh'] ?? "";
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);

        log('🔑 로그인 성공 - 이메일: $id');
        log(
          '💫 토큰 저장 완료 - 액세스 토큰: ${accessToken.isNotEmpty ? "있음" : "없음"}, 리프레시 토큰: ${refreshToken.isNotEmpty ? "있음" : "없음"}',
        );

        // 로그인한 이메일 정보 저장
        await prefs.setString('email', id);

        try {
          // 로그인 응답에서 사용자 ID 추출 시도
          String? userId;
          try {
            // 응답 본문을 UTF-8로 디코딩
            final String decodedBody = utf8.decode(response.bodyBytes);
            log('📥 로그인 응답 본문: $decodedBody');

            final responseData = json.decode(decodedBody);
            if (responseData['data'] != null) {
              userId =
                  responseData['data']['userId']?.toString() ??
                  responseData['data']['id']?.toString();

              if (userId != null) {
                await prefs.setInt('userId', int.parse(userId));
                log('💾 사용자 ID 저장: $userId');
              }
            }
          } catch (e) {
            log('⚠️ 로그인 응답에서 사용자 ID 추출 실패: $e');
          }

          // 사용자 ID가 추출되지 않았을 경우, 사용자 정보 API 호출
          if (userId == null) {
            log('🔍 사용자 정보 API 호출 시작');

            // 이메일로 사용자 조회 시도
            final userEmailEndpoint = "/user/email/$id";
            log('🔍 엔드포인트 호출: $userEmailEndpoint');

            try {
              final userResponse = await ApiHelper.sendRequest(
                endpoint: userEmailEndpoint,
                method: "GET",
                includeToken: true,
              );

              log('📥 사용자 정보 응답 상태 코드: ${userResponse.statusCode}');

              if (userResponse.statusCode == 200) {
                // UTF-8로 디코딩
                final String decodedBody = utf8.decode(userResponse.bodyBytes);
                log('📥 사용자 정보 응답 본문: $decodedBody');

                final userData = json.decode(decodedBody);

                // 사용자 정보 로깅
                if (userData['data'] != null) {
                  final nickname = userData['data']['nickname'] ?? '알 수 없음';
                  final name = userData['data']['name'] ?? '알 수 없음';
                  log('👤 로그인한 사용자 정보 - 닉네임: $nickname, 이름: $name');

                  // userId 저장
                  if (userData['data']['id'] != null) {
                    final id = userData['data']['id'];
                    await prefs.setInt('userId', id);
                    log('💾 사용자 ID 저장: $id (id 필드)');
                  } else if (userData['data']['userId'] != null) {
                    final id = userData['data']['userId'];
                    await prefs.setInt('userId', id);
                    log('💾 사용자 ID 저장: $id (userId 필드)');
                  }
                }
              } else {
                log('⚠️ 사용자 정보 API 호출 실패: ${userResponse.statusCode}');
              }
            } catch (e) {
              log('⚠️ 사용자 정보 API 호출 오류: $e');
            }
          }
        } catch (userError) {
          log('❌ 사용자 정보 처리 오류: $userError');
        }

        if (context.mounted) {
          // ✅ 로그인 성공 후 HomeScreen으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showSnackBar("아이디 또는 비밀번호가 잘못되었습니다.");
      }
    } catch (e) {
      _showSnackBar("네트워크 오류가 발생했습니다.");
    }
  }

  /// ✅ 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  /// ✅ 메시지 표시 (BuildContext 없이 사용 가능)
  static void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
