import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';

class RoomChatScreen extends StatefulWidget {
  final CounselorModel counselor;
  final ConsultationModel? consultation;

  const RoomChatScreen({
    super.key,
    required this.counselor,
    this.consultation,
  });

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late final List<MessageModel> _messages;

  @override
  void initState() {
    super.initState();

    _messages = _initialMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  List<MessageModel> _initialMessages() {
    final now = DateTime.now();
    final notes = widget.consultation?.notes;

    final messages = <MessageModel>[
      MessageModel(
        id: 1,
        content:
            'Halo, saya ${widget.counselor.name}. Terima kasih sudah membuat jadwal konsultasi.',
        role: 'counselor',
        createdAt: now.subtract(const Duration(minutes: 3)),
      ),
    ];

    if (notes != null && notes.trim().isNotEmpty) {
      messages.add(
        MessageModel(
          id: 2,
          content: notes.trim(),
          role: 'user',
          createdAt: now.subtract(const Duration(minutes: 2)),
        ),
      );

      messages.add(
        MessageModel(
          id: 3,
          content:
              'Saya sudah membaca ceritamu. Kamu bisa lanjut cerita di sini dengan aman dan nyaman.',
          role: 'counselor',
          createdAt: now.subtract(const Duration(minutes: 1)),
        ),
      );
    } else {
      messages.add(
        MessageModel(
          id: 2,
          content:
              'Silakan ceritakan apa yang sedang kamu rasakan. Saya siap mendengarkan.',
          role: 'counselor',
          createdAt: now.subtract(const Duration(minutes: 1)),
        ),
      );
    }

    return messages;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        MessageModel(
          id: _messages.length + 1,
          content: text,
          role: 'user',
          createdAt: DateTime.now(),
        ),
      );
      _msgCtrl.clear();
    });

    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _messages.add(
          MessageModel(
            id: _messages.length + 1,
            content:
                'Terima kasih sudah berbagi. Saya memahami perasaanmu. Mari kita bahas pelan-pelan bersama.',
            role: 'counselor',
            createdAt: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollCtrl.hasClients) return;

      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final consultation = widget.consultation;

    final subtitle = consultation == null
        ? 'Online Consultation'
        : '${consultation.type} • ${DateFormat('d MMM, HH.00').format(consultation.scheduledAt)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.black87,
          ),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.secondaryLight,
              child: Icon(
                Icons.person,
                color: AppColors.teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.counselor.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (consultation != null) _buildSessionInfo(consultation),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildBubble(_messages[index]);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(ConsultationModel consultation) {
    final dateText = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(consultation.scheduledAt);

    final timeText = DateFormat('HH.00').format(consultation.scheduledAt);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$dateText • $timeText WIB',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(MessageModel message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : const Color(0xFFFFE4EE),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isUser ? AppColors.white : AppColors.textDark,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}