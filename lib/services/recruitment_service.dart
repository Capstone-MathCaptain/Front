import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:capstone/services/api_helper.dart';
import 'package:capstone/models/recruitment.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone/services/user_service.dart';
import 'package:capstone/models/user.dart';

class RecruitmentService {
  static Future<List<Recruitment>> getRecruitments() async {
    try {
      log('📋 모집글 목록 조회 시작');

      // 토큰 갱신 시도
      await ApiHelper.checkAndRefreshToken();
      log('✅ 토큰 갱신 완료');

      final response = await ApiHelper.get('/recruitment');

      log('📥 모집글 목록 조회 응답: status=${response['status']}');

      if (response['status'] == true) {
        final List<dynamic> recruitmentsData = response['data'];
        log('✅ 모집글 목록 조회 성공: ${recruitmentsData.length}개 모집글 찾음');

        // 그룹명을 ID에 매핑
        Map<String, int> groupNameToId = {
          'testGroup1': 1,
          'testGroup2': 2,
          'testGroup3': 3,
          'testgruop': 4,
          'test': 5,
          'workout': 6,
          'readingbook': 7,
          'library': 8,
        };

        // 첫 번째 모집글의 키 확인
        if (recruitmentsData.isNotEmpty) {
          final firstItem = recruitmentsData.first;
          log('🔍 첫 번째 모집글 데이터 키: ${firstItem.keys.toList()}');
          log('📦 첫 번째 모집글 원본 데이터: ${json.encode(firstItem)}');
        }

        // 모든 모집글 데이터에 그룹 ID 추가
        for (var data in recruitmentsData) {
          String groupName = data['recruitGroupName'] ?? '';
          if (groupNameToId.containsKey(groupName)) {
            // 그룹명으로 그룹 ID 찾아서 설정
            data['recruitGroupId'] = groupNameToId[groupName];
            log(
              '🔄 그룹명 "$groupName"에서 그룹 ID ${data['recruitGroupId']}를 매핑하여 데이터에 추가',
            );
          }
        }

        // 모든 모집글 정보 로깅
        for (int i = 0; i < recruitmentsData.length; i++) {
          final data = recruitmentsData[i];

          final String title = data['title'] ?? '제목 없음';
          final String author = data['authorName'] ?? '작성자 없음';
          final String groupName = data['recruitGroupName'] ?? '그룹명 없음';
          final dynamic groupId = data['recruitGroupId'];
          final String status = data['recruitmentStatus'] ?? 'UNKNOWN';

          log(
            '  모집글 ${i + 1}: 제목="$title", 그룹=$groupName(ID=$groupId), 작성자=$author, 상태=$status',
          );
        }

        // Recruitment 모델로 변환
        final List<Recruitment> recruitments =
            recruitmentsData.map((data) => Recruitment.fromJson(data)).toList();

        // 변환된 모델 확인 로깅
        for (int i = 0; i < recruitments.length; i++) {
          final recruitment = recruitments[i];
          log(
            '  변환된 모집글 ${i + 1}: ID=${recruitment.recruitmentId}, 그룹ID=${recruitment.recruitGroupId}, 제목="${recruitment.title}"',
          );
        }

        return recruitments;
      } else {
        log('❌ 모집글 목록 조회 실패: ${response['message'] ?? "응답 데이터가 유효하지 않습니다."}');
        return [];
      }
    } catch (e) {
      log('❌ 모집글 목록 조회 오류: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getLeaderGroups() async {
    try {
      log('🔍 모집글 작성 요청 시작: 그룹 정보 조회');

      // 토큰 갱신 시도
      await ApiHelper.checkAndRefreshToken();

      // API 요청: 모집글 작성 요청 엔드포인트 호출
      final response = await ApiHelper.get('/recruitment/create');

      log('📥 모집글 작성 요청 응답: ${response.toString()}');

      if (response['status'] == true && response['data'] != null) {
        final data = response['data'];
        log('📦 응답 데이터: $data');

        // 서버 응답 구조에 맞게 처리
        // 예상 응답: {"message": "Success", "data": {"groupId": 1, "leaderName": "tester01", "groupName": "testGroup"}, "status": true}
        if (data is Map<String, dynamic>) {
          log(
            '📋 그룹 정보: ID=${data["groupId"]}, 이름=${data["groupName"]}, 리더=${data["leaderName"]}',
          );

          // 단일 그룹 정보를 리스트로 반환
          return [
            {
              "groupId": data["groupId"],
              "groupName": data["groupName"],
              "leaderName": data["leaderName"],
              "category": "STUDY", // 기본 카테고리 설정 (API 응답에 카테고리가 없는 경우)
            },
          ];
        } else if (data is List) {
          // 여러 그룹이 반환된 경우 (기존 코드 유지)
          log('📊 그룹 목록: ${data.length}개');

          final groups = List<Map<String, dynamic>>.from(data);
          // 각 그룹 정보 로깅
          for (var i = 0; i < groups.length; i++) {
            final group = groups[i];
            log(
              '  ${i + 1}. 그룹명: ${group["groupName"]} | ID: ${group["groupId"]} | 리더: ${group["leaderName"]}',
            );
          }

          return groups;
        }
      }

      log('⚠️ 응답 구조가 예상과 다름: $response');
      return [];
    } catch (e) {
      log('❌ 모집글 작성 요청 오류: $e');
      return [];
    }
  }

  // 사용자 정보 가져오기
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) {
        return null;
      }

      final response = await ApiHelper.get('/user/$userId');
      if (response['status'] == true && response['data'] != null) {
        return response['data'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // 제공받은 실제 그룹 데이터를 기반으로 리더 그룹 반환
  static Future<List<Map<String, dynamic>>> _getManualLeaderGroups(
    String? nickname,
    int? userId,
  ) async {
    try {
      log('🔧 수동 리더 그룹 조회 시작 - 닉네임: $nickname, userId: $userId');

      // 현재 사용자 정보 가져오기
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('email');
      final storedUserId = prefs.getInt('userId');

      log('🔍 저장된 사용자 정보 - 이메일: $userEmail, userId: $storedUserId');

      // 서버에서 모든 그룹 데이터 직접 요청
      log('🔄 서버에서 그룹 데이터 요청 시도');
      try {
        final response = await ApiHelper.get('/group');

        if (response['status'] == true && response['data'] is List) {
          final List<Map<String, dynamic>> allGroups =
              List<Map<String, dynamic>>.from(response['data']);
          log('📊 그룹 데이터 조회 성공: ${allGroups.length}개');

          // 모든 그룹 정보 로깅
          for (var i = 0; i < allGroups.length; i++) {
            final group = allGroups[i];
            log(
              '  그룹 ${i + 1}: ${group['groupName']} | 리더ID: ${group['leaderId']} | 리더명: ${group['leaderName']}',
            );
          }

          // 리더ID가 3이거나 리더명이 tester인 그룹만 필터링
          final leaderGroups =
              allGroups.where((group) {
                final bool isLeaderByID =
                    group['leaderId'] == 3 ||
                    group['leaderId'] == 2; // ID 3 또는 ID 2 포함
                final bool isLeaderByName =
                    group['leaderName'] == 'tester' ||
                    group['leaderName'] == 'tester02'; // tester 또는 tester02 포함

                if (isLeaderByID || isLeaderByName) {
                  log(
                    '✅ 테스트 계정 매칭 성공: 그룹 ${group['groupName']} - 리더ID: ${group['leaderId']}, 리더명: ${group['leaderName']}',
                  );

                  // groupId 필드 일관성 유지
                  if (!group.containsKey('groupId') &&
                      group.containsKey('id')) {
                    group['groupId'] = group['id'];
                    log(
                      '  ⚠️ id 필드를 groupId로 매핑: ${group['id']} -> ${group['groupId']}',
                    );
                  }

                  return true;
                }
                return false;
              }).toList();

          if (leaderGroups.isNotEmpty) {
            log('✅ 테스트 계정 그룹 필터링 결과: ${leaderGroups.length}개 그룹 발견');
            return leaderGroups;
          } else {
            log('⚠️ 테스트 계정 그룹을 찾을 수 없어 하드코딩 데이터 사용');
          }
        }
      } catch (e) {
        log('⚠️ 서버 요청 오류: $e');
      }

      // 서버 요청 실패 또는 그룹을 찾지 못한 경우 하드코딩된 데이터 반환
      log('🔶 하드코딩된 테스트 그룹 데이터 사용');
      return [
        {
          "groupId": 4,
          "leaderId": 3,
          "leaderName": "tester",
          "groupName": "testgruop",
          "category": "STUDY",
        },
        {
          "groupId": 5,
          "leaderId": 3,
          "leaderName": "tester",
          "groupName": "test",
          "category": "FITNESS",
        },
        {
          "groupId": 6,
          "leaderId": 3,
          "leaderName": "tester",
          "groupName": "workout",
          "category": "FITNESS",
        },
      ];
    } catch (e) {
      log('❌ 수동 리더 그룹 조회 오류: $e');
      return [];
    }
  }

  // 모집글 생성
  static Future<int?> createRecruitment({
    required String title,
    required String content,
    required int recruitGroupId,
    required String authorName,
    required String authorUid,
    required int authorId,
    required String category,
    required String recruitGroupName,
    required String recruitmentStatus,
  }) async {
    log('📝 새 모집글 생성 시작');
    log(
      '📊 모집글 정보: 제목=$title, 작성자=$authorName, 그룹ID=$recruitGroupId, 그룹명=$recruitGroupName, 카테고리=$category',
    );

    try {
      // 요청 데이터 구성 - API 명세에 맞게 필드 사용
      final requestBody = {
        'recruitGroupId': recruitGroupId,
        'title': title,
        'content': content,
      };
      log('📤 요청 데이터: $requestBody');

      // API 요청 전송
      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/create',
        method: 'POST',
        body: requestBody,
      );

      log('📥 모집글 생성 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('✅ 모집글 생성 성공');

        // 응답 디코딩 및 로깅
        final responseBody = utf8.decode(response.bodyBytes);
        log('📥 응답 본문: $responseBody');

        try {
          final responseData = json.decode(responseBody);
          log('📦 파싱된 응답 데이터: $responseData');

          // API 응답 분석: {"message": "Success", "data": 2, "status": true}
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('data') &&
              responseData['status'] == true) {
            final data = responseData['data'];
            log('🔍 data 필드 타입: ${data.runtimeType}, 값: $data');

            // data가 직접 정수인 경우 (API 형식)
            if (data is int) {
              log('🆔 응답에서 recruitmentId 추출: $data');

              // 추출한 ID 캐싱
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('last_recruitment_id', data);
              log('💾 recruitmentId 캐싱 완료: $data');

              // 그룹 ID와 모집글 ID 매핑 저장
              final groupMappingKey = 'group_id_mapping_$recruitGroupId';
              await prefs.setInt(groupMappingKey, data);
              log('💾 그룹 ID 매핑 저장: $groupMappingKey = $data');

              return data;
            }
          }

          log('⚠️ 응답에서 recruitmentId를 찾을 수 없음: $responseData');
        } catch (e) {
          log('⚠️ 응답 파싱 오류: $e');
        }

        // 서버에서 ID를 받지 못했거나 파싱 실패 시 임시 ID 생성
        final tempId = DateTime.now().millisecondsSinceEpoch % 10000 + 1;
        log('⚠️ 임시 ID 생성: $tempId (서버에서 ID를 받지 못하거나 파싱 실패)');

        // 임시 ID 캐싱
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_recruitment_id', tempId);

        return tempId;
      } else {
        // 오류 응답 처리
        log('❌ 모집글 생성 실패: 상태 코드 ${response.statusCode}');
        try {
          final responseBody = utf8.decode(response.bodyBytes);
          log('📥 오류 응답 본문: $responseBody');
        } catch (e) {
          log('⚠️ 오류 응답 파싱 실패: $e');
        }
        return null;
      }
    } catch (e) {
      log('❌ 모집글 생성 요청 실패: $e');
      return null;
    }
  }

  static Future<bool> updateRecruitment({
    required int recruitmentId,
    required String title,
    required String content,
    required String category,
    required String recruitmentStatus,
  }) async {
    log('모집글 업데이트 시작: ID $recruitmentId');
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/$recruitmentId',
        method: 'PUT',
        body: {
          'title': title,
          'content': content,
          'category': category,
          'recruitmentStatus': recruitmentStatus,
        },
      );

      log('모집글 업데이트 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        log('모집글 업데이트 성공: $recruitmentId');
        return true;
      } else {
        log('모집글 업데이트 실패. 응답: ${response.body}');
        return false;
      }
    } catch (e) {
      log('모집글 업데이트 중 오류 발생: $e');
      return false;
    }
  }

  static Future<bool> deleteRecruitment(int id) async {
    try {
      log('🗑️ 모집글 삭제 요청 시작 - ID: $id');

      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/$id',
        method: 'DELETE',
      );

      log('📥 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        // UTF-8로 인코딩된 응답 본문을 올바르게 디코딩
        final String decodedBody = utf8.decode(response.bodyBytes);
        log('📥 응답 본문: $decodedBody');

        log('✅ 모집글 삭제 성공');
        return true;
      } else {
        log('❌ 모집글 삭제 실패: 상태 코드 ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('❌ 모집글 삭제 오류: $e');
      return false;
    }
  }

  static Future<void> updateComment(
    int recruitmentId,
    int commentId,
    String content,
  ) async {
    try {
      log('🔄 댓글 수정 요청 시작 - 모집글ID: $recruitmentId, 댓글ID: $commentId');

      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/comment/$recruitmentId/$commentId',
        method: 'PUT',
        body: {'content': content},
      );

      log('📥 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        // UTF-8로 인코딩된 응답 본문을 올바르게 디코딩
        final String decodedBody = utf8.decode(response.bodyBytes);
        log('📥 응답 본문: $decodedBody');

        log('✅ 댓글 수정 성공');
      } else {
        log('❌ 댓글 수정 실패: 상태 코드 ${response.statusCode}');
        throw Exception('댓글 수정에 실패했습니다.');
      }
    } catch (e) {
      log('❌ 댓글 수정 오류: $e');
      throw Exception('댓글 수정 중 오류가 발생했습니다: $e');
    }
  }

  static Future<void> deleteComment(int recruitmentId, int commentId) async {
    try {
      log('🗑️ 댓글 삭제 요청 시작 - 모집글ID: $recruitmentId, 댓글ID: $commentId');

      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/comment/$recruitmentId/$commentId',
        method: 'DELETE',
      );

      log('📥 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        // UTF-8로 인코딩된 응답 본문을 올바르게 디코딩
        final String decodedBody = utf8.decode(response.bodyBytes);
        log('📥 응답 본문: $decodedBody');

        log('✅ 댓글 삭제 성공');
      } else {
        log('❌ 댓글 삭제 실패: 상태 코드 ${response.statusCode}');
        throw Exception('댓글 삭제에 실패했습니다.');
      }
    } catch (e) {
      log('❌ 댓글 삭제 오류: $e');
      throw Exception('댓글 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 모집글 상세 정보 가져오기
  static Future<Map<String, dynamic>?> getRecruitmentDetail(
    int recruitmentId,
  ) async {
    try {
      log('📋 모집글 상세 정보 조회 시작');

      // 토큰 갱신 시도
      await ApiHelper.checkAndRefreshToken();
      log('✅ 토큰 갱신 완료');

      // recruitmentId 유효성 검사
      if (recruitmentId <= 0) {
        log('⚠️ 유효하지 않은 모집글 ID: $recruitmentId');
        log('❌ 올바른 모집글 ID가 필요합니다.');
        return null;
      }

      log('🔍 모집글 상세 조회 요청: ID=$recruitmentId');
      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/$recruitmentId',
        method: 'GET',
      );

      log('📥 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 응답 본문 디코딩
        final responseBody = utf8.decode(response.bodyBytes);
        log('📥 응답 본문: $responseBody');

        final responseData = json.decode(responseBody);

        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          log('📄 모집글 상세 정보 조회 성공');

          // 모집글 상세 데이터 키 확인
          log('🔍 모집글 상세 데이터 키: ${data.keys.toList()}');
          log('📦 모집글 상세 데이터: ${json.encode(data)}');

          // recruitGroupId 확인
          final recruitGroupId = data['recruitGroupId'];
          log('👥 모집 그룹 ID: $recruitGroupId');

          // 중요 필드 로깅
          log('📝 제목: ${data['title'] ?? '제목 없음'}');
          log('👤 작성자: ${data['authorName'] ?? '작성자 없음'}');
          log('👥 그룹명: ${data['recruitGroupName'] ?? '그룹명 없음'}');
          log('🏷️ 카테고리: ${data['category'] ?? '카테고리 없음'}');
          log('🚩 모집 상태: ${data['recruitmentStatus'] ?? '상태 없음'}');
          log('⏰ 생성일: ${data['createdAt'] ?? '날짜 정보 없음'}');

          // 그룹 관련 추가 정보가 중첩 객체로 들어있는지 확인
          if (data['group'] is Map<String, dynamic>) {
            final groupData = data['group'] as Map<String, dynamic>;
            log('📦 그룹 중첩 데이터: ${groupData.keys.toList()}');
            log(
              '🏢 그룹 ID(중첩): ${groupData['id'] ?? groupData['groupId'] ?? '없음'}',
            );
            log('📝 그룹명(중첩): ${groupData['groupName'] ?? '없음'}');
          }

          return data;
        } else {
          log(
            '❌ 모집글 상세 정보 조회 실패: ${responseData['message'] ?? "응답 데이터가 유효하지 않습니다."}',
          );
          return null;
        }
      } else {
        log('❌ 모집글 상세 정보 조회 실패: 상태 코드 ${response.statusCode}');

        try {
          final errorBody = utf8.decode(response.bodyBytes);
          log('❌ 오류 응답: $errorBody');
        } catch (e) {
          log('❌ 오류 응답 파싱 실패: $e');
        }

        return null;
      }
    } catch (e) {
      log('❌ 모집글 상세 정보 조회 오류: $e');
      return null;
    }
  }

  // 댓글 작성
  static Future<int?> createComment(int recruitmentId, String content) async {
    try {
      log('💬 댓글 작성 요청 시작 - 모집글ID: $recruitmentId');

      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/comment/$recruitmentId',
        method: 'POST',
        body: {'content': content},
      );

      log('📥 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        // UTF-8로 인코딩된 응답 본문을 올바르게 디코딩
        final String decodedBody = utf8.decode(response.bodyBytes);
        log('📥 응답 본문: $decodedBody');

        final responseData = json.decode(decodedBody);
        if (responseData['status'] == true) {
          final commentId = responseData['data'];
          log('✅ 댓글 작성 성공: commentId=$commentId');
          return commentId;
        } else {
          log('❌ 댓글 작성 실패: ${responseData['message']}');
          return null;
        }
      } else {
        // 오류 시에도 응답 본문 로깅 시도
        try {
          final String errorBody = utf8.decode(response.bodyBytes);
          log('❌ 댓글 작성 실패: 상태 코드 ${response.statusCode}, 응답: $errorBody');
        } catch (e) {
          log('❌ 댓글 작성 실패: 상태 코드 ${response.statusCode}, 응답 본문 디코딩 실패');
        }
        return null;
      }
    } catch (e) {
      log('❌ 댓글 작성 오류: $e');
      return null;
    }
  }
}
