// ... existing code ...
import 'package:flutter/material.dart';
import 'package:capstone/services/recruitment_service.dart';

class RecruitmentCreateScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  RecruitmentCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('모집글 작성')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: '제목'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '제목을 입력하세요';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(labelText: '내용'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '내용을 입력하세요';
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  RecruitmentService.createRecruitment(
                    _titleController.text,
                    _contentController.text,
                  ).then((_) {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  });
                }
              },
              child: Text('작성'),
            ),
          ],
        ),
      ),
    );
  }
}
