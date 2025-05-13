import 'package:capstone/screens/user/find_password_screen.dart';
import 'package:capstone/services/auth_service.dart';
import 'package:capstone/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:capstone/screens/user/signup_screen.dart';
import 'package:capstone/screens/user/find_email_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final TextEditingController idController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('로그인', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          Text(
                            '의지박약',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 32),
                          CustomTextField(
                            labelText: '아이디',
                            controller: idController,
                            keyboardType: TextInputType.visiblePassword,
                            onSubmitted: (_) => AuthService.login(
                              context,
                              idController.text,
                              passwordController.text,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            labelText: '비밀번호',
                            controller: passwordController,
                            obscureText: true,
                            onSubmitted: (_) => AuthService.login(
                              context,
                              idController.text,
                              passwordController.text,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => AuthService.login(
                              context,
                              idController.text,
                              passwordController.text,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEEF4FF),
                              foregroundColor: const Color(0xFF5C6BC0),
                              minimumSize: Size(screenWidth * 0.6, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Color(0xFF5C6BC0),
                                ),
                              ),
                            ),
                            child: const Text('로그인'),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF5C6BC0),
                                ),
                                child: const Text('회원가입'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FindEmailScreen(),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF5C6BC0),
                                ),
                                child: const Text('아이디 찾기'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FindPasswordScreen(),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF5C6BC0),
                                ),
                                child: const Text('비밀번호 찾기'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
