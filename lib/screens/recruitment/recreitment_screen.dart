import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone/screens/recruitment/recruitment_add_screen.dart';

class RecruitmentListScreen extends StatefulWidget {
  const RecruitmentListScreen({super.key});

  @override
  State<RecruitmentListScreen> createState() => _RecruitmentListScreenState();
}

class _RecruitmentListScreenState extends State<RecruitmentListScreen> {
  List<dynamic> recruitmentPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecruitmentPosts();
  }

  Future<void> _fetchRecruitmentPosts() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString("access_token");

    if (accessToken == null) {
      _showSnackBar("로그인이 필요합니다.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse("http://baseUrl/recruitments");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        setState(() {
          recruitmentPosts = jsonDecode(response.body)['data'];
        });
      } else {
        _showSnackBar("모집글을 불러오지 못했습니다.");
      }
    } catch (e) {
      _showSnackBar("네트워크 오류 발생: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모집글 조회')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: recruitmentPosts.length,
                itemBuilder: (context, index) {
                  final post = recruitmentPosts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: ListTile(
                      title: Text(post['groupName']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('그룹 레벨: ${post['groupLevel']}'),
                          Text('참여자 수: ${post['participantCount']}명'),
                          Text('그룹 주제: ${post['groupTopic']}'),
                          Text('그룹장: ${post['groupLeader']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecruitmentAddScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
