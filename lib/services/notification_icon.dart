import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:capstone/services/api_helper.dart'; // ApiHelper import 추가

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({super.key});

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  bool hasNotification = false;

  @override
  void initState() {
    super.initState();
    _connectSSE();
  }

  void _connectSSE() async {
    final accessToken = await ApiHelper.getAccessToken(); // 토큰 가져오기
    final uri = Uri.parse('http://localhost:8080/notification/subscribe');
    final request = http.Request('GET', uri);

    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    final client = http.Client();
    final response = await client.send(request);

    response.stream
        .transform(utf8.decoder)
        .listen(
          (data) {
            debugPrint('🔔 SSE message: $data');
            setState(() {
              hasNotification = true;
            });
          },
          onError: (error) {
            debugPrint('❌ SSE error: $error');
          },
          cancelOnError: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            setState(() {
              hasNotification = false;
            });
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        if (hasNotification)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}
