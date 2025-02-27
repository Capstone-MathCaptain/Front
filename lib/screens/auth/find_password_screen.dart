import 'package:flutter/material.dart';
import 'package:capstone/services/user_service.dart';

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  /// ✅ ScaffoldMessengerKey 사용 (BuildContext 문제 해결)
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// ✅ 스낵바 메시지 표시 함수
  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// ✅ 비밀번호 찾기 요청 (UserService 활용)
  Future<void> _findPassword() async {
    final String name = nameController.text;
    final String email = emailController.text;

    if (name.isEmpty || email.isEmpty) {
      _showSnackBar('모든 필드를 입력해주세요.');
      return;
    }

    final bool success = await UserService.findUserPassword(name, email);

    if (success) {
      _showSnackBar('비밀번호 재설정 링크가 이메일로 전송되었습니다.');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context); // 로그인 화면으로 돌아가기
        }
      });
    } else {
      _showSnackBar('비밀번호 찾기에 실패했습니다. 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey, // ✅ ScaffoldMessenger 적용
      child: Scaffold(
        appBar: AppBar(
          title: const Text('비밀번호 찾기'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24.0),
              Center(
                child: ElevatedButton(
                  onPressed: _findPassword,
                  child: const Text('비밀번호 재설정 링크 보내기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
