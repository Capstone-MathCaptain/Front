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
        future: RecruitmentDetailService.getRecruitmentDetail(recruitmentId),
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

class RecruitmentDetailService {
  static Future<List> getRecruitments() async {
    final response = await http.get(Uri.parse('http://baseUrl/recruitment'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load recruitments');
    }
  }

  static Future getRecruitmentDetail(int recruitmentId) async {
    final response = await http.get(
      Uri.parse('http://baseUrl/recruitment/$recruitmentId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load recruitment detail');
    }
  }

  static Future<void> createRecruitment(String title, String content) async {
    final response = await http.post(
      Uri.parse('http://baseUrl/recruitment/create'),
      body: json.encode({'title': title, 'content': content}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create recruitment');
    }
  }

  static Future<void> updateRecruitment(
    int recruitmentId,
    String title,
    String content,
  ) async {
    final response = await http.put(
      Uri.parse('http://baseUrl/recruitment/$recruitmentId'),
      body: json.encode({'title': title, 'content': content}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update recruitment');
    }
  }

  static Future<void> deleteRecruitment(int recruitmentId) async {
    final response = await http.delete(
      Uri.parse('http://baseUrl/recruitment/$recruitmentId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete recruitment');
    }
  }
}
