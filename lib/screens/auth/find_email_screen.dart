import 'package:flutter/material.dart';
import 'package:capstone/services/user_service.dart';

class FindEmailScreen extends StatefulWidget {
  const FindEmailScreen({super.key});

  @override
  State<FindEmailScreen> createState() => _FindEmailScreen();
}

class _FindEmailScreen extends State<FindEmailScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// ✅ 이메일 찾기 요청 (UserService 활용)
  Future<void> _findEmail() async {
    final String name = nameController.text;
    final String phone = phoneController.text;

    if (name.isEmpty || phone.isEmpty) {
      _showSnackBar('모든 필드를 입력해주세요.');
      return;
    }

    final String? userEmail = await UserService.findUserEmail(name, phone);

    if (userEmail != null) {
      _showEmailDialog(userEmail); // 이메일 다이얼로그 표시
    } else {
      _showSnackBar('이메일을 찾을 수 없습니다. 다시 시도해주세요.');
    }
  }

  /// ✅ 찾은 이메일을 다이얼로그로 표시
  void _showEmailDialog(String userEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이메일 찾기'),
        content: Text('회원님의 이메일: $userEmail'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 로그인 화면으로 돌아가기
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('이메일 찾기'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: '휴대폰번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24.0),
              Center(
                child: ElevatedButton(
                  onPressed: _findEmail,
                  child: const Text('이메일 찾기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
