import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone/screens/home_screen.dart';
import 'api_helper.dart';
import 'user_service.dart';
import 'dart:convert';

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

      log(response.body);
      log(response.statusCode.toString());

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'access_token',
          response.headers['authorization'] ?? "",
        );
        await prefs.setString(
          'refresh_token',
          response.headers['authorization-refresh'] ?? "",
        );

        await UserService.fetchAndSaveUserId();
        // 서버에서 받은 userId 저장
        // 서버에서 받은 userId 저장
        final responseData = jsonDecode(response.body);
        final newUserId = responseData['data']['userId'];
        await UserService.saveuserId(newUserId);

        log("✅ 로그인 성공");

        if (context.mounted) {
          // ✅ 로그인 성공 후 HomeScreen으로 이동 (userGroups 없이)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showSnackBar("아이디 또는 비밀번호가 잘못되었습니다.");
      }
    } catch (e) {
      log("❌ 로그인 요청 실패: $e", error: e);
      _showSnackBar("네트워크 오류가 발생했습니다.");
    }
  }

  /// ✅ 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('userId');
  }

  /// ✅ 메시지 표시 (BuildContext 없이 사용 가능)
  static void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
