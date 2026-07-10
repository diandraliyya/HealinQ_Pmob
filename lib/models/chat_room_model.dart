class ChatRoomModel {
  final String roomId;
  final String consultationId;
  final String userId;
  final String counselorId;
  final String currentRole;
  final String otherParticipantName;
  final String? otherParticipantAvatarPath;
  final String specialization;
  final String bookingCode;
  final String consultationStatus;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String? consultationNotes;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatRoomModel({
    required this.roomId,
    required this.consultationId,
    required this.userId,
    required this.counselorId,
    required this.currentRole,
    required this.otherParticipantName,
    required this.otherParticipantAvatarPath,
    required this.specialization,
    required this.bookingCode,
    required this.consultationStatus,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.consultationNotes,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  bool get isCounselorView => currentRole == 'counselor';
  bool get isUpcoming => DateTime.now().isBefore(scheduledStart);

  bool get isActive {
    final DateTime now = DateTime.now();
    return !now.isBefore(scheduledStart) &&
        now.isBefore(scheduledEnd) &&
        (consultationStatus == 'confirmed' ||
            consultationStatus == 'ongoing');
  }

  bool get isEnded =>
      !DateTime.now().isBefore(scheduledEnd) ||
      consultationStatus == 'completed';

  bool get canSendNow => isActive;

  String get sessionStatusLabel {
    if (isActive) return 'Active Session';
    if (isUpcoming) return 'Upcoming';
    return 'Session Ended';
  }
}