import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/chat_room_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import 'room_chat_screen.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  final ChatService _service = ChatService();

  List<ChatRoomModel> _rooms = <ChatRoomModel>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<ChatRoomModel> result = await _service.getMyChatRooms();
      if (!mounted) return;

      setState(() {
        _rooms = result
            .where((ChatRoomModel room) => !room.isCounselorView)
            .toList();
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '')
            .trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openRoom(ChatRoomModel room) async {
    if (room.isUpcoming) {
      _showMessage(
        'Room chat aktif pada '
        '${DateFormat('d MMM yyyy, HH:mm').format(room.scheduledStart)}.',
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RoomChatScreen(roomId: room.roomId),
      ),
    );

    if (mounted) {
      await _loadRooms(showLoading: false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFB2EBF2),
              Color(0xFFFCE4EC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _loadRooms(showLoading: false),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'My Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Chat konsultasi online yang sudah terkonfirmasi.',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadRooms,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 220),
          Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 90),
          _buildErrorState(),
        ],
      );
    }

    if (_rooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 90),
          _buildEmptyState(),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: _rooms.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildRoomCard(_rooms[index]);
      },
    );
  }

  Widget _buildRoomCard(ChatRoomModel room) {
    final Color statusColor = room.isActive
        ? AppColors.success
        : room.isUpcoming
            ? const Color(0xFFD68A1F)
            : AppColors.textMedium;

    return InkWell(
      onTap: () => _openRoom(room),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.secondaryLight,
              child: Icon(
                Icons.medical_services_rounded,
                color: AppColors.teal,
                size: 29,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          room.otherParticipantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (room.unreadCount > 0)
                        _UnreadBadge(count: room.unreadCount),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: room.unreadCount > 0
                          ? AppColors.textDark
                          : AppColors.textMedium,
                      fontWeight: room.unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      _StatusBadge(
                        label: room.sessionStatusLabel,
                        color: statusColor,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '${DateFormat('d MMM').format(room.scheduledStart)} • '
                          '${DateFormat('HH:mm').format(room.scheduledStart)}–'
                          '${DateFormat('HH:mm').format(room.scheduledEnd)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Icon(
              room.isUpcoming
                  ? Icons.lock_clock_rounded
                  : Icons.chevron_right_rounded,
              color: room.isUpcoming
                  ? const Color(0xFFD68A1F)
                  : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.forum_outlined,
            size: 54,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No Chat Rooms Yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Room dibuat otomatis setelah pembayaran konsultasi online disetujui admin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              height: 1.5,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Gagal memuat chat.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
