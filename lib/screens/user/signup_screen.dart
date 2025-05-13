import 'package:capstone/services/user_service.dart';
import 'package:capstone/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  void _showSnackBar(String message) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitSignup() async {
    final name = nameController.text.trim();
    final nickname = nicknameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final phone = phoneController.text.trim();

    if ([
      name,
      nickname,
      email,
      password,
      confirmPassword,
      phone,
    ].any((s) => s.isEmpty)) {
      _showSnackBar('모든 필드를 입력해주세요.');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }

    final success = await UserService.signupUser(
      name: name,
      nickname: nickname,
      email: email,
      password: password,
      phoneNumber: phone,
    );
    if (success) {
      _showSnackBar('회원가입 성공! 🎉');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      _showSnackBar('회원가입 실패. 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '회원가입',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.02),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: h * 0.8),
            child: IntrinsicHeight(
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.06,
                    vertical: h * 0.04,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: h * 0.02),
                      CustomTextField(
                        labelText: '이름',
                        controller: nameController,
                      ),
                      SizedBox(height: h * 0.02),
                      CustomTextField(
                        labelText: '닉네임',
                        controller: nicknameController,
                      ),
                      SizedBox(height: h * 0.02),
                      CustomTextField(
                        labelText: '이메일',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: h * 0.02),
                      CustomTextField(
                        labelText: '비밀번호',
                        controller: passwordController,
                        obscureText: true,
                      ),
                      SizedBox(height: h * 0.02),
                      CustomTextField(
                        labelText: '비밀번호 확인',
                        controller: confirmPasswordController,
                        obscureText: true,
                      ),
                      SizedBox(height: h * 0.02),
                      CustomTextField(
                        labelText: '휴대폰번호',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: h * 0.04),
                      ElevatedButton(
                        onPressed: _submitSignup,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(w * 0.6, 50),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '가입 완료',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
