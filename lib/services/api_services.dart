import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchGroupDetails(int groupId) async {
  final response =
      await http.get(Uri.parse('http://localhost:8080/group/$groupId'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("그룹 정보를 불러오는 데 실패했습니다.");
  }

  // return {
  //   "groupId": "1",
  //   "leaderId": 1,
  //   "groupName": "헬스 챌린지",
  //   "category": "운동",
  //   "leaderName": "Alice",
  //   "group_point": 120,
  //   "group_rank": 1,
  //   "group_image_url": "https://example.com/image1.png",
  //   "members": [
  //     {
  //       "name": "Alice",
  //       "daily_goal": 4,
  //       "weekly_goal": 3,
  //       "current_progress": 3
  //     },
  //     {"name": "Bob", "daily_goal": 4, "weekly_goal": 3, "current_progress": 3},
  //     {
  //       "name": "Charlie",
  //       "daily_goal": 4,
  //       "weekly_goal": 3,
  //       "current_progress": 1
  //     },
  //     {
  //       "name": "David",
  //       "daily_goal": 4,
  //       "weekly_goal": 3,
  //       "current_progress": 1
  //     },
  //     {
  //       "name": "Emma",
  //       "daily_goal": 2,
  //       "weekly_goal": 3,
  //       "current_progress": 2
  //     },
  //   ]
  // };
}
