import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone/services/recruitment_service.dart';
import 'package:capstone/services/group_join_service.dart';
import 'package:intl/intl.dart';

class RecruitmentDetailScreen extends StatefulWidget {
  final int recruitmentId;

  const RecruitmentDetailScreen({super.key, required this.recruitmentId});

  @override
  State<RecruitmentDetailScreen> createState() =>
      _RecruitmentDetailScreenState();
}

class _RecruitmentDetailScreenState extends State<RecruitmentDetailScreen> {
  bool isLoading = true;
  bool isAuthor = false;

  String? userName;
  String? userNickname;
  int? currentUserId;

  Map<String, dynamic> recruitmentDetail = {};
  //* 댓글 수정 필드
  TextEditingController _commentController = TextEditingController();
  TextEditingController _editCommentController = TextEditingController();

  //* 가입 요청 목표 입력 필드
  final TextEditingController _joinDailyController = TextEditingController();
  final TextEditingController _joinWeeklyController = TextEditingController();

  //* 모집글 수정 필드
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _editCommentController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getInt('userId');
      await _fetchRecruitmentDetail();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editCommentController.dispose();
    _joinDailyController.dispose();
    _joinWeeklyController.dispose();
    super.dispose();
  }

  //* 모집글 상세 정보 가져오기
  Future<void> _fetchRecruitmentDetail() async {
    try {
      final response = await RecruitmentService.fetchDetailRecruitments(
        widget.recruitmentId,
      );
      setState(() {
        recruitmentDetail = Map<String, dynamic>.from(response);
        isAuthor = recruitmentDetail['author'] ?? false;
        isLoading = false;
      });
      // await _fetchUserInfo();
    } catch (e) {
      log("모집글 정보를 불러오는데 실패했습니다: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateRecruitment(
    String title,
    String content,
    String category,
    String recruitmentStatus,
  ) async {
    try {
      final success = await RecruitmentService.updateRecruitment(
        recruitmentId: widget.recruitmentId,
        authorId: recruitmentDetail['authorId'] ?? 0,
        recruitGroupId: recruitmentDetail['recruitGroupId'] ?? 0,
        title: title,
        content: content,
        recruitmentStatus: recruitmentStatus,
      );

      if (success) {
        _showSnackBar("모집글이 수정되었습니다.");
        _fetchRecruitmentDetail();
      } else {
        _showSnackBar("모집글 수정에 실패했습니다.");
      }
    } catch (e) {
      _showSnackBar("네트워크 오류 발생: $e");
    }
  }

  Future<void> _deleteRecruitment() async {
    try {
      final bool result = await RecruitmentService.deleteRecruitment(
        recruitmentId: widget.recruitmentId,
      );

      if (result) {
        log("✅ 모집글 삭제 성공");
        _showSnackBar("모집글이 삭제되었습니다.");
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        log("❌ 모집글 삭제 실패");
        _showSnackBar("모집글 삭제에 실패했습니다.");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      _showSnackBar("네트워크 오류 발생: $e");
    }
  }

  void _showEditRecruitmentDialog() {
    _titleController.text = recruitmentDetail['title'] ?? '변경할 제목을 입력하시오.';
    _contentController.text = recruitmentDetail['content'] ?? '변경할 내용을 입력하시오.';
    _categoryController.text = recruitmentDetail['category'] ?? 'STUDY';
    _statusController.text = recruitmentDetail['recruitmentStatus'] ?? '모집중';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('모집글 수정'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: '내용',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: '카테고리',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _statusController,
                    decoration: const InputDecoration(
                      labelText: '상태',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateRecruitment(
                    _titleController.text,
                    _contentController.text,
                    _categoryController.text,
                    _statusController.text,
                  );
                },
                child: const Text('수정'),
              ),
            ],
          ),
    );
  }

  void _showDeleteRecruitmentConfirmDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('모집글 삭제'),
            content: const Text('모집글을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('아니오'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteRecruitment();
                },
                child: const Text('예', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) {
      _showSnackBar("댓글 내용을 입력해주세요");
      return;
    }

    try {
      await RecruitmentService.createComment(
        recruitmentId: widget.recruitmentId,
        content: _commentController.text,
      );
      _commentController.clear();
      _showSnackBar("댓글이 등록되었습니다.");
      _fetchRecruitmentDetail();
    } catch (e) {
      _showSnackBar("댓글 등록에 실패했습니다: $e");
    }
  }

  Future<void> _updateComment(int commentId, String content) async {
    if (content.trim().isEmpty) {
      _showSnackBar("댓글 내용을 입력하세요.");
      return;
    }

    if (content.length > 1000) {
      _showSnackBar("댓글은 최대 1000자까지 입력 가능합니다.");
      return;
    }

    try {
      final success = await RecruitmentService.updateComment(
        recruitmentId: widget.recruitmentId,
        commentId: commentId,
        content: content,
      );

      if (success) {
        _showSnackBar("댓글이 수정되었습니다.");
        _fetchRecruitmentDetail();
      } else {
        _showSnackBar("댓글 수정에 실패했습니다.");
      }
    } catch (e) {
      _showSnackBar("네트워크 오류 발생: $e");
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString("access_token");

    if (accessToken == null) {
      _showSnackBar("로그인이 필요합니다.");
      return;
    }

    try {
      final success = await RecruitmentService.deleteComment(
        recruitmentId: widget.recruitmentId,
        commentId: commentId,
      );

      if (success) {
        _showSnackBar("댓글이 삭제되었습니다.");
        _fetchRecruitmentDetail();
      } else {
        _showSnackBar("댓글 삭제에 실패했습니다.");
      }
    } catch (e) {
      _showSnackBar("네트워크 오류 발생: $e");
    }
  }

  void _showEditCommentDialog(int commentId, String currentContent) {
    _editCommentController.text = currentContent;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('댓글 수정'),
            content: TextField(
              controller: _editCommentController,
              decoration: const InputDecoration(
                hintText: '수정할 댓글 내용을 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              maxLength: 300,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateComment(commentId, _editCommentController.text);
                },
                child: const Text('수정'),
              ),
            ],
          ),
    );
  }

  void _showDeleteCommentDialog(int commentId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('댓글 삭제'),
            content: const Text('이 댓글을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteComment(commentId);
                },
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return; // 마운트 상태 확인

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _normalizeStatus(String? status) {
    switch (status) {
      case '모집중':
        return 'RECRUITING';
      case '모집 완료':
      case '모집완료':
        return 'COMPLETED';
      default:
        return status?.toUpperCase() ?? '';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모집글 상세'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
        foregroundColor: Colors.black,
        actions:
            isAuthor
                ? [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showEditRecruitmentDialog();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteRecruitmentConfirmDialog(),
                  ),
                ]
                : null,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Detail content
                    Expanded(
                      flex: 2,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 헤더 정보 (제목, 카테고리, 모집 상태)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${recruitmentDetail['title']}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                recruitmentDetail['category'] ??
                                                    '카테고리 없음',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '그룹명: ${recruitmentDetail['recruitGroupName']?.toString() ?? '그룹명 없음'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 모집 상태 표시
                                  Column(
                                    children: [
                                      Text(
                                        '모집 상태',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _getRecruitmentStatusColor(
                                                _normalizeStatus(
                                                  recruitmentDetail['recruitmentStatus'],
                                                ),
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getRecruitmentStatusText(
                                              _normalizeStatus(
                                                recruitmentDetail['recruitmentStatus'],
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _getRecruitmentStatusColor(
                                                _normalizeStatus(
                                                  recruitmentDetail['recruitmentStatus'],
                                                ),
                                              ),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isAuthor)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: GestureDetector(
                                            onTap:
                                                () =>
                                                    _toggleRecruitmentStatus(),
                                            child: Text(
                                              '상태 변경',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // 작성자 정보 및 날짜
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        recruitmentDetail['authorName'] ??
                                            '작성자 없음',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _formatDate(recruitmentDetail['createdAt']),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),

                              // 본문 내용
                              Text(
                                recruitmentDetail['content'] ?? '내용 없음',
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _joinDailyController.text = '';
                                    _joinWeeklyController.text = '';
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            insetPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 24,
                                                  vertical: 24,
                                                ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '가입 요청 목표 입력',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  TextField(
                                                    controller:
                                                        _joinDailyController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: InputDecoration(
                                                      labelText: '일간 목표 (시간)',
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  TextField(
                                                    controller:
                                                        _joinWeeklyController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: InputDecoration(
                                                      labelText: '주간 목표 (일수)',
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text('취소'),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          try {
                                                            final success = await GroupJoinService.joinGroup(
                                                              groupId:
                                                                  recruitmentDetail['recruitGroupId'] ??
                                                                  0,
                                                              request: GroupJoinRequest(
                                                                personalDailyGoal:
                                                                    int.parse(
                                                                      _joinDailyController
                                                                          .text,
                                                                    ),
                                                                personalWeeklyGoal:
                                                                    int.parse(
                                                                      _joinWeeklyController
                                                                          .text,
                                                                    ),
                                                              ),
                                                            );
                                                            if (success) {
                                                              _showSnackBar(
                                                                '그룹 가입 요청이 전송되었습니다.',
                                                              );
                                                            } else {
                                                              _showSnackBar(
                                                                '가입 요청에 실패했습니다.',
                                                              );
                                                            }
                                                          } catch (e) {
                                                            _showSnackBar(
                                                              '가입 요청 중 오류 발생: $e',
                                                            );
                                                          }
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                0xFF3A86FF,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 20,
                                                                vertical: 12,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          '확인',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3A86FF),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '가입',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // comments section
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.only(top: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '댓글 ${(recruitmentDetail['comments'] as List?)?.length ?? 0}개',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  itemCount:
                                      (recruitmentDetail['comments'] as List?)
                                          ?.length ??
                                      0,
                                  itemBuilder: (context, index) {
                                    final comment =
                                        recruitmentDetail['comments'][index];
                                    return Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      padding: const EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                comment['authorName'] ??
                                                    '알 수 없음',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                _formatDate(
                                                  comment['createdAt'],
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            comment['content'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const Divider(height: 1, color: Colors.grey),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _commentController,
                                        maxLines: 1,
                                        decoration: InputDecoration(
                                          hintText: '댓글을 입력하세요',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _postComment,
                                      child: const Text('등록'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // 모집 상태 색상 반환
  Color _getRecruitmentStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toUpperCase()) {
      case 'RECRUITING':
        return Colors.green;
      case 'COMPLETED':
      case 'CLOSED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 모집 상태 텍스트 반환
  String _getRecruitmentStatusText(String? status) {
    if (status == null) return '알 수 없음';

    switch (status.toUpperCase()) {
      case 'RECRUITING':
        return '모집중';
      case 'COMPLETED':
      case 'CLOSED':
        return '모집 완료';
      default:
        return status;
    }
  }

  // 모집 상태 토글
  Future<void> _toggleRecruitmentStatus() async {
    final currentStatus =
        (recruitmentDetail['recruitmentStatus'] ?? '').toUpperCase();
    final newStatus =
        currentStatus == 'RECRUITING' ? 'COMPLETED' : 'RECRUITING';

    try {
      // 모집 상태 변경 API 호출
      await RecruitmentService.updateRecruitment(
        recruitmentId: widget.recruitmentId,
        authorId: recruitmentDetail['authorId'],
        recruitGroupId: recruitmentDetail['recruitGroupId'],
        title: recruitmentDetail['title'] ?? '수정할 제목을 입력하시요.',
        content: recruitmentDetail['content'] ?? '수정할 내용을 입력하시요.',
        recruitmentStatus: newStatus == 'RECRUITING' ? '모집중' : '모집 완료',
      );

      _showSnackBar("모집 상태가 변경되었습니다.");

      // UI 업데이트
      setState(() {
        recruitmentDetail['recruitmentStatus'] = newStatus;
      });
    } catch (e) {
      _showSnackBar("모집 상태 변경에 실패했습니다: $e");
    }
  }
}
