import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_data.dart';
import '../../models/models.dart';
import 'room_chat_screen.dart';

class MessageListScreen extends StatelessWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFB2EBF2), Color(0xFFFCE4EC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary)),
                    Expanded(child: Text('Massage', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded, color: AppColors.primary)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: AppData.counselors.length,
                  itemBuilder: (ctx, i) {
                    final c = AppData.counselors[i];
                    return _buildMessageItem(context, c, i == 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, CounselorModel counselor, bool isAvailable) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoomChatScreen(counselor: counselor))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 28, backgroundColor: Color(0xFFE0E0E0), child: Icon(Icons.person, color: Colors.grey, size: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(counselor.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1A1A2E))),
                  Text(isAvailable ? 'Available' : 'Expired', style: GoogleFonts.poppins(fontSize: 12, color: isAvailable ? AppColors.success : AppColors.textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
