import 'dart:convert';
import 'api_helper.dart';
import 'package:capstone/services/api_helper.dart';
import 'dart:developer';

class RecruitmentService {
  static Future<List<dynamic>> fetchRecruitments() async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/recruitment",
        method: "GET",
      );
      final decodedData = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(decodedData)['data'];
        log("✅ 모집글 데이터 가져오기 성공: ${responseData.length}개 모집글");
        return responseData;
      } else {
        log("❌ 모집글 데이터 불러오기 실패: ${response.statusCode}");
        throw Exception("모집글 정보를 불러오지 못했습니다.");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  static Future<Map<String, dynamic>> fetchDetailRecruitments(
    int recruitmentId,
  ) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/recruitment/$recruitmentId",
        method: "GET",
      );
      final decodedData = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(decodedData)['data'];
        log("✅ 모집글 상세 데이터 가져오기 성공: ID $recruitmentId");
        return responseData;
      } else {
        log("❌ 모집글 상세 데이터 불러오기 실패: ${response.statusCode}");
        throw Exception("모집글 상세 정보를 불러오지 못했습니다.");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  //모집글 작성 요청
  static Future<Map<String, dynamic>> requestCreateRecruitment() async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: "/recruitment/create",
        method: "GET",
      );
      final decodedData = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(decodedData);

      if (response.statusCode == 200 && responseData["status"] == true) {
        log("✅ 모집글 작성 요청 성공: ${responseData['data']}");
        return responseData['data'];
      } else {
        log(
          "❌ 모집글 작성 요청 실패: ${response.statusCode}, ${responseData['message']}",
        );
        throw Exception(responseData["message"] ?? "모집글 작성 요청 실패");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  // 모집글 작성
  static Future<bool> createRecruitment({
    required int recruitGroupId,
    required String title,
    required String content,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "recruitGroupId": recruitGroupId,
        "title": title,
        "content": content,
      };

      final response = await ApiHelper.sendRequest(
        endpoint: "/recruitment/create",
        method: "POST",
        body: requestBody,
      );
      final decodedData = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(decodedData);

      if (response.statusCode == 200 && responseData["status"] == true) {
        log("✅ 모집글 생성 성공: ${responseData['data']}");
        return true;
      } else {
        log("❌ 모집글 생성 실패: ${response.statusCode}, ${responseData['message']}");
        throw Exception(responseData["message"] ?? "모집글 생성 실패");
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  static Future<bool> updateRecruitment({
    required int recruitmentId,
    required int authorId,
    required String recruitGroupId,
    required String title,
    required String content,
    required String recruitmentStatus,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "authorId": authorId,
        "recruitGroupId": recruitGroupId,
        "title": title,
        "content": content,
        "recruitmentStatus": recruitmentStatus,
      };

      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/$recruitmentId',
        method: 'PUT',
        body: requestBody,
      );
      final decodedData = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(decodedData);

      if (response.statusCode == 200 && responseData["status"] == true) {
        log('✅ 모집글 수정 성공: ${responseData['data']}');
        return true;
      } else {
        log(
          '모집글 수정 실패. 응답: ${response.statusCode}, ${responseData['message']}',
        );
        return false;
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  static Future<bool> deleteRecruitment({required int recruitmentId}) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/$recruitmentId',
        method: 'DELETE',
      );
      final decodedData = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(decodedData);

      if (response.statusCode == 200 && responseData["status"] == true) {
        log('✅ 모집글 삭제 성공: ${responseData['data']}');
        return true;
      } else {
        log(
          '모집글 삭제 실패. 응답: ${response.statusCode}, ${responseData['message']}',
        );
        return false;
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  // 댓글 작성
  static Future<bool> createComment({
    required int recruitmentId,
    required String content,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {"content": content};
      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/comment/$recruitmentId',
        method: 'POST',
        body: requestBody,
      );
      final decodedData = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(decodedData);

      if (response.statusCode == 200 && responseData["status"] == true) {
        log('✅ 댓글 작성 성공: ${responseData['data']}');
        return true;
      } else if (response.statusCode == 400) {
        log('❌ 잘못된 요청: ${responseData['message']}');
        throw Exception(responseData['message'] ?? "잘못된 요청입니다.");
      } else if (response.statusCode == 404) {
        log('❌ 리소스를 찾을 수 없음: ${responseData['message']}');
        throw Exception("리소스를 찾을 수 없습니다.");
      } else {
        log('댓글 작성 실패. 응답: ${response.statusCode}, ${responseData['message']}');
        return false;
      }
    } catch (e) {
      log('❌ 댓글 작성 오류: $e');
      throw Exception('댓글 작성 중 오류가 발생했습니다: $e');
    }
  }

  static Future<bool> updateComment({
    required int recruitmentId,
    required int commentId,
    required String content,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {"content": content};

      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/comment/$recruitmentId/$commentId',
        method: 'PUT',
        body: requestBody,
      );
      final decodedData = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(decodedData);

      if (response.statusCode == 200 && responseData["status"] == true) {
        log('✅ 댓글 수정 성공: ${responseData['data']}');
        return true;
      } else if (response.statusCode == 400) {
        log('❌ 잘못된 요청: ${responseData['message']}');
        throw Exception(responseData['message'] ?? "잘못된 요청입니다.");
      } else if (response.statusCode == 404) {
        log('❌ 리소스를 찾을 수 없음: 리소스를 찾을 수 없음');
        throw Exception("리소스를 찾을 수 없습니다.");
      } else {
        log('댓글 수정 실패. 응답: ${response.statusCode}, ${responseData['message']}');
        return false;
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }

  static Future<bool> deleteComment({
    required int recruitmentId,
    required int commentId,
  }) async {
    try {
      final response = await ApiHelper.sendRequest(
        endpoint: '/recruitment/comment/$recruitmentId/$commentId',
        method: 'DELETE',
      );
      final decodedData = utf8.decode(response.bodyBytes);
      final responseData = jsonDecode(decodedData);

      if (response.statusCode == 200 && responseData["status"] == true) {
        log('✅ 댓글 삭제 성공: ${responseData['data']}');
        return true;
      } else if (response.statusCode == 400) {
        log('❌ 잘못된 요청: ${responseData['message']}');
        throw Exception(responseData['message'] ?? "해당 댓글이 해당 모집글에 속해있지 않습니다.");
      } else if (response.statusCode == 404) {
        log('❌ 리소스를 찾을 수 없음: 해당 댓글이 없습니다.');
        throw Exception("해당 댓글이 없습니다.");
      } else {
        log('댓글 삭제 실패. 응답: ${response.statusCode}, ${responseData['message']}');
        return false;
      }
    } catch (e) {
      log("❌ 네트워크 오류: $e", error: e);
      throw Exception("네트워크 오류 발생: $e");
    }
  }
}
