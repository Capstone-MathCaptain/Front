import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class ChatService {
  static late StompClient stompClient;

  /// ✅ 토큰을 담아 WebSocket 연결 시작
  static Future<void> connect({
    required void Function(StompFrame frame) onConnect,
    required void Function(dynamic error) onError,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      log("❌ 토큰 없음: WebSocket 연결 불가");
      return;
    }

    stompClient = StompClient(
      config: StompConfig.SockJS(
        url: 'http://localhost:8080/ws-stomp', // ← 서버 주소 수정 필요
        onConnect: onConnect,
        onStompError: (frame) {
          log('❌ STOMP 오류: ${frame.body}');
        },
        onWebSocketError: onError,
        onDisconnect: (frame) => log('🔌 연결 종료'),
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'}, // ✅ 올바른 위치
      ),
    );

    stompClient.activate();
  }

  static Future<void> sendChatMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      log("❌ userId 없음: 메시지 전송 불가");
      return;
    }

    final payload = json.encode({'userId': userId, 'message': message});

    stompClient.send(destination: '/send/chat.send', body: payload);
  }

  static void subscribeToUserChannel({
    required String userId,
    required void Function(StompFrame frame) onMessage,
  }) {
    stompClient.subscribe(destination: '/sub/$userId', callback: onMessage);
  }

  static void disconnect() {
    stompClient.deactivate();
  }
}
