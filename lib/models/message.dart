import 'json_helpers.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    this.content,
    this.mediaUrl,
    this.mediaType = 'text',
    this.replyTo,
    this.forwardedFrom,
    this.isSms = false,
    this.isDeleted = false,
    this.createdAt,
  });

  final int id;
  final int threadId;
  final String senderId;
  final String? content;
  final String? mediaUrl;
  final String mediaType;
  final int? replyTo;
  final int? forwardedFrom;
  final bool isSms;
  final bool isDeleted;
  final DateTime? createdAt;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      threadId: JsonReader.intValue(json, 'thread_id', defaultValue: 0) ?? 0,
      senderId: JsonReader.string(json, 'sender_id'),
      content: json['content']?.toString(),
      mediaUrl: json['media_url']?.toString(),
      mediaType: JsonReader.string(json, 'media_type', defaultValue: 'text'),
      replyTo: JsonReader.intValue(json, 'reply_to'),
      forwardedFrom: JsonReader.intValue(json, 'forwarded_from'),
      isSms: JsonReader.boolValue(json, 'is_sms'),
      isDeleted: JsonReader.boolValue(json, 'is_deleted'),
      createdAt: JsonReader.dateTime(json, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thread_id': threadId,
      'sender_id': senderId,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'reply_to': replyTo,
      'forwarded_from': forwardedFrom,
      'is_sms': isSms,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
