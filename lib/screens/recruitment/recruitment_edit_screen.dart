import 'package:flutter/material.dart';
import 'package:capstone/services/recruitment_service.dart';

class RecruitmentEditScreen extends StatelessWidget {
  final int recruitmentId;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  RecruitmentEditScreen({super.key, required this.recruitmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('모집글 수정')),
      body: FutureBuilder(
        future: RecruitmentService.getRecruitmentDetail(recruitmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final recruitment = snapshot.data;
            _titleController.text = recruitment.title;
            _contentController.text = recruitment.content;
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: '제목'),
                  ),
                  TextFormField(
                    controller: _contentController,
                    decoration: InputDecoration(labelText: '내용'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        RecruitmentService.updateRecruitment(
                          recruitmentId,
                          _titleController.text,
                          _contentController.text,
                        ).then((_) {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        });
                      }
                    },
                    child: Text('수정'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
