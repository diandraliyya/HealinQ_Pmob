import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/chat_message_model.dart';
import '../../models/chat_room_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';

class RoomChatScreen extends StatefulWidget {
  final String roomId;

  const RoomChatScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final ChatService _service = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatRoomModel? _room;
  Stream<List<ChatMessageModel>>? _messageStream;
  Timer? _sessionTimer;

  bool _isLoading = true;
  bool _isSending = false;
  bool _markReadScheduled = false;
  int _lastMessageCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoom();
    _sessionTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRoom({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final ChatRoomModel room = await _service.getChatRoom(widget.roomId);

      if (!mounted) return;

      setState(() {
        _room = room;
        _messageStream = _service.watchMessages(widget.roomId);
        _errorMessage = null;
      });

      await _service.markMessagesRead(widget.roomId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _cleanError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final ChatRoomModel? room = _room;
    final String content = _messageController.text.trim();

    if (room == null || _isSending || content.isEmpty) return;

    if (!room.canSendNow) {
      _showMessage(
        room.isUpcoming
            ? 'Room chat baru aktif saat jadwal konsultasi dimulai.'
            : 'Sesi chat sudah berakhir.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _service.sendMessage(
        roomId: room.roomId,
        content: content,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error), isError: true);
      await _loadRoom(showLoading: false);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scheduleMarkRead() {
    if (_markReadScheduled) return;
    _markReadScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _service.markMessagesRead(widget.roomId);
      _markReadScheduled = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final ChatRoomModel? room = _room;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textDark,
          ),
        ),
        title: room == null ? _plainTitle() : _buildAppBarTitle(room),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : () => _loadRoom(showLoading: false),
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _plainTitle() {
    return Text(
      'Room Chat',
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildAppBarTitle(ChatRoomModel room) {
    return Row(
      children: <Widget>[
        const CircleAvatar(
          radius: 19,
          backgroundColor: AppColors.secondaryLight,
          child: Icon(
            Icons.person_rounded,
            color: AppColors.teal,
            size: 23,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                room.otherParticipantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                room.isCounselorView
                    ? 'User • ${room.bookingCode}'
                    : room.specialization.trim().isEmpty
                        ? room.bookingCode
                        : room.specialization,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null || _room == null || _messageStream == null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 50,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Room chat tidak ditemukan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _loadRoom,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final ChatRoomModel room = _room!;

    return Column(
      children: <Widget>[
        _buildSessionBanner(room),
        Expanded(
          child: StreamBuilder<List<ChatMessageModel>>(
            stream: _messageStream,
            builder: (
              BuildContext context,
              AsyncSnapshot<List<ChatMessageModel>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    _cleanError(snapshot.error!),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                );
              }

              final List<ChatMessageModel> messages =
                  snapshot.data ?? <ChatMessageModel>[];

              _scheduleMarkRead();

              if (messages.length != _lastMessageCount) {
                _lastMessageCount = messages.length;
                _scrollToBottom();
              }

              if (messages.isEmpty) {
                return _buildEmptyMessages(room);
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                itemCount: messages.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildBubble(messages[index]);
                },
              );
            },
          ),
        ),
        _buildInputArea(room),
      ],
    );
  }

  Widget _buildSessionBanner(ChatRoomModel room) {
    final Color color = room.isActive
        ? AppColors.success
        : room.isUpcoming
            ? const Color(0xFFD68A1F)
            : AppColors.textMedium;

    final IconData icon = room.isActive
        ? Icons.play_circle_fill_rounded
        : room.isUpcoming
            ? Icons.lock_clock_rounded
            : Icons.history_rounded;

    final String description = room.isActive
        ? 'Sesi berlangsung. Pesan dapat dikirim sampai '
            '${DateFormat('HH:mm').format(room.scheduledEnd)}.'
        : room.isUpcoming
            ? 'Room aktif pada '
                '${DateFormat('d MMM yyyy, HH:mm').format(room.scheduledStart)}.'
            : 'Sesi selesai. Riwayat pesan hanya dapat dibaca.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 10,
                height: 1.45,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages(ChatRoomModel room) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              room.isActive
                  ? Icons.forum_outlined
                  : Icons.chat_bubble_outline_rounded,
              size: 54,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              room.isActive ? 'Mulai Percakapan' : 'Belum Ada Pesan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              room.isActive
                  ? 'Gunakan ruang ini untuk konsultasi secara aman dan terarah.'
                  : 'Pesan baru dapat dikirim saat sesi berlangsung.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.5,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessageModel message) {
    final bool isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 7),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : const Color(0xFFFFE4EE),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.content,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.45,
                  color: isMine ? AppColors.white : AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: isMine
                        ? AppColors.white.withOpacity(0.76)
                        : AppColors.textLight,
                  ),
                ),
                if (isMine) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(
                    message.readAt == null
                        ? Icons.done_rounded
                        : Icons.done_all_rounded,
                    size: 13,
                    color: AppColors.white.withOpacity(
                      message.readAt == null ? 0.70 : 1,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatRoomModel room) {
    if (!room.canSendNow) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          18,
          13,
          18,
          13 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.lock_clock_rounded,
              color: AppColors.textMedium,
              size: 19,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                room.isUpcoming
                    ? 'Pesan aktif saat sesi dimulai.'
                    : 'Sesi selesai — mode baca saja.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isSending,
              minLines: 1,
              maxLines: 5,
              maxLength: 4000,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Type a message...',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
