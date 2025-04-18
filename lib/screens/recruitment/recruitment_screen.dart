import 'package:flutter/material.dart';
import 'package:capstone/screens/recruitment/recruitment_create_screen.dart';
import 'package:capstone/screens/recruitment/recruitment_detail_screen.dart';
import 'package:capstone/services/recruitment_service.dart';
import 'dart:developer';
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
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 카테고리 아이콘 + 텍스트
                              Row(
                                children: [
                                  Icon(
                                    recruitment['category'] == '공부'
                                        ? Icons.school
                                        : recruitment['category'] == '헬스'
                                        ? Icons.fitness_center
                                        : Icons.directions_run,
                                    size: 18,
                                    color: Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    recruitment['category'],
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // 제목 + 그룹명 + 상태표시
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            recruitment['title'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          recruitment['recruitGroupName'],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          recruitment['recruitmentStatus'] ==
                                                  '모집중'
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // 본문 미리보기
                              Text(
                                recruitment['content'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),

                              const SizedBox(height: 12),

                              // 작성일
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
