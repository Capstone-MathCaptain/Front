import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommentWidget extends StatefulWidget {
  final int recruitmentId;

  const CommentWidget({super.key, required this.recruitmentId});

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
      'http://baseUrl/recruitment/${widget.recruitmentId}/comments',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          comments = json.decode(response.body)['data'];
        });
      } else {
        _showSnackBar('댓글을 불러오지 못했습니다.');
      }
    } catch (e) {
      _showSnackBar('네트워크 오류 발생: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitComment() async {
    final String content = _commentController.text;
    if (content.isEmpty) {
      _showSnackBar('댓글 내용을 입력하세요.');
      return;
    }

    final url = Uri.parse(
      'http://baseUrl/recruitment/${widget.recruitmentId}/comments',
    );
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({'content': content});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        _commentController.clear();
        _fetchComments();
        _showSnackBar('댓글이 성공적으로 작성되었습니다.');
      } else {
        _showSnackBar('댓글 작성 실패: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('네트워크 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isLoading)
          CircularProgressIndicator()
        else
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return ListTile(
                  title: Text(comment['author']),
                  subtitle: Text(comment['content']),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(labelText: '댓글 입력'),
                ),
              ),
              IconButton(icon: Icon(Icons.send), onPressed: _submitComment),
            ],
          ),
        ),
      ],
    );
  }
}
