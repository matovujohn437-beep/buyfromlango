class ChatMessageReaction {
  const ChatMessageReaction({
    required this.threadId,
    required this.messageId,
    required this.userId,
    required this.emoji,
  });

  final int threadId;
  final int messageId;
  final String userId;
  final String emoji;

  factory ChatMessageReaction.fromJson(Map<String, dynamic> json) =>
      ChatMessageReaction(
        threadId: int.parse(json['thread_id'].toString()),
        messageId: int.parse(json['message_id'].toString()),
        userId: json['user_id'].toString(),
        emoji: json['emoji'].toString(),
      );
}
