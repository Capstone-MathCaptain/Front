import 'package:flutter/material.dart';
import 'package:capstone/screens/recruitment/recruitment_create_screen.dart';
import 'package:capstone/screens/recruitment/recruitment_detail_screen.dart';
import 'package:capstone/services/recruitment_service.dart';
import 'dart:developer';
import 'package:capstone/services/group_service.dart';
import 'package:capstone/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecruitmentListScreen extends StatefulWidget {
  const RecruitmentListScreen({super.key});

  @override
  State<RecruitmentListScreen> createState() => _RecruitmentListScreenState();
}

class _RecruitmentListScreenState extends State<RecruitmentListScreen> {
  List<dynamic> _recruitments = [];
  bool _isLoading = false;
  bool canCreateRecruitment = false;

  @override
  void initState() {
    super.initState();
    _loadRecruitments();
    _checkUserGroupLeader();
  }

  Future<void> _loadRecruitments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recruitments = await RecruitmentService.fetchRecruitments();
      setState(() {
        _recruitments = recruitments;
      });
    } catch (e) {
      log("모집글 정보를 불러오는데 실패했습니다: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //현재 유저가 리더로 있는 그룹이 있는지 판별
  Future<void> _checkUserGroupLeader() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId'); // 저장된 userId 불러오기

      if (userId == null) {
        log("userId를 불러오는데 실패했습니다.");
        return;
      }

      final userInfo = await UserService.getUserInfo(userId: userId);
      final userName = userInfo['name'];
      final userNickname = userInfo['nickname'];

      final userGroups = await GroupService.fetchUserGroups();
      for (var group in userGroups) {
        if (group['leaderName'] == userName ||
            group['leaderName'] == userNickname) {
          setState(() {
            canCreateRecruitment = true;
          });
          break;
        }
      }
    } catch (e) {
      log("사용자 정보를 확인하는데 실패했습니다: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모집글 목록')),
      floatingActionButton: FloatingActionButton(
        onPressed:
            canCreateRecruitment
                ? () {
                  // 모집글 생성 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecruitmentCreateScreen(),
                    ),
                  ).then((_) => _loadRecruitments());
                }
                : () {
                  // 모집글 작성 불가 메시지 표시
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('모집글을 작성할 수 있는 그룹이 없습니다. 먼저 그룹을 생성해주세요.'),
                    ),
                  );
                },
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recruitments.isEmpty
              ? const Center(child: Text('모집글이 없습니다.'))
              : RefreshIndicator(
                onRefresh: RecruitmentService.fetchRecruitments,
                child: ListView.builder(
                  itemCount: _recruitments.length,
                  itemBuilder: (context, index) {
                    final recruitment = _recruitments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(recruitment['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('작성자: ${recruitment['authorName']}'),
                            Text('그룹명: ${recruitment['recruitGroupName']}'),
                            Text('카테고리: ${recruitment['category']}'),
                            Text('상태: ${recruitment['recruitmentStatus']}'),
                            Text('작성일: ${recruitment['createdAt']}'),
                          ],
                        ),
                        onTap: () {
                          // 모집글 상세 화면으로 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => RecruitmentDetailScreen(
                                    recruitmentId: recruitment['recruitmentId'],
                                  ),
                            ),
                          ).then((_) => _loadRecruitments());
                        },
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
