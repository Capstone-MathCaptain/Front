import 'package:capstone/screens/auth/find_password_screen.dart';
import 'package:capstone/services/auth_service.dart';
import 'package:capstone/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:capstone/screens/auth/signup_screen.dart';
import 'package:capstone/screens/auth/find_email_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final TextEditingController idController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.1,
                vertical: screenHeight * 0.05,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 아이디 입력 필드
                  CustomTextField(
                    labelText: '아이디',
                    controller: idController,
                    keyboardType: TextInputType.visiblePassword,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // 비밀번호 입력 필드
                  CustomTextField(
                    labelText: '비밀번호',
                    controller: passwordController,
                    obscureText: true,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  // 로그인 버튼
                  ElevatedButton(
                    onPressed:
                        () => AuthService.login(
                          context,
                          idController.text,
                          passwordController.text,
                        ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(screenWidth * 0.6, screenHeight * 0.06),
                    ),
                    child: const Text('로그인'),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  // 하단 텍스트 버튼들
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text('회원가입'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FindEmailScreen(),
                            ),
                          );
                        },
                        child: const Text('아이디 찾기'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FindPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text('비밀번호 찾기'),
                      ),
                    ],
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
