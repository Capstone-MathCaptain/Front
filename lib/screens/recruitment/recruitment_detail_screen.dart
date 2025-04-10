import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone/services/api_helper.dart';
import 'package:intl/intl.dart';
import 'package:capstone/screens/recruitment/recruitment_edit_screen.dart';
import 'package:capstone/services/recruitment_service.dart';
import 'package:capstone/models/recruitment.dart';

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
  String? currentUserId;
  String? nickname;

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
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      log('📋 모집글 상세 조회 시작 - 모집글ID: ${widget.recruitmentId}');

      // 사용자 정보 가져오기
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userId = prefs.getInt('userId');
      final userNickname = prefs.getString('nickname');

      log('👤 현재 사용자 정보: userId=$userId, nickname=$userNickname');

      if (accessToken == null) {
        _showSnackBar("로그인이 필요합니다");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // 그룹 ID로 매핑된 모집글 ID 확인
      final groupMappingKey = 'group_id_mapping_${widget.recruitmentId}';
      final mappedRecruitmentId = prefs.getInt(groupMappingKey);

      log(
        '🔄 그룹ID로 모집글 조회 시도 - 그룹ID: ${widget.recruitmentId}, 매핑된 모집글ID: $mappedRecruitmentId',
      );

      // 매핑된 모집글 ID가 있으면 사용, 없으면 받은 ID 그대로 사용
      final idToUse = mappedRecruitmentId ?? widget.recruitmentId;
      log(
        '🔍 최종 사용 ID: $idToUse (${mappedRecruitmentId != null ? "그룹ID 매핑에서 찾음" : "원본 ID 사용"})',
      );

      // RecruitmentService를 통해 모집글 상세 정보 조회
      final recruitmentData = await RecruitmentService.getRecruitmentDetail(
        idToUse,
      );

      if (recruitmentData != null) {
        log('✅ 모집글 상세 조회 성공: ${recruitmentData['title']}');
        log('📊 모집글 상세 정보 - 그룹ID: ${recruitmentData['recruitGroupId']}');

        // 현재 사용자가 작성자인지 확인 (닉네임 또는 ID로 비교)
        final authorName = recruitmentData['authorName'] ?? '';
        final isAuthorByNickname =
            userNickname != null && authorName == userNickname;

        setState(() {
          recruitmentDetail = recruitmentData;
          isLoading = false;
          isAuthor = isAuthorByNickname;
          currentUserId = userId?.toString();
          nickname = userNickname;

          log(
            '🔍 작성자 여부 확인: 모집글 작성자="$authorName", 현재 사용자 닉네임="$userNickname", 일치=$isAuthorByNickname',
          );
        });
      } else {
        log('❌ 모집글 상세 조회 실패');
        setState(() {
          isLoading = false;
        });
        _showSnackBar("존재하지 않는 모집글입니다");
      }
    } catch (e) {
      log("❌ 모집글 상세 조회 오류: $e", error: e);
      setState(() {
        isLoading = false;
      });
      _showSnackBar("네트워크 오류 발생: $e");
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) {
      _showSnackBar("댓글 내용을 입력해주세요");
      return;
    }

    try {
      await RecruitmentService.createComment(
        widget.recruitmentId,
        _commentController.text,
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

    if (content.length > 300) {
      _showSnackBar("댓글은 최대 300자까지 입력 가능합니다.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString("access_token");

    if (accessToken == null) {
      _showSnackBar("로그인이 필요합니다.");
      return;
    }

    final url = Uri.parse(
      "${ApiHelper.baseUrl}/recruitment/comment/${widget.recruitmentId}/$commentId",
    );
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    };
    final body = jsonEncode({"content": content});

    try {
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        _showSnackBar("댓글이 수정되었습니다.");
        _fetchRecruitmentDetail();
      } else {
        _showSnackBar("댓글 수정에 실패했습니다: ${response.statusCode}");
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

    final url = Uri.parse(
      "${ApiHelper.baseUrl}/recruitment/comment/${widget.recruitmentId}/$commentId",
    );
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    };

    try {
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        _showSnackBar("댓글이 삭제되었습니다.");
        _fetchRecruitmentDetail();
      } else {
        _showSnackBar("댓글 삭제에 실패했습니다: ${response.statusCode}");
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

  void _showDeleteConfirmDialog() {
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'STUDY':
        return Icons.school;
      case 'READING':
        return Icons.book;
      case 'WORKOUT':
        return Icons.fitness_center;
      default:
        return Icons.group;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'STUDY':
        return '공부';
      case 'READING':
        return '독서';
      case 'WORKOUT':
        return '운동';
      default:
        return '기타';
    }
  }

  Future<void> _deleteRecruitment() async {
    try {
      log("📌 모집글 삭제 시작 - 모집글ID: ${widget.recruitmentId}");

      final bool result = await RecruitmentService.deleteRecruitment(
        widget.recruitmentId,
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

  Future<void> _navigateToEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RecruitmentEditScreen(
              recruitmentId: widget.recruitmentId,
              initialCategory: recruitmentDetail['category'] ?? 'STUDY',
              initialRecruitmentStatus:
                  recruitmentDetail['recruitmentStatus'] == 'RECRUITING'
                      ? '모집중'
                      : '모집 완료',
            ),
      ),
    );

    if (result == true && mounted) {
      _fetchRecruitmentDetail();
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
                      _navigateToEditScreen();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmDialog(),
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
                                    '${recruitmentDetail['recruitGroupName'] ?? '그룹명 없음'} 그룹',
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
                              nickname != null && commentAuthor == nickname;

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
        title: recruitmentDetail['title'] ?? '',
        content: recruitmentDetail['content'] ?? '',
        category: recruitmentDetail['category'] ?? 'STUDY',
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
