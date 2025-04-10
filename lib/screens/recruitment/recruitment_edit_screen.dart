import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone/services/api_helper.dart';
import 'package:capstone/services/recruitment_service.dart';
import 'package:capstone/models/recruitment.dart';

class RecruitmentEditScreen extends StatefulWidget {
  final int recruitmentId;
  final String initialCategory;
  final String initialRecruitmentStatus;

  const RecruitmentEditScreen({
    super.key,
    required this.recruitmentId,
    required this.initialCategory,
    required this.initialRecruitmentStatus,
  });

  @override
  _RecruitmentEditScreenState createState() => _RecruitmentEditScreenState();
}

class _RecruitmentEditScreenState extends State<RecruitmentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = '';
  bool _isRecruiting = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _isRecruiting = widget.initialRecruitmentStatus == '모집중';
    _fetchRecruitmentDetail();

    developer.log('📝 모집글 수정 화면 초기화');
    developer.log('🆔 모집글 ID: ${widget.recruitmentId}');
    developer.log('📋 초기 카테고리: $_selectedCategory');
    developer.log('🚩 초기 모집 상태: ${_isRecruiting ? "모집중" : "모집 완료"}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecruitmentDetail() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      developer.log('모집글 세부 정보 가져오기 시작: 모집글 ID ${widget.recruitmentId}');

      final recruitmentData = await RecruitmentService.getRecruitmentDetail(
        widget.recruitmentId,
      );

      if (!mounted) return;

      if (recruitmentData != null) {
        setState(() {
          _titleController.text = recruitmentData['title'] ?? '';
          _contentController.text = recruitmentData['content'] ?? '';
          // initialCategory와 initialRecruitmentStatus는 이미 위젯 파라미터로 설정됨
          developer.log('모집글 세부 정보 로드 완료: ${recruitmentData['title']}');
        });
      } else {
        developer.log('모집글을 찾을 수 없음: ${widget.recruitmentId}');
        _showSnackBar('모집글을 찾을 수 없습니다.');
        Navigator.pop(context);
      }
    } catch (e) {
      developer.log('모집글 세부 정보 가져오기 오류: $e');
      if (mounted) {
        _showSnackBar('모집글 정보를 가져오는 중 오류가 발생했습니다.');
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitEdit() async {
    // 폼 검증
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String recruitmentStatus = _isRecruiting ? '모집중' : '모집 완료';
      developer.log(
        '모집글 수정 - 상태: $recruitmentStatus, 제목: ${_titleController.text}',
      );

      final success = await RecruitmentService.updateRecruitment(
        recruitmentId: widget.recruitmentId,
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
        recruitmentStatus: recruitmentStatus,
      );

      if (success) {
        developer.log('모집글 수정 성공');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('모집글이 수정되었습니다.')));
        Navigator.pop(context, true);
      } else {
        developer.log('모집글 수정 실패');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('모집글 수정에 실패했습니다.')));
      }
    } catch (e) {
      developer.log('모집글 수정 중 오류 발생: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모집글 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 그룹 정보 표시 카드
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '그룹 정보',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.group, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '그룹명: 수정 중...',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              '작성자: 수정 중...',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 모집 상태 스위치 추가
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '모집 상태',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _isRecruiting ? '모집중' : '모집 완료',
                                  style: TextStyle(
                                    color:
                                        _isRecruiting
                                            ? Colors.green
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _isRecruiting,
                                  activeColor: Colors.green,
                                  inactiveTrackColor: Colors.red.withOpacity(
                                    0.5,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _isRecruiting = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 제목 입력
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '모집글 제목을 입력하세요',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '제목을 입력하세요';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 카테고리 선택
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'STUDY', child: Text('스터디')),
                    DropdownMenuItem(value: 'READING', child: Text('독서')),
                    DropdownMenuItem(value: 'WORKOUT', child: Text('운동')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '카테고리를 선택하세요';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 내용 입력
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    hintText: '모집 내용을 자세히 입력하세요',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '내용을 입력하세요';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // 수정하기 버튼
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitEdit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text('수정하기', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
