class ChatMessageModel {
  final int id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isMine;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.readAt,
    required this.isMine,
  });

  factory ChatMessageModel.fromMap(
    Map<String, dynamic> map, {
    required String currentUserId,
  }) {
    final String senderId = map['sender_id']?.toString() ?? '';

    return ChatMessageModel(
      id: _parseInt(map['id']),
      roomId: map['room_id']?.toString() ?? '',
      senderId: senderId,
      content: map['content']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at'].toString()).toLocal(),
      readAt: map['read_at'] == null
          ? null
          : DateTime.tryParse(map['read_at'].toString())?.toLocal(),
      isMine: senderId == currentUserId,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
