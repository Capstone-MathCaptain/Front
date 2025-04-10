import 'package:flutter/material.dart';
import 'package:capstone/services/recruitment_service.dart';
import 'package:capstone/services/user_service.dart';
import 'package:capstone/models/user.dart';
import 'package:capstone/services/api_helper.dart';
import 'dart:developer';

class RecruitmentCreateScreen extends StatefulWidget {
  const RecruitmentCreateScreen({super.key});

  @override
  State<RecruitmentCreateScreen> createState() =>
      _RecruitmentCreateScreenState();
}

class _RecruitmentCreateScreenState extends State<RecruitmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  User? _currentUser;
  List<Map<String, dynamic>> _leaderGroups = [];
  Map<String, dynamic>? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isSubmitting = true; // 로딩 중 표시
      });

      log('🔄 모집글 작성 화면 - 데이터 로드 시작');

      // 토큰 갱신 시도
      await ApiHelper.checkAndRefreshToken();
      log('✅ 토큰 갱신 완료');

      final user = await UserService.getCurrentUser();
      if (user == null) {
        log('⚠️ 사용자 정보 없음 - 로그인 필요');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 정보를 가져올 수 없습니다. 다시 로그인해주세요.')),
          );
          Navigator.pop(context);
        }
        return;
      }

      log(
        '👤 현재 사용자: ${user.nickname} (ID: ${user.userId}), 전체 정보: ${user.toJson()}',
      );

      log('📋 리더 그룹 조회 시작');
      final groups = await RecruitmentService.getLeaderGroups();
      log('📋 리더 그룹 조회 결과: ${groups.length}개');

      if (groups.isEmpty) {
        log('⚠️ 리더 그룹이 없습니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('리더로 있는 그룹이 없습니다. 그룹을 생성한 후 모집글을 작성해주세요.'),
            ),
          );
        }
      } else {
        log('📋 리더 그룹 목록:');
        for (int i = 0; i < groups.length; i++) {
          log(
            '  ${i + 1}. ${groups[i]['groupName']} (ID: ${groups[i]['groupId']})',
          );
        }
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _leaderGroups = groups;
          _isSubmitting = false; // 로딩 완료

          // 그룹이 하나만 있으면 자동 선택
          if (_leaderGroups.length == 1) {
            _selectedGroup = _leaderGroups.first;
            log('✅ 그룹 자동 선택: ${_selectedGroup?['groupName']}');
          }
        });
      }
    } catch (e) {
      log('❌ 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 로드 실패: $e')));
      }
    }
  }

  Future<void> _submitRecruitment() async {
    if (!_formKey.currentState!.validate() || _selectedGroup == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final recruitmentId = await RecruitmentService.createRecruitment(
        recruitGroupId: _selectedGroup!['groupId'],
        title: _titleController.text,
        content: _contentController.text,
        authorName: _currentUser?.nickname ?? '',
        authorUid: _currentUser?.email ?? '',
        authorId: _currentUser?.userId ?? 0,
        category: _selectedGroup!['category'] ?? 'STUDY',
        recruitGroupName: _selectedGroup!['groupName'] ?? '',
        recruitmentStatus: 'RECRUITING',
      );

      if (recruitmentId != null && mounted) {
        Navigator.pop(context, true);
      } else {
        throw Exception('모집글 작성 실패');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('모집글 작성 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모집글 작성')),
      body:
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_leaderGroups.isEmpty)
                          const Card(
                            margin: EdgeInsets.only(bottom: 16),
                            color: Colors.amber,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                '모집글을 작성하려면 리더로 있는 그룹이 필요합니다. 새 그룹을 생성해주세요.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedGroup,
                          decoration: const InputDecoration(
                            labelText: '그룹 선택',
                            border: OutlineInputBorder(),
                            hintText: '리더로 있는 그룹을 선택해주세요',
                          ),
                          items:
                              _leaderGroups.map((group) {
                                return DropdownMenuItem(
                                  value: group,
                                  child: Text(
                                    '${group['groupName']} (${group['category']})',
                                  ),
                                );
                              }).toList(),
                          onChanged:
                              _leaderGroups.isEmpty
                                  ? null
                                  : (value) {
                                    setState(() {
                                      _selectedGroup = value;
                                    });
                                  },
                          validator: (value) {
                            if (value == null) {
                              return '그룹을 선택해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: '제목',
                            border: OutlineInputBorder(),
                            hintText: '모집글 제목을 입력해주세요',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '제목을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contentController,
                          decoration: const InputDecoration(
                            labelText: '내용',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                            hintText: '모집 내용을 상세히 입력해주세요',
                          ),
                          maxLines: 10,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '내용을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed:
                              (_leaderGroups.isEmpty || _isSubmitting)
                                  ? null
                                  : _submitRecruitment,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child:
                              _isSubmitting
                                  ? const CircularProgressIndicator()
                                  : const Text(
                                    '모집글 등록',
                                    style: TextStyle(fontSize: 16),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
