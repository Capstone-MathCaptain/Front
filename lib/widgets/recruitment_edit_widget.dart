import 'package:flutter/material.dart';
import 'package:capstone/services/recruitment_service.dart';

class CommentEditWidget extends StatelessWidget {
  final int recruitmentId;
  final int commentId;
  final _contentController = TextEditingController();

  CommentEditWidget({
    super.key,
    required this.recruitmentId,
    required this.commentId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _contentController,
          decoration: InputDecoration(labelText: '댓글 내용'),
        ),
        ElevatedButton(
          onPressed: () {
            RecruitmentService.updateComment(
              recruitmentId,
              commentId,
              _contentController.text,
            ).then((_) {
              if (context.mounted) {
                Navigator.pop(context);
              }
            });
          },
          child: Text('수정'),
        ),
      ],
    );
  }
}
