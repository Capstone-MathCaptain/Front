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
  final bool isLoading;
  final String? messageId;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isLoading = false,
    this.messageId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _ChatMessage &&
        other.text == text &&
        other.isUser == isUser &&
        other.time == time &&
        other.isLoading == isLoading &&
        other.messageId == messageId;
  }

  @override
  int get hashCode =>
      text.hashCode ^
      isUser.hashCode ^
      time.hashCode ^
      isLoading.hashCode ^
      (messageId?.hashCode ?? 0);
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
          // Ignore messages sent by this user to prevent duplicates
          if (data['role'] == 'USER') {
            return;
          }
          // Remove any existing loading placeholder immediately
          setState(() {
            _messages.removeWhere((msg) => msg.isLoading);
          });

          final newMessage = _ChatMessage(
            text: data['message'] ?? '',
            isUser: false,
            time:
                data['sendTime'] != null
                    ? DateTime.tryParse(data['sendTime']) ?? DateTime.now()
                    : DateTime.now(),
            messageId: data['messageId'],
          );

          // Add the actual response message
          setState(() {
            _messages.add(newMessage);
          });
          _scrollToBottom();
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
                    messageId: item['messageId'],
                  ),
                )
                .where(
                  (newMsg) =>
                      !_messages.any(
                        (msg) =>
                            msg.text == newMsg.text && msg.time == newMsg.time,
                      ),
                )
                .toList();

        if (history.isNotEmpty) {
          setState(() {
            _messages.addAll(history);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('❌ 채팅 기록 불러오기 실패: $e');
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final now = DateTime.now();
    final messageId = now.millisecondsSinceEpoch.toString();

    // ✅ prevent same messageId from being sent twice
    final isDuplicate = _messages.any((msg) => msg.messageId == messageId);
    if (isDuplicate) return;

    setState(() {
      _messages.addAll([
        _ChatMessage(text: text, isUser: true, time: now, messageId: messageId),
        _ChatMessage(
          text: '답변 생성 중...',
          isUser: false,
          time: now,
          isLoading: true,
          messageId: '${messageId}_loading',
        ),
      ]);
    });

    _scrollToBottom();

    ChatService.sendChatMessage(text, messageId: messageId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
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
        title: const Text("도우미 챗봇 🤖"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                reverse: false,
                shrinkWrap: false,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  if (message.isLoading) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text("답변 생성 중...", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }
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
                        color:
                            message.isUser
                                ? Colors.yellow[50]
                                : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                message.isUser
                                    ? Colors.black.withOpacity(0.10)
                                    : Colors.black.withOpacity(0.15),
                            blurRadius: message.isUser ? 6 : 8,
                            offset:
                                message.isUser
                                    ? const Offset(0, 3)
                                    : const Offset(0, 4),
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
