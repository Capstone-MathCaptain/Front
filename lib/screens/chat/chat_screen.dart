import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:capstone/services/chat_service.dart';
import 'package:capstone/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({required this.text, required this.isUser, required this.time});
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _userId;

  @override
  void initState() {
    super.initState();
    UserService.getUserId().then((id) {
      if (id != null) {
        setState(() => _userId = id.toString());
        ChatService.connect(
          onConnect: _onConnect,
          onError: (error) => debugPrint('WebSocket Error: $error'),
        );
      } else {
        debugPrint('❌ userId 없음: WebSocket 연결 불가');
      }
    });
  }

  void _onConnect(StompFrame frame) {
    if (_userId != null) {
      _loadChatHistory();
      ChatService.subscribeToUserChannel(
        userId: _userId!,
        onMessage: (frame) {
          final data = jsonDecode(frame.body!);
          setState(() {
            _messages.add(
              _ChatMessage(
                text: data['message'] ?? '',
                isUser: data['role'] == 'USER',
                time:
                    data['sendTime'] != null
                        ? DateTime.tryParse(data['sendTime']) ?? DateTime.now()
                        : DateTime.now(),
              ),
            );
          });
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        },
      );
    }
  }

  Future<void> _loadChatHistory() async {
    if (_userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:8080/chat/history/$_userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decodedData = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(decodedData);
        final history =
            data
                .map(
                  (item) => _ChatMessage(
                    text: item['message'] ?? '',
                    isUser: item['role'] == 'USER',
                    time:
                        DateTime.tryParse(item['sendTime'] ?? '') ??
                        DateTime.now(),
                  ),
                )
                .toList();

        setState(() {
          _messages.addAll(history);
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    } catch (e) {
      debugPrint('❌ 채팅 기록 불러오기 실패: $e');
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ChatService.sendChatMessage(text);
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    _controller.clear();
  }

  @override
  void dispose() {
    ChatService.disconnect();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("채팅"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              reverse: false,
              shrinkWrap: false,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment:
                      message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.yellow[100] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          message.isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: const TextStyle(fontSize: 15, height: 1.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFFFDFDFD),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  backgroundColor: Colors.amberAccent,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
