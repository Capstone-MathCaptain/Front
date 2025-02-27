import 'dart:convert';
import 'package:http/http.dart' as http;

class RecruitmentService {
  static Future<void> createRecruitment(String title, String content) async {
    final response = await http.post(
      Uri.parse('http://baseUrl/recruitment/create'),
      body: json.encode({'title': title, 'content': content}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create recruitment');
    }
  }

  static Future<void> updateRecruitment(
    int id,
    String title,
    String content,
  ) async {
    final response = await http.put(
      Uri.parse('http://baseUrl/recruitment/$id'),
      body: json.encode({'title': title, 'content': content}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update recruitment');
    }
  }

  static Future<void> deleteRecruitment(int id) async {
    final response = await http.delete(
      Uri.parse('http://baseUrl/recruitment/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete recruitment');
    }
  }

  static Future<void> updateComment(
    int recruitmentId,
    int commentId,
    String content,
  ) async {
    final response = await http.put(
      Uri.parse('http://baseUrl/recruitment/comment/$recruitmentId/$commentId'),
      body: json.encode({'content': content}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update comment');
    }
  }

  static Future<List> getRecruitments() async {
    final response = await http.get(Uri.parse('http://baseUrl/recruitment'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load recruitments');
    }
  }

  static Future getRecruitmentDetail(int id) async {
    final response = await http.get(
      Uri.parse('http://baseUrl/recruitment/$id'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load recruitment detail');
    }
  }
}
