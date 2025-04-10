import 'package:flutter/material.dart';
import 'package:capstone/screens/recruitment/recruitment_create_screen.dart';
import 'package:capstone/screens/recruitment/recruitment_detail_screen.dart';
import 'package:capstone/services/recruitment_service.dart';
import 'package:capstone/models/recruitment.dart';
import 'package:capstone/services/group_service.dart';
import 'package:capstone/models/group.dart';
import 'package:capstone/services/user_service.dart';
import 'package:capstone/models/user.dart';
import 'package:capstone/services/api_helper.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecruitmentListScreen extends StatefulWidget {
  const RecruitmentListScreen({super.key});

  @override
  State<RecruitmentListScreen> createState() => _RecruitmentListScreenState();
}

class _RecruitmentListScreenState extends State<RecruitmentListScreen> {
  List<Recruitment> _recruitments = [];
  bool _isLoading = true;
  String? _error;
  User? _currentUser;
  List<Group> _userGroups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      log('데이터 로드 시작...');

      // 토큰 갱신 시도
      log('토큰 갱신 시도 중...');
      final tokenResult = await ApiHelper.checkAndRefreshToken();
      log('토큰 갱신 결과: $tokenResult');

      // SharedPreferences에서 토큰 및 userId 확인
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userId = prefs.getInt('userId');
      log('저장된 토큰: ${accessToken != null ? "있음" : "없음"}');
      log('저장된 userId: $userId');

      // 현재 로그인한 사용자 정보 가져오기
      log('사용자 정보 요청 시작...');
      _currentUser = await UserService.getCurrentUser();
      log('사용자 정보 응답: ${_currentUser != null ? "성공" : "실패"}');
      log(
        '현재 사용자: ${_currentUser != null ? "ID: ${_currentUser!.userId}, 닉네임: ${_currentUser!.nickname}" : "null"}',
      ); // User 객체의 기본 정보 출력

      // 사용자가 리더인 그룹 목록 가져오기
      log('사용자 그룹 요청 시작...');
      _userGroups = await GroupService.getUserGroups();
      log('사용자 그룹 응답: ${_userGroups.length}개 그룹 발견');
      for (var group in _userGroups) {
        log(
          '그룹 정보: ID=${group.groupId}, 이름=${group.groupName}, 카테고리=${group.category}',
        );
      }

      // 모집글 목록 가져오기
      final recruitments = await RecruitmentService.getRecruitments();
      log('모집글 목록 응답: ${recruitments.length}개 모집글 발견');

      if (mounted) {
        setState(() {
          _recruitments = recruitments;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('데이터 로드 실패: $e'); // 디버깅용 로그
      log('에러 StackTrace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모집글 목록')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 모집글 생성 버튼 클릭 시 로그 추가
          log('모집글 생성 버튼 클릭됨');
          log('현재 사용자: ${_currentUser?.nickname ?? "로그인 필요"}');
          log('사용자 그룹 수: ${_userGroups.length}');

          // 사용자 로그인 상태 확인
          if (_currentUser == null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
            return;
          }

          // 사용자 그룹 확인
          if (_userGroups.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('작성 가능한 그룹이 없습니다. 그룹을 먼저 생성해주세요.')),
            );
            return;
          }

          // 모집글 생성 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecruitmentCreateScreen(),
            ),
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('오류: $_error'))
              : _recruitments.isEmpty
              ? const Center(child: Text('모집글이 없습니다.'))
              : RefreshIndicator(
                onRefresh: _loadData,
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
                        title: Text(recruitment.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('작성자: ${recruitment.authorName}'),
                            Text('그룹: ${recruitment.recruitGroupName}'),
                            Text('카테고리: ${recruitment.category}'),
                            Text('상태: ${recruitment.recruitmentStatus}'),
                            Text('작성일: ${recruitment.createdAt}'),
                          ],
                        ),
                        onTap: () async {
                          // 모집글 클릭 시 상세 정보 로깅
                          int recruitmentId = recruitment.recruitmentId;
                          int recruitGroupId = recruitment.recruitGroupId;

                          log('======= 모집글 클릭 정보 =======');
                          log('🔍 모집글 ID: $recruitmentId');
                          log('🏢 그룹 ID: $recruitGroupId');
                          log('📑 모집글 제목: ${recruitment.title}');
                          log('👤 작성자: ${recruitment.authorName}');
                          log('👥 그룹명: ${recruitment.recruitGroupName}');
                          log('🏷️ 카테고리: ${recruitment.category}');
                          log('🚩 모집 상태: ${recruitment.recruitmentStatus}');
                          log('📅 생성일: ${recruitment.createdAt}');
                          log('🔄 업데이트일: ${recruitment.updatedAt}');
                          log('==============================');

                          // recruitmentId가 유효하지 않은 경우에 그룹 ID 매핑 확인
                          if (recruitmentId <= 0 && recruitGroupId > 0) {
                            log('⚠️ 유효하지 않은 모집글 ID - 그룹 ID 기반으로 매핑 확인');

                            final prefs = await SharedPreferences.getInstance();
                            final groupMappingKey =
                                'group_id_mapping_$recruitGroupId';
                            final mappedId = prefs.getInt(groupMappingKey);

                            if (mappedId != null && mappedId > 0) {
                              log(
                                '✅ 그룹 ID($recruitGroupId) 매핑에서 모집글 ID 발견: $mappedId',
                              );
                              recruitmentId = mappedId;
                            } else {
                              log('⚠️ 그룹 ID($recruitGroupId)에 매핑된 모집글 ID가 없음');
                            }
                          }

                          // 모집글 상세 화면으로 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => RecruitmentDetailScreen(
                                    // 모집글 ID가 유효한 경우 사용, 아니면 그룹 ID 사용
                                    recruitmentId:
                                        recruitmentId > 0
                                            ? recruitmentId
                                            : recruitGroupId,
                                  ),
                            ),
                          ).then((_) => _loadData());
                        },
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
