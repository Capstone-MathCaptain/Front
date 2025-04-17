import 'dart:convert';
import 'dart:developer';
import 'package:capstone/services/api_helper.dart';

class RecordService {
  static Future<Map<String, dynamic>?> sendRecordTime(
    int groupId,
    int activityTimeMinutes,
    String startTime,
    String endTime,
  ) async {
    final response = await ApiHelper.sendRequest(
      endpoint: '/record/end/fitness/$groupId',
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
}
