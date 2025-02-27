import 'package:capstone/screens/auth/login_screen.dart';
import 'package:capstone/screens/home_screen.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:developer'; // ✅ 로그를 보기 위한 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _clearAccessTokenIfNeeded(); // ✅ 앱 시작 시 액세스 토큰 삭제
  runApp(const MyApp());
}

/// ✅ 앱 시작 시 access_token이 존재하면 삭제
Future<void> _clearAccessTokenIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey("access_token")) {
    log("🔴 앱 재시작 - 기존 액세스 토큰 삭제");
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Capstone",
      theme: ThemeData(primaryColor: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    log("🔍 저장된 액세스 토큰: $accessToken");

    if (accessToken != null) {
      try {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } catch (e) {
        _redirectToLogin();
      }
    } else {
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
