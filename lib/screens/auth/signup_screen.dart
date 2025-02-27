import 'package:capstone/services/user_service.dart';
import 'package:capstone/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  /// ✅ ScaffoldMessengerKey 사용 (BuildContext 문제 해결)
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// ✅ 스낵바 메시지 표시 함수
  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitSignup() async {
    final String name = nameController.text;
    final String nickname = nicknameController.text;
    final String email = emailController.text;
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;
    final String phone = phoneController.text;

    if ([name, nickname, email, password, confirmPassword, phone]
        .any((field) => field.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    final bool success = await UserService.signupUser(
      name: name,
      nickname: nickname,
      email: email,
      password: password,
      phoneNumber: phone,
    );

    if (success) {
      _showSnackBar('회원가입 성공! 🎉');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context); // 로그인 화면으로 돌아가기
        }
      });
    } else {
      _showSnackBar('회원가입 실패. 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.1),
                  CustomTextField(
                    labelText: '이름',
                    controller: nameController,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  CustomTextField(
                    labelText: '닉네임',
                    controller: nicknameController,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  CustomTextField(
                    labelText: '이메일',
                    controller: emailController,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  CustomTextField(
                    labelText: '비밀번호',
                    controller: passwordController,
                    obscureText: true,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  CustomTextField(
                    labelText: '비밀번호 확인',
                    controller: confirmPasswordController,
                    obscureText: true,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  CustomTextField(
                    labelText: '휴대폰번호',
                    controller: phoneController,
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitSignup,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(screenWidth * 0.6, 50),
                      ),
                      child: const Text('회원가입 완료'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
