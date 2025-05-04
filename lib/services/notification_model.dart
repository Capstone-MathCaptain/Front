class NotificationModel {
  final int id;
  final String sender;
  final String content;
  final String createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.sender,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      sender: json['sender'],
      content: json['content'],
      createdAt: json['createdAt'],
      isRead: json['isRead'],
    );
  }
}