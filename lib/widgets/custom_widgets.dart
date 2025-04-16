import 'package:flutter/material.dart';
import 'package:capstone/screens/recruitment/recruitment_detail_screen.dart';
import 'package:capstone/services/recruitment_service.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final void Function(String)? onSubmitted;

  const CustomTextField({
    required this.labelText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onSubmitted, // ✅ 생성자에 추가
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: onSubmitted, // ✅ onSubmitted 추가
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({required this.text, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }
}

class RecruitmentOverviewWidget extends StatelessWidget {
  const RecruitmentOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('모집글')),
      body: FutureBuilder(
        future: RecruitmentService.fetchRecruitments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final recruitments = snapshot.data;
            return ListView.builder(
              itemCount: recruitments?.length ?? 0,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(recruitments?[index].title ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => RecruitmentDetailScreen(
                              recruitmentId:
                                  recruitments?[index].recruitmentId ?? 0,
                            ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 그룹장만 접근 가능하도록 조건 추가
          Navigator.pushNamed(context, '/recruitment/create');
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
