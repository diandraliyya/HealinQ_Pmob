import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class CounselorChatListScreen extends StatefulWidget {
  const CounselorChatListScreen({super.key});

  @override
  State<CounselorChatListScreen> createState() =>
      _CounselorChatListScreenState();
}

class _CounselorChatListScreenState extends State<CounselorChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_CounselorChatItem> _chatItems = const [
    _CounselorChatItem(
      id: 1,
      userName: 'Alya Putri',
      lastMessage: 'Dok, saya akhir-akhir ini sering merasa cemas.',
      time: '08:10',
      unreadCount: 2,
      status: 'Online',
      topic: 'Anxiety',
    ),
    _CounselorChatItem(
      id: 2,
      userName: 'Nadhif Ramadhan',
      lastMessage: 'Saya ingin konsultasi tentang stress kuliah.',
      time: '09:25',
      unreadCount: 1,
      status: 'Online',
      topic: 'Stress Management',
    ),
    _CounselorChatItem(
      id: 3,
      userName: 'Citra Maharani',
      lastMessage: 'Terima kasih dok, saya akan coba sarannya.',
      time: 'Yesterday',
      unreadCount: 0,
      status: 'Offline',
      topic: 'Self-Esteem',
    ),
    _CounselorChatItem(
      id: 4,
      userName: 'Raka Pratama',
      lastMessage: 'Apakah saya bisa jadwalkan sesi lanjutan?',
      time: 'Yesterday',
      unreadCount: 0,
      status: 'Offline',
      topic: 'Career Confusion',
    ),
  ];

  List<_CounselorChatItem> get _filteredChats {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return _chatItems;

    return _chatItems.where((chat) {
      return chat.userName.toLowerCase().contains(query) ||
          chat.lastMessage.toLowerCase().contains(query) ||
          chat.topic.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChatRoom(_CounselorChatItem chat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CounselorChatPreviewScreen(chat: chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgGradientStart,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _CounselorChatBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'User Chat',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Balas pesan dan lanjutkan konsultasi dengan user.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Search box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search user or topic...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMedium,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: _filteredChats.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = _filteredChats[index];
                            return _ChatUserCard(
                              chat: chat,
                              onTap: () => _openChatRoom(chat),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 52,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              'No chat found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba cari dengan nama user atau topik lain.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatUserCard extends StatelessWidget {
  final _CounselorChatItem chat;
  final VoidCallback onTap;

  const _ChatUserCard({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = chat.status == 'Online';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.secondaryLight,
                      child: Icon(
                        Icons.person,
                        color: AppColors.teal,
                        size: 32,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppColors.success
                              : AppColors.textLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Text(
                            chat.time,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              chat.topic,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (chat.unreadCount > 0)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${chat.unreadCount}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CounselorChatPreviewScreen extends StatefulWidget {
  final _CounselorChatItem chat;

  const _CounselorChatPreviewScreen({
    required this.chat,
  });

  @override
  State<_CounselorChatPreviewScreen> createState() =>
      _CounselorChatPreviewScreenState();
}

class _CounselorChatPreviewScreenState
    extends State<_CounselorChatPreviewScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final List<_PreviewMessage> _messages = [
    _PreviewMessage(
      content: 'Halo dok, saya ingin konsultasi.',
      role: 'user',
    ),
    _PreviewMessage(
      content: 'Halo, tentu. Boleh ceritakan apa yang sedang kamu rasakan?',
      role: 'counselor',
    ),
    _PreviewMessage(
      content: widget.chat.lastMessage,
      role: 'user',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _PreviewMessage(
          content: text,
          role: 'counselor',
        ),
      );
      _messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.primary,
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
                    widget.chat.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    widget.chat.status,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: widget.chat.status == 'Online'
                          ? AppColors.success
                          : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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

  Widget _buildBubble(_PreviewMessage message) {
    final isCounselor = message.role == 'counselor';

    return Align(
      alignment: isCounselor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isCounselor ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isCounselor ? 18 : 4),
            bottomRight: Radius.circular(isCounselor ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isCounselor ? AppColors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Reply as counselor...',
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
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

class _CounselorChatItem {
  final int id;
  final String userName;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String status;
  final String topic;

  const _CounselorChatItem({
    required this.id,
    required this.userName,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.status,
    required this.topic,
  });
}

class _PreviewMessage {
  final String content;
  final String role;

  const _PreviewMessage({
    required this.content,
    required this.role,
  });
}

class _CounselorChatBackground extends StatelessWidget {
  const _CounselorChatBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        _CounselorChatBlob(
          alignment: Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _CounselorChatBlob(
          alignment: Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _CounselorChatBlob(
          alignment: Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
        _CounselorChatBlob(
          alignment: Alignment.bottomRight,
          widthFactor: 0.60,
          heightFactor: 0.22,
          color: AppColors.blobPink,
          opacity: 0.30,
        ),
      ],
    );
  }
}

class _CounselorChatBlob extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _CounselorChatBlob({
    required this.alignment,
    required this.widthFactor,
    required this.heightFactor,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size.width * widthFactor,
          height: size.height * heightFactor,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(opacity),
                color.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}