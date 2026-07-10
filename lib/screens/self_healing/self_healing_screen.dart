import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/content_models.dart';
import '../../services/content_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_state.dart';
import '../../models/models.dart';

class SelfHealingScreen extends StatefulWidget {
  const SelfHealingScreen({super.key});

  @override
  State<SelfHealingScreen> createState() => _SelfHealingScreenState();
}

class _SelfHealingScreenState extends State<SelfHealingScreen> {
  final ContentService _contentService =
      ContentService();

  List<JarItemContentModel> _jarItems =
      <JarItemContentModel>[];

  String? _jarMessage;
  String? _jarError;
  bool _isLoadingJar = true;

  @override
  void initState() {
    super.initState();
    _loadJarItems();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AppState>().loadJournals().catchError((_) {});
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait<void>(<Future<void>>[
      _loadJarItems(),
      context.read<AppState>().loadJournals(force: true),
    ]);
  }

  Future<void> _loadJarItems() async {
    try {
      final List<JarItemContentModel> result =
          await _contentService.getActiveJarItems();

      if (!mounted) return;

      setState(() {
        _jarItems = result;
        _jarError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _jarError = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            )
            .trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingJar = false;
        });
      }
    }
  }

  void _pickFromJar() {
    if (_isLoadingJar) {
      return;
    }

    if (_jarItems.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _jarError ??
                  'Belum ada Jar of Happiness yang aktif.',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final Random random = Random();
    final JarItemContentModel item =
        _jarItems[random.nextInt(_jarItems.length)];

    final popupColors = [
      const Color(0xFFFCE4EC),
      const Color(0xFFE0F7FA),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF3E0),
      const Color(0xFFEDE7F6),
      const Color(0xFFFFF9C4),
      const Color(0xFFD7FBE8),
      const Color(0xFFFFE5F4),
    ];

    final popupBg = popupColors[random.nextInt(popupColors.length)];

    setState(() {
      _jarMessage = item.content;
    });

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: popupBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: AppColors.white.withOpacity(0.9),
                width: 4,
              ),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '✨',
                  style: TextStyle(fontSize: 34),
                ),
                const SizedBox(height: 12),
                Text(
                  'Jar of Happiness',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: Text(
                      _jarMessage ?? '',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final journals = [...state.journals]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final now = DateTime.now();
    final todayJournals =
        journals.where((j) => _isSameDay(j.createdAt, now)).toList();
    final previousJournals =
        journals.where((j) => !_isSameDay(j.createdAt, now)).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB2EBF2), Color(0xFFFCE4EC)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Self Healing',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh Data',
                    onPressed: _isLoadingJar || state.isLoadingJournals
                        ? null
                        : () {
                            _refreshAll().catchError((error) {
                              if (!mounted) return;

                              _showMessage(
                                _cleanError(error),
                                isError: true,
                              );
                            });
                          },
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildJarCard(),
                    const SizedBox(height: 20),
                    _buildJournalingHeader(
                      totalNotes: journals.length,
                      todayCount: todayJournals.length,
                    ),
                    const SizedBox(height: 16),
                    _buildQuickMessage(),
                    const SizedBox(height: 16),
                    if (state.isLoadingJournals && journals.isEmpty)
                      _buildJournalLoading()
                    else if (state.journalError != null &&
                        journals.isEmpty)
                      _buildJournalError(state.journalError!)
                    else ...<Widget>[
                      _buildSectionTitle(
                        title: 'Today\'s Notes',
                        icon: Icons.today_rounded,
                      ),
                      const SizedBox(height: 10),
                      if (todayJournals.isEmpty)
                        _buildEmptyTodayJournal()
                      else
                        ...todayJournals.map(
                          (JournalModel journal) =>
                              _buildJournalCard(journal),
                        ),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        title: 'Track Record Notes',
                        icon: Icons.history_rounded,
                      ),
                      const SizedBox(height: 10),
                      if (previousJournals.isEmpty)
                        _buildEmptyTrackRecord()
                      else
                        ...previousJournals.map(
                          (JournalModel journal) =>
                              _buildJournalCard(journal),
                        ),
                    ],
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildJournalError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 38,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              context
                  .read<AppState>()
                  .loadJournals(force: true)
                  .catchError((error) {
                if (!mounted) return;
                _showMessage(
                  _cleanError(error),
                  isError: true,
                );
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildJarCard() {
    return GestureDetector(
      onTap: _pickFromJar,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFFCE4EC)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              'Jar of Happiness',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              _isLoadingJar
                  ? 'Loading happiness jar...'
                  : _jarItems.isEmpty
                      ? 'Belum ada content aktif'
                      : 'Pick one to brighten up your day',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMedium,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/jar.png',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  width: 160,
                  height: 160,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalingHeader({
    required int totalNotes,
    required int todayCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB2EBF2), Color(0xFFE0F7FA)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Journaling',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Write your feelings, save your notes, and track your healing journey.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textMedium,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showAddJournalDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Note',
                        style: GoogleFonts.poppins(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniInfoCard(
                  'Total Notes',
                  '$totalNotes',
                  Icons.notes_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniInfoCard(
                  'Today',
                  '$todayCount',
                  Icons.edit_calendar_rounded,
                  AppColors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.favorite_border_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Keep writing. Even small notes matter.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTodayJournal() {
    return GestureDetector(
      onTap: () => _showAddJournalDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.note_add_rounded,
              color: AppColors.primary,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada note untuk hari ini',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap di sini atau tekan Add Note untuk mulai menulis.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTrackRecord() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Belum ada track record notes sebelumnya.',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textMedium,
        ),
      ),
    );
  }

  Widget _buildJournalCard(JournalModel journal) {
    final dateLabel = DateFormat('EEEE, d MMM yyyy').format(journal.createdAt);
    final timeLabel = DateFormat('HH:mm').format(journal.createdAt);

    return GestureDetector(
      onTap: () => _showJournalDetail(context, journal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      journal.moodTag ?? '😊',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journal.title.isEmpty ? 'Untitled Note' : journal.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        journal.content,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textMedium,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dateLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showJournalDetail(context, journal),
                icon: const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Read Note',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddJournalDialog(BuildContext context) {
    _showJournalEditor();
  }

  Future<void> _showJournalEditor({
    JournalModel? journal,
  }) async {
    final bool isEditing = journal != null;
    final TextEditingController titleCtrl = TextEditingController(
      text: journal?.title ?? '',
    );
    final TextEditingController contentCtrl = TextEditingController(
      text: journal?.content ?? '',
    );

    String selectedMood = journal?.moodTag ?? '😊';
    bool isSaving = false;

    const List<String> moods = <String>[
      '😊', '😔', '😢', '😡', '😌', '🥰', '😰', '😴',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(void Function()) setModalState,
          ) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isEditing
                        ? 'Edit Journal Entry'
                        : 'New Journal Entry',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEditing
                        ? 'Perbarui catatan dan perasaanmu.'
                        : 'Write whatever you feel today.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'How are you feeling?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: moods.map((String mood) {
                      final bool isSelected = selectedMood == mood;

                      return GestureDetector(
                        onTap: isSaving
                            ? null
                            : () {
                                setModalState(() {
                                  selectedMood = mood;
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primarySoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            mood,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    enabled: !isSaving,
                    maxLength: 120,
                    decoration: InputDecoration(
                      hintText: 'Title (optional)',
                      hintStyle: GoogleFonts.poppins(
                        color: AppColors.textLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: contentCtrl,
                      enabled: !isSaving,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Write your thoughts here...',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.textLight,
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop();
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (contentCtrl.text.trim().isEmpty) {
                                    _showMessage(
                                      'Isi note dulu ya.',
                                      isError: true,
                                    );
                                    return;
                                  }

                                  setModalState(() {
                                    isSaving = true;
                                  });

                                  try {
                                    if (isEditing) {
                                      await this
                                          .context
                                          .read<AppState>()
                                          .updateJournal(
                                            journalId: journal!.id,
                                            title: titleCtrl.text,
                                            content: contentCtrl.text,
                                            moodTag: selectedMood,
                                          );
                                    } else {
                                      await this
                                          .context
                                          .read<AppState>()
                                          .createJournal(
                                            title: titleCtrl.text,
                                            content: contentCtrl.text,
                                            moodTag: selectedMood,
                                          );
                                    }

                                    if (!sheetContext.mounted) return;
                                    Navigator.of(sheetContext).pop();

                                    _showMessage(
                                      isEditing
                                          ? 'Journal berhasil diperbarui.'
                                          : 'Journal berhasil disimpan.',
                                      isError: false,
                                    );
                                  } catch (error) {
                                    if (!mounted) return;

                                    _showMessage(
                                      _cleanError(error),
                                      isError: true,
                                    );

                                    if (sheetContext.mounted) {
                                      setModalState(() {
                                        isSaving = false;
                                      });
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text(
                                  isEditing
                                      ? 'Save Changes'
                                      : 'Save Journal',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    contentCtrl.dispose();
  }

  void _showJournalDetail(
    BuildContext context,
    JournalModel journal,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final bool wasEdited = journal.updatedAt
                .difference(journal.createdAt)
                .abs()
                .inSeconds >
            1;

        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        journal.moodTag ?? '😊',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          journal.title.isEmpty
                              ? 'Untitled Note'
                              : journal.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy - HH:mm',
                          ).format(journal.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                        if (wasEdited) ...<Widget>[
                          const SizedBox(height: 3),
                          Text(
                            'Edited ${DateFormat('d MMM yyyy - HH:mm').format(journal.updatedAt)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Your note record',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    journal.content,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textMedium,
                      height: 1.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();

                        Future<void>.delayed(
                          Duration.zero,
                          () {
                            if (mounted) {
                              _showJournalEditor(journal: journal);
                            }
                          },
                        );
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();

                        Future<void>.delayed(
                          Duration.zero,
                          () {
                            if (mounted) {
                              _confirmDeleteJournal(journal);
                            }
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteJournal(
    JournalModel journal,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Delete Journal?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          content: Text(
            'Journal yang dihapus tidak dapat dikembalikan.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<AppState>().deleteJournal(journal.id);

      if (!mounted) return;

      _showMessage(
        'Journal berhasil dihapus.',
        isError: false,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanError(error),
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? AppColors.error
              : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }
}
