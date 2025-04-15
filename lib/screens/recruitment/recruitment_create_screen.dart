import 'package:flutter/material.dart';
import 'package:capstone/services/recruitment_service.dart';
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
  List<Map<String, dynamic>> _leaderGroups = [];
  Map<String, dynamic>? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _fetchLeaderGroups();
  }

  Future<void> _fetchLeaderGroups() async {
    try {
      final response = await RecruitmentService.requestCreateRecruitment();
      setState(() {
        _leaderGroups = response['data'];
      });
    } catch (e) {
      log("리더 그룹 정보를 불러오는데 실패했습니다: $e");
    }
  }

  Future<void> _submitRecruitment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final recruitGroupId = _selectedGroup?['groupId'];
      if (recruitGroupId == null) {
        throw Exception("그룹을 선택해주세요.");
      }

      final success = await RecruitmentService.createRecruitment(
        recruitGroupId: recruitGroupId,
        title: _titleController.text,
        content: _contentController.text,
      );

      if (success) {
        log('모집글 등록 성공');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('모집글이 등록되었습니다.')));
          Navigator.pop(context, true);
        }
      } else {
        log('모집글 등록 실패');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('모집글 등록에 실패했습니다.')));
        }
      }
    } catch (e) {
      log('모집글 등록 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
