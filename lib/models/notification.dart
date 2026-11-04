import 'json_helpers.dart';

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    this.body,
    this.payload,
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final String userId;
  final String kind;
  final String title;
  final String? body;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      userId: JsonReader.string(json, 'user_id'),
      kind: JsonReader.string(json, 'kind'),
      title: JsonReader.string(json, 'title'),
      body: json['body']?.toString(),
      payload: JsonReader.map(json, 'payload'),
      isRead: JsonReader.boolValue(json, 'is_read'),
      createdAt: JsonReader.dateTime(json, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'kind': kind,
      'title': title,
      'body': body,
      'payload': payload,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
