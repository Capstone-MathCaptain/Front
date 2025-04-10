import 'dart:convert';
import 'dart:developer';
import 'package:capstone/models/profile.dart';
import 'package:capstone/services/api_helper.dart';

class ProfileService {
  /// 사용자 프로필 정보 조회
  static Future<UserProfile?> getUserProfile() async {
    try {
      log('👤 사용자 프로필 정보 조회 시작');

      // 토큰 갱신 시도
      await ApiHelper.checkAndRefreshToken();
      log('✅ 토큰 갱신 완료');

      // API 요청
      final response = await ApiHelper.sendRequest(
        endpoint: '/user/mypage',
        method: 'POST',
      );

      log('📥 프로필 정보 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 응답 본문 디코딩
        final responseBody = utf8.decode(response.bodyBytes);
        log('📥 응답 본문: $responseBody');

        final responseData = json.decode(responseBody);

        if (responseData['status'] == true && responseData['data'] != null) {
          log('✅ 프로필 정보 조회 성공');

          final userData = responseData['data'];
          final userProfile = UserProfile.fromJson(userData);

          // 기본 프로필 정보 로깅
          log('👤 사용자: ${userProfile.userName} (ID: ${userProfile.userId})');
          log('🏆 등급: ${userProfile.userTier}, 포인트: ${userProfile.userPoint}');
          log('👥 소속 그룹 수: ${userProfile.groupCards.length}개');

          // 그룹 정보 로깅
          for (int i = 0; i < userProfile.groupCards.length; i++) {
            final card = userProfile.groupCards[i];
            log(
              '  그룹 ${i + 1}: ${card.groupName} (역할: ${card.groupRole}, 포인트: ${card.groupPoint})',
            );
          }

          return userProfile;
        } else {
          log(
            '❌ 프로필 정보 조회 실패: ${responseData['message'] ?? "응답 데이터가 유효하지 않습니다."}',
          );
          return null;
        }
      } else {
        // 오류 응답 로깅
        try {
          final errorBody = utf8.decode(response.bodyBytes);
          log('❌ 프로필 정보 조회 실패: 상태 코드 ${response.statusCode}, 응답: $errorBody');
        } catch (e) {
          log('❌ 프로필 정보 조회 실패: 상태 코드 ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      log('❌ 프로필 정보 조회 오류: $e');
      return null;
    }
  }

  /// 티어 정보에 기반한 색상과 아이콘 이름 반환
  static Map<String, String> getTierInfo(String tier) {
    // 티어별 색상 코드와 아이콘
    switch (tier.toUpperCase()) {
      case 'BRONZE':
        return {
          'color': '#CD7F32', // 브론즈 색상
          'icon': 'shield',
        };
      case 'SILVER':
        return {
          'color': '#C0C0C0', // 실버 색상
          'icon': 'shield',
        };
      case 'GOLD':
        return {
          'color': '#FFD700', // 골드 색상
          'icon': 'security',
        };
      case 'PLATINUM':
        return {
          'color': '#E5E4E2', // 플래티넘 색상
          'icon': 'verified_user',
        };
      case 'DIAMOND':
        return {
          'color': '#B9F2FF', // 다이아몬드 색상
          'icon': 'diamond',
        };
      case 'MASTER':
        return {
          'color': '#FF4500', // 마스터 색상
          'icon': 'workspace_premium',
        };
      default:
        return {
          'color': '#CD7F32', // 기본 브론즈 색상
          'icon': 'shield',
        };
    }
  }

  /// 요일 이름을 한글로 변환
  static String getDayNameInKorean(String day) {
    switch (day.toUpperCase()) {
      case 'MONDAY':
        return '월';
      case 'TUESDAY':
        return '화';
      case 'WEDNESDAY':
        return '수';
      case 'THURSDAY':
        return '목';
      case 'FRIDAY':
        return '금';
      case 'SATURDAY':
        return '토';
      case 'SUNDAY':
        return '일';
      default:
        return day;
    }
  }
}
