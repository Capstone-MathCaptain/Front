import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone/services/recruitment_service.dart';
import 'package:capstone/services/user_service.dart';
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
  Map<String, dynamic> recruitmentDetail = {};
  TextEditingController _commentController = TextEditingController();
  TextEditingController _editCommentController = TextEditingController();
  bool isAuthor = false;
  String? userName;
  String? userNickname;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _editCommentController = TextEditingController();

    // 메인 UI 빌드 후 데이터 로딩 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecruitmentDetail();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editCommentController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecruitmentDetail() async {
    try {
      final response = await RecruitmentService.fetchDetailRecruitments(
        widget.recruitmentId,
      );
      setState(() {
        recruitmentDetail = response['data'];
        isLoading = false;
      });
      await _fetchUserInfo();
    } catch (e) {
      log("모집글 정보를 불러오는데 실패했습니다: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        log("userId를 불러오는데 실패했습니다.");
        return;
      }

      final userInfo = await UserService.getUserInfo(userId: userId);
      userName = userInfo['name'];
      userNickname = userInfo['nickname'];

      setState(() {
        isAuthor =
            recruitmentDetail['authorName'] == userName ||
            recruitmentDetail['authorName'] == userNickname;
      });
    } catch (e) {
      log("작성자 확인 중 오류 발생: $e");
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
        authorId: recruitmentDetail['authorId'],
        recruitGroupId: recruitmentDetail['recruitGroupId'],
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recruitmentDetail['title'] ?? '제목 없음',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      recruitmentDetail['category'] ??
                                          '카테고리 없음',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '그룹명: ${recruitmentDetail['recruitGroupName'] ?? '그룹명 없음'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
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
                                      recruitmentDetail['recruitmentStatus'],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getRecruitmentStatusText(
                                    recruitmentDetail['recruitmentStatus'],
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _getRecruitmentStatusColor(
                                      recruitmentDetail['recruitmentStatus'],
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (isAuthor)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: GestureDetector(
                                  onTap: () => _toggleRecruitmentStatus(),
                                  child: Text(
                                    '상태 변경',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              recruitmentDetail['authorName'] ?? '작성자 없음',
                              style: const TextStyle(color: Colors.grey),
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
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 댓글 섹션
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '댓글 ${(recruitmentDetail['comments'] as List?)?.length ?? 0}개',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 댓글 입력
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            maxLines: 3,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: '댓글을 입력하세요',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _postComment,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('등록'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 댓글 목록
                    if ((recruitmentDetail['comments'] as List?)?.isNotEmpty ??
                        false)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            (recruitmentDetail['comments'] as List).length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final comment =
                              (recruitmentDetail['comments'] as List)[index];
                          final commentAuthor =
                              comment['authorName'] ?? '알 수 없음';
                          final isCommentAuthor =
                              (userName != null && commentAuthor == userName) ||
                              (userNickname != null &&
                                  commentAuthor == userNickname);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person_outline,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          commentAuthor,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          _formatDate(comment['createdAt']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (isCommentAuthor)
                                          Row(
                                            children: [
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap:
                                                    () =>
                                                        _showEditCommentDialog(
                                                          comment['commentId'],
                                                          comment['content'],
                                                        ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap:
                                                    () =>
                                                        _showDeleteCommentDialog(
                                                          comment['commentId'],
                                                        ),
                                                child: const Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(comment['content'] ?? ''),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            '아직 댓글이 없습니다. 첫 댓글을 남겨보세요!',
                            style: TextStyle(color: Colors.grey),
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
