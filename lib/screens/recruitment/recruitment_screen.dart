import 'package:flutter/material.dart';
import 'package:capstone/screens/recruitment/recruitment_create_screen.dart';
import 'package:capstone/screens/recruitment/recruitment_detail_screen.dart';
import 'package:capstone/services/recruitment_service.dart';
import 'dart:developer';
import 'package:capstone/services/group_service.dart';
import 'package:capstone/services/api_helper.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class RecruitmentListScreen extends StatefulWidget {
  const RecruitmentListScreen({super.key});

  @override
  State<RecruitmentListScreen> createState() => _RecruitmentListScreenState();
}

class _RecruitmentListScreenState extends State<RecruitmentListScreen> {
  List<dynamic> recruitments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecruitments();
  }

  Future<void> _loadRecruitments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      recruitments = await RecruitmentService.fetchRecruitments();
      setState(() {});
    } catch (e) {
      log("모집글 정보를 불러오는데 실패했습니다: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모집글 목록')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecruitmentCreateScreen()),
          ).then((_) => _loadRecruitments());
        },
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : recruitments.isEmpty
              ? const Center(child: Text('모집글이 없습니다.'))
              : RefreshIndicator(
                onRefresh: _loadRecruitments,
                child: ListView.builder(
                  itemCount: recruitments.length,
                  itemBuilder: (context, index) {
                    final recruitment = recruitments[index];
                    final createdAt = DateTime.parse(recruitment['createdAt']);
                    final formattedDate = DateFormat(
                      'yyyy년 M월 d일 H시 m분',
                    ).format(createdAt);
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
                            Text('작성일: $formattedDate'),
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
