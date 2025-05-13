// lib/services/group_join_service.dart

import 'dart:convert';
import 'dart:developer';

import 'package:capstone/services/api_helper.dart';

/// 클라이언트에서 보내는 가입 요청 DTO
class GroupJoinRequest {
  final int personalDailyGoal;
  final int personalWeeklyGoal;

  GroupJoinRequest({
    required this.personalDailyGoal,
    required this.personalWeeklyGoal,
  });

  Map<String, dynamic> toJson() => {
    'personalDailyGoal': personalDailyGoal,
    'personalWeeklyGoal': personalWeeklyGoal,
  };
}

/// 서버가 내려주는 가입 요청 응답 DTO
class GroupJoinResponse {
  final int groupJoinId;
  final int userId;
  final int groupId;
  final String userNickname;
  final int userPoint;
  final int personalDailyGoal;
  final int personalWeeklyGoal;

  GroupJoinResponse({
    required this.groupJoinId,
    required this.userId,
    required this.groupId,
    required this.userNickname,
    required this.userPoint,
    required this.personalDailyGoal,
    required this.personalWeeklyGoal,
  });

  factory GroupJoinResponse.fromJson(Map<String, dynamic> json) {
    return GroupJoinResponse(
      groupJoinId: json['groupJoinId'] as int,
      userId: json['userId'] as int,
      groupId: json['groupId'] as int,
      userNickname: json['userNickname'] as String,
      userPoint: (json['userPoint'] as num).toInt(),
      personalDailyGoal: (json['personalDailyGoal'] as num).toInt(),
      personalWeeklyGoal: (json['personalWeeklyGoal'] as num).toInt(),
    );
  }
}

/// 그룹 가입 관련 API를 호출하는 서비스
class GroupJoinService {
  /// 그룹 가입 요청
  static Future<bool> joinGroup({
    required int groupId,
    required GroupJoinRequest request,
  }) async {
    final endpoint = '/group/join/$groupId';
    try {
      final resp = await ApiHelper.sendRequest(
        endpoint: endpoint,
        method: 'POST',
        body: request.toJson(),
      );
      if (resp.statusCode == 200) {
        // {"data": "...", ...}
        return true;
      } else {
        final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
        throw Exception(
          '가입 요청 실패: ${resp.statusCode} ${decoded['message'] ?? ''}',
        );
      }
    } catch (e) {
      log('joinGroup error: $e');
      rethrow;
    }
  }

  /// 가입 요청 수락
  static Future<bool> acceptJoinRequest(int groupId) async {
    final endpoint = '/group/join/accept/$groupId';
    try {
      final resp = await ApiHelper.sendRequest(
        endpoint: endpoint,
        method: 'POST',
      );
      if (resp.statusCode == 200) return true;
      throw Exception('수락 실패: ${resp.statusCode}');
    } catch (e) {
      log('acceptJoinRequest error: $e');
      rethrow;
    }
  }

  /// 가입 요청 거절
  static Future<bool> rejectJoinRequest(int groupId) async {
    final endpoint = '/group/join/reject/$groupId';
    try {
      final resp = await ApiHelper.sendRequest(
        endpoint: endpoint,
        method: 'POST',
      );
      if (resp.statusCode == 200) return true;
      throw Exception('거절 실패: ${resp.statusCode}');
    } catch (e) {
      log('rejectJoinRequest error: $e');
      rethrow;
    }
  }

  /// 가입 요청 취소
  static Future<bool> cancelJoinRequest(int groupId) async {
    final endpoint = '/group/join/cancel/$groupId';
    try {
      final resp = await ApiHelper.sendRequest(
        endpoint: endpoint,
        method: 'DELETE',
      );
      if (resp.statusCode == 200) return true;
      throw Exception('취소 실패: ${resp.statusCode}');
    } catch (e) {
      log('cancelJoinRequest error: $e');
      rethrow;
    }
  }

  /// 해당 그룹의 가입 요청 리스트 조회
  static Future<List<GroupJoinResponse>> fetchJoinRequests(int groupId) async {
    final endpoint = '/group/join/$groupId';
    try {
      final resp = await ApiHelper.sendRequest(
        endpoint: endpoint,
        method: 'GET',
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
        final data = decoded['data'] as List<dynamic>;
        return data
            .map((e) => GroupJoinResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('요청 리스트 조회 실패: ${resp.statusCode}');
    } catch (e) {
      log('fetchJoinRequests error: $e');
      rethrow;
    }
  }

  /// 그룹 탈퇴
  static Future<bool> leaveGroup(int groupId) async {
    final endpoint = '/group/leave/$groupId';
    try {
      final resp = await ApiHelper.sendRequest(
        endpoint: endpoint,
        method: 'DELETE',
      );
      if (resp.statusCode == 200) return true;
      throw Exception('탈퇴 실패: ${resp.statusCode}');
    } catch (e) {
      log('leaveGroup error: $e');
      rethrow;
    }
  }
}
