import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:capstone/services/notification_model.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  late Future<List<NotificationModel>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = fetchNotifications();
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/notification/list'),
      headers: {
        'Content-Type': 'application/json',
        // 필요하면 Authorization 헤더 추가
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList =
          jsonDecode(utf8.decode(response.bodyBytes))['data'];
      return jsonList.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('알림을 불러오지 못했습니다');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('알림이 없습니다.'));
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: notification.isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(notification.content),
                subtitle: Text(
                  '${notification.sender} · ${notification.createdAt.substring(0, 16)}',
                ),
                onTap: () {
                  // 눌렀을 때 읽음 처리하거나 상세보기 등
                },
              );
            },
          );
        },
      ),
    );
  }
}
