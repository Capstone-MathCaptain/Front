import 'dart:convert';
import 'package:capstone/services/api_helper.dart';

class RecordService {
  static Future<Map<String, dynamic>?> sendRecordTime(
    int groupId,
    int activityTimeMinutes,
    String startTime,
    String endTime,
  ) async {
    final response = await ApiHelper.sendRequest(
      endpoint: '/record/end/$groupId',
      method: 'POST',
      body: {
        'activityTime': activityTimeMinutes,
        'startTime': startTime,
        'endTime': endTime,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }

    return null;
  }

  static Future<Map<String, dynamic>?> sendfitnessRecord(
    int groupId,
    int activityTimeMinutes,
    String startTime,
    String endTime,
    List<Map<String, dynamic>> exerciseInfoList,
  ) async {
    final response = await ApiHelper.sendRequest(
      endpoint: '/record/end/fitness/$groupId',
      method: 'POST',
      body: {
        'activityTime': activityTimeMinutes,
        'startTime': startTime,
        'endTime': endTime,
        'exerciseInfoList': exerciseInfoList,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }

    return null;
  }

  static Future<Map<String, dynamic>?> sendrunningRecord(
    int groupId,
    int activityTime,
    String startTime,
    String endTime,
    int distance,
    String memo,
  ) async {
    final response = await ApiHelper.sendRequest(
      endpoint: '/record/end/running/$groupId',
      method: 'POST',
      body: {
        'activityTime': activityTime,
        'startTime': startTime,
        'endTime': endTime,
        'distance': distance,
        'memo': memo,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }

    return null;
  }

  static Future<Map<String, dynamic>?> sendstudyRecord(
    int groupId,
    int activityTime,
    String startTime,
    String endTime,
    String subject,
    String memo,
  ) async {
    final response = await ApiHelper.sendRequest(
      endpoint: '/record/end/study/$groupId',
      method: 'POST',
      body: {
        'activityTime': activityTime,
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'memo': memo,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }

    return null;
  }
}
