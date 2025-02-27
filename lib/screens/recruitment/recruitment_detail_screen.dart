import 'package:flutter/material.dart';
import 'package:capstone/widgets/recruitment_comment_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecruitmentDetailScreen extends StatelessWidget {
  final int recruitmentId;

  const RecruitmentDetailScreen({super.key, required this.recruitmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('모집글 상세')),
      body: FutureBuilder(
        future: RecruitmentService.getRecruitmentDetail(recruitmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final recruitment = snapshot.data;
            return Column(
              children: [
                Text(recruitment.title),
                Text(recruitment.content),
                CommentWidget(recruitmentId: recruitmentId),
              ],
            );
          }
        },
      ),
    );
  }
}

class RecruitmentService {
  static Future<List> getRecruitments() async {
    final response = await http.get(
      Uri.parse('https://api.example.com/recruitment'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load recruitments');
    }
  }

  static Future getRecruitmentDetail(int id) async {
    final response = await http.get(
      Uri.parse('https://api.example.com/recruitment/$id'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load recruitment detail');
    }
  }

  // 추가적인 서비스 메소드들 (작성, 수정, 삭제 등)
}
