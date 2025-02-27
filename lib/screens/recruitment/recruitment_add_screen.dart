import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecruitmentAddScreen extends StatefulWidget {
  const RecruitmentAddScreen({super.key});

  @override
  State<RecruitmentAddScreen> createState() => _RecruitmentAddScreenState();
}

class _RecruitmentAddScreenState extends State<RecruitmentAddScreen> {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupLevelController = TextEditingController();
  final TextEditingController participantCountController =
      TextEditingController();
  final TextEditingController groupTopicController = TextEditingController();
  final TextEditingController groupLeaderController = TextEditingController();

  void _submitRecruitment() async {
    final String groupName = groupNameController.text;
    final String groupLevel = groupLevelController.text;
    final String participantCount = participantCountController.text;
    final String groupTopic = groupTopicController.text;
    final String groupLeader = groupLeaderController.text;

    if (groupName.isEmpty ||
        groupLevel.isEmpty ||
        participantCount.isEmpty ||
        groupTopic.isEmpty ||
        groupLeader.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 필드를 입력해주세요.')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString("access_token");

    if (accessToken == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    const String apiUrl =
        'http://localhost:8080/recruitments'; // 모집글 작성 API URL
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    };

    final body = jsonEncode({
      'groupName': groupName,
      'groupLevel': groupLevel,
      'participantCount': participantCount,
      'groupTopic': groupTopic,
      'groupLeader': groupLeader,
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('모집글이 성공적으로 작성되었습니다.')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('모집글 작성 실패: ${response.body}')));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('네트워크 오류 발생: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모집글 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: groupNameController,
              decoration: const InputDecoration(labelText: '그룹 이름'),
            ),
            TextField(
              controller: groupLevelController,
              decoration: const InputDecoration(labelText: '그룹 레벨'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: participantCountController,
              decoration: const InputDecoration(labelText: '참여자 수'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: groupTopicController,
              decoration: const InputDecoration(labelText: '그룹 주제'),
            ),
            TextField(
              controller: groupLeaderController,
              decoration: const InputDecoration(labelText: '그룹장'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitRecruitment,
              child: const Text('제출'),
            ),
          ],
        ),
      ),
    );
  }
}
