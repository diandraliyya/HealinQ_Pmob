import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/admin_user_model.dart';
import '../../models/content_models.dart';
import '../../services/admin_content_service.dart';
import '../../services/admin_user_service.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() =>
      _AdminUsersScreenState();
}

class _AdminUsersScreenState
    extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  static const int _rowsPerPage = 10;

  final AdminUserService _userService =
      AdminUserService();

  final AdminContentService _contentService =
      AdminContentService();

  final TextEditingController
      _searchController =
      TextEditingController();

  late final TabController _tabController;

  List<AdminUserModel> _users =
      <AdminUserModel>[];

  List<LyricContentModel> _lyrics =
      <LyricContentModel>[];

  List<JarItemContentModel> _jarItems =
      <JarItemContentModel>[];

  List<PassionCategoryContentModel>
      _categories =
      <PassionCategoryContentModel>[];

  List<PassionQuestionContentModel>
      _questions =
      <PassionQuestionContentModel>[];

  String _selectedStatus = 'all';
  String? _errorMessage;
  String? _processingId;

  bool _isLoading = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 4,
      vsync: this,
    );

    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<dynamic> result =
          await Future.wait<dynamic>(
        <Future<dynamic>>[
          _userService.getAllUsers(),
          _contentService.getAllLyrics(),
          _contentService.getAllJarItems(),
          _contentService.getCategories(),
          _contentService
              .getAllPassionQuestions(),
        ],
      );

      if (!mounted) return;

      setState(() {
        _users =
            result[0] as List<AdminUserModel>;
        _lyrics = result[1]
            as List<LyricContentModel>;
        _jarItems = result[2]
            as List<JarItemContentModel>;
        _categories = result[3]
            as List<
                PassionCategoryContentModel>;
        _questions = result[4]
            as List<
                PassionQuestionContentModel>;
        _currentPage = 1;
        _errorMessage = null;
      });
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

  List<AdminUserModel>
      get _filteredUsers {
    final String query =
        _searchController.text
            .trim()
            .toLowerCase();

    final List<AdminUserModel> result =
        _users.where(
      (AdminUserModel user) {
        final bool matchesSearch =
            query.isEmpty ||
                user.fullName
                    .toLowerCase()
                    .contains(query) ||
                user.username
                    .toLowerCase()
                    .contains(query) ||
                user.email
                    .toLowerCase()
                    .contains(query) ||
                (user.address ?? '')
                    .toLowerCase()
                    .contains(query);

        final bool matchesStatus =
            _selectedStatus == 'all' ||
                user.status ==
                    _selectedStatus;

        return matchesSearch &&
            matchesStatus;
      },
    ).toList();

    result.sort(
      (
        AdminUserModel first,
        AdminUserModel second,
      ) =>
          second.createdAt.compareTo(
        first.createdAt,
      ),
    );

    return result;
  }

  int get _totalPages {
    if (_filteredUsers.isEmpty) {
      return 1;
    }

    return (_filteredUsers.length /
            _rowsPerPage)
        .ceil();
  }

  List<AdminUserModel>
      get _pageUsers {
    final int page =
        _currentPage
            .clamp(
              1,
              _totalPages,
            )
            .toInt();

    final int start =
        (page - 1) * _rowsPerPage;

    if (start >= _filteredUsers.length) {
      return <AdminUserModel>[];
    }

    final int end =
        (start + _rowsPerPage)
            .clamp(
              0,
              _filteredUsers.length,
            )
            .toInt();

    return _filteredUsers.sublist(
      start,
      end,
    );
  }

  int _countUserStatus(String status) {
    return _users
        .where(
          (AdminUserModel user) =>
              user.status == status,
        )
        .length;
  }

  Future<void> _changeUserStatus(
    AdminUserModel user,
  ) async {
    String selectedStatus =
        user.status;

    final String? result =
        await showDialog<String>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(
              void Function(),
            ) setDialogState,
          ) {
            return AlertDialog(
              backgroundColor:
                  AppColors.white,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
              title: Text(
                'Manage User Status',
                style: GoogleFonts.poppins(
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.primary,
                ),
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: <Widget>[
                  Text(
                    user.fullName,
                    style:
                        GoogleFonts.poppins(
                      fontWeight:
                          FontWeight.w700,
                      color:
                          AppColors.textDark,
                    ),
                  ),
                  Text(
                    user.email,
                    style:
                        GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors
                          .textMedium,
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<
                      String>(
                    value:
                        selectedStatus,
                    items: const <
                        DropdownMenuItem<
                            String>>[
                      DropdownMenuItem<
                          String>(
                        value: 'active',
                        child:
                            Text('Active'),
                      ),
                      DropdownMenuItem<
                          String>(
                        value: 'inactive',
                        child:
                            Text('Inactive'),
                      ),
                      DropdownMenuItem<
                          String>(
                        value:
                            'suspended',
                        child: Text(
                          'Suspended',
                        ),
                      ),
                    ],
                    onChanged: (
                      String? value,
                    ) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedStatus =
                            value;
                      });
                    },
                    decoration:
                        InputDecoration(
                      filled: true,
                      fillColor:
                          AppColors
                              .primarySoft,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selectedStatus ==
                            'active'
                        ? 'User dapat login dan menggunakan fitur.'
                        : selectedStatus ==
                                'inactive'
                            ? 'Akun dinonaktifkan sementara tanpa menghapus data.'
                            : 'Akun dibatasi secara administratif tanpa menghapus riwayat.',
                    style:
                        GoogleFonts.poppins(
                      fontSize: 10,
                      height: 1.5,
                      color: AppColors
                          .textMedium,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      selectedStatus ==
                              user.status
                          ? null
                          : () {
                              Navigator.of(
                                dialogContext,
                              ).pop(
                                selectedStatus,
                              );
                            },
                  style: ElevatedButton
                      .styleFrom(
                    backgroundColor:
                        selectedStatus ==
                                'suspended'
                            ? AppColors.error
                            : AppColors
                                .primary,
                    foregroundColor:
                        AppColors.white,
                  ),
                  child:
                      const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted ||
        result == null ||
        result == user.status) {
      return;
    }

    setState(() {
      _processingId = user.id;
    });

    try {
      final String message =
          await _userService.setUserStatus(
        userId: user.id,
        status: result,
      );

      final int index = _users.indexWhere(
        (AdminUserModel item) =>
            item.id == user.id,
      );

      if (index != -1 && mounted) {
        setState(() {
          _users[index] =
              _users[index].copyWith(
            status: result,
          );
        });
      }

      if (mounted) {
        _showMessage(
          message,
          isError: false,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _cleanError(error),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingId = null;
        });
      }
    }
  }

  void _showUserDetail(
    AdminUserModel user,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (
        BuildContext sheetContext,
      ) {
        return DraggableScrollableSheet(
          initialChildSize: 0.76,
          minChildSize: 0.48,
          maxChildSize: 0.94,
          expand: false,
          builder: (
            BuildContext context,
            ScrollController controller,
          ) {
            return Container(
              decoration:
                  const BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller: controller,
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color: AppColors
                            .textLight
                            .withOpacity(
                          0.35,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 31,
                        backgroundColor:
                            AppColors
                                .primarySoft,
                        child: Text(
                          user.fullName
                                  .trim()
                                  .isEmpty
                              ? 'U'
                              : user.fullName
                                  .trim()[0]
                                  .toUpperCase(),
                          style:
                              GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight:
                                FontWeight
                                    .w700,
                            color: AppColors
                                .primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: <Widget>[
                            Text(
                              user.fullName,
                              style:
                                  GoogleFonts
                                      .poppins(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color: AppColors
                                    .textDark,
                              ),
                            ),
                            Text(
                              '@${user.username}',
                              style:
                                  GoogleFonts
                                      .poppins(
                                fontSize: 11,
                                color: AppColors
                                    .textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        status: user.status,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DetailTile(
                    label: 'Email',
                    value: user.email,
                  ),
                  _DetailTile(
                    label: 'Phone',
                    value:
                        user.phone ?? '-',
                  ),
                  _DetailTile(
                    label: 'Address',
                    value:
                        user.address ?? '-',
                  ),
                  _DetailTile(
                    label: 'Gender',
                    value:
                        user.gender ?? '-',
                  ),
                  _DetailTile(
                    label: 'Birth Date',
                    value:
                        user.birthDate == null
                            ? '-'
                            : DateFormat(
                                'd MMMM yyyy',
                              ).format(
                                user.birthDate!,
                              ),
                  ),
                  _DetailTile(
                    label: 'Joined',
                    value: DateFormat(
                      'd MMMM yyyy, HH:mm',
                    ).format(
                      user.createdAt,
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MiniStat(
                          label:
                              'Consultations',
                          value:
                              '${user.consultationCount}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          label: 'Completed',
                          value:
                              '${user.completedConsultationCount}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child:
                        ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(
                          sheetContext,
                        ).pop();

                        Future<void>.delayed(
                          Duration.zero,
                          () {
                            if (mounted) {
                              _changeUserStatus(
                                user,
                              );
                            }
                          },
                        );
                      },
                      icon: const Icon(
                        Icons
                            .manage_accounts_rounded,
                      ),
                      label: const Text(
                        'Manage Account Status',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showLyricDialog({
    LyricContentModel? lyric,
  }) async {
    final TextEditingController
        titleController =
        TextEditingController(
      text: lyric?.title ?? '',
    );

    final TextEditingController
        artistController =
        TextEditingController(
      text: lyric?.artist ?? '',
    );

    final TextEditingController
        excerptController =
        TextEditingController(
      text: lyric?.lyricExcerpt ?? '',
    );

    bool isActive =
        lyric?.isActive ?? true;

    final bool? save =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(
              void Function(),
            ) setDialogState,
          ) {
            return AlertDialog(
              backgroundColor:
                  AppColors.white,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
              title: Text(
                lyric == null
                    ? 'Add Lyric'
                    : 'Edit Lyric',
                style: GoogleFonts.poppins(
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.primary,
                ),
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: <Widget>[
                    _DialogField(
                      controller:
                          titleController,
                      label: 'Song title',
                    ),
                    const SizedBox(height: 10),
                    _DialogField(
                      controller:
                          artistController,
                      label: 'Artist',
                    ),
                    const SizedBox(height: 10),
                    _DialogField(
                      controller:
                          excerptController,
                      label:
                          'Short lyric excerpt',
                      maxLines: 4,
                      maxLength: 1000,
                    ),
                    SwitchListTile(
                      value: isActive,
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Active on user pages',
                      ),
                      onChanged: (
                        bool value,
                      ) {
                        setDialogState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(false);
                  },
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController
                            .text
                            .trim()
                            .isEmpty ||
                        artistController
                            .text
                            .trim()
                            .isEmpty ||
                        excerptController
                            .text
                            .trim()
                            .isEmpty) {
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(true);
                  },
                  child:
                      const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || save != true) {
      titleController.dispose();
      artistController.dispose();
      excerptController.dispose();
      return;
    }

    setState(() {
      _processingId =
          lyric?.id ?? 'new_lyric';
    });

    try {
      await _contentService.saveLyric(
        id: lyric?.id,
        title:
            titleController.text,
        artist:
            artistController.text,
        lyricExcerpt:
            excerptController.text,
        isActive: isActive,
      );

      await _loadAll(
        showLoading: false,
      );

      if (mounted) {
        _showMessage(
          'Lyric berhasil disimpan.',
          isError: false,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _cleanError(error),
          isError: true,
        );
      }
    } finally {
      titleController.dispose();
      artistController.dispose();
      excerptController.dispose();

      if (mounted) {
        setState(() {
          _processingId = null;
        });
      }
    }
  }

  Future<void> _showJarDialog({
    JarItemContentModel? item,
  }) async {
    final TextEditingController controller =
        TextEditingController(
      text: item?.content ?? '',
    );

    String itemType =
        item?.itemType ?? 'affirmation';

    bool isActive =
        item?.isActive ?? true;

    final bool? save =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(
              void Function(),
            ) setDialogState,
          ) {
            return AlertDialog(
              backgroundColor:
                  AppColors.white,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
              title: Text(
                item == null
                    ? 'Add Jar Item'
                    : 'Edit Jar Item',
                style: GoogleFonts.poppins(
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.primary,
                ),
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<
                        String>(
                      value: itemType,
                      items: const <
                          DropdownMenuItem<
                              String>>[
                        DropdownMenuItem<
                            String>(
                          value:
                              'affirmation',
                          child: Text(
                            'Affirmation',
                          ),
                        ),
                        DropdownMenuItem<
                            String>(
                          value: 'question',
                          child:
                              Text('Question'),
                        ),
                        DropdownMenuItem<
                            String>(
                          value:
                              'challenge',
                          child: Text(
                            'Challenge',
                          ),
                        ),
                      ],
                      onChanged: (
                        String? value,
                      ) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          itemType = value;
                        });
                      },
                      decoration:
                          InputDecoration(
                        labelText: 'Type',
                        filled: true,
                        fillColor:
                            AppColors
                                .primarySoft,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            18,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DialogField(
                      controller:
                          controller,
                      label: 'Content',
                      maxLines: 5,
                      maxLength: 1000,
                    ),
                    SwitchListTile(
                      value: isActive,
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Active in Jar of Happiness',
                      ),
                      onChanged: (
                        bool value,
                      ) {
                        setDialogState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(false);
                  },
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(true);
                  },
                  child:
                      const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || save != true) {
      controller.dispose();
      return;
    }

    setState(() {
      _processingId =
          item?.id ?? 'new_jar';
    });

    try {
      await _contentService.saveJarItem(
        id: item?.id,
        itemType: itemType,
        content: controller.text,
        isActive: isActive,
      );

      await _loadAll(
        showLoading: false,
      );

      if (mounted) {
        _showMessage(
          'Jar item berhasil disimpan.',
          isError: false,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _cleanError(error),
          isError: true,
        );
      }
    } finally {
      controller.dispose();

      if (mounted) {
        setState(() {
          _processingId = null;
        });
      }
    }
  }

  Future<void> _showQuestionDialog({
    PassionQuestionContentModel? question,
  }) async {
    if (_categories.isEmpty) {
      _showMessage(
        'Kategori passion belum tersedia.',
        isError: true,
      );
      return;
    }

    final TextEditingController
        questionController =
        TextEditingController(
      text: question?.questionText ?? '',
    );

    final TextEditingController
        orderController =
        TextEditingController(
      text: '${question?.sortOrder ?? (_questions.length + 1)}',
    );

    String categoryCode =
        question?.categoryCode ??
            _categories.first.code;

    bool isActive =
        question?.isActive ?? true;

    final bool? save =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(
              void Function(),
            ) setDialogState,
          ) {
            return AlertDialog(
              backgroundColor:
                  AppColors.white,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
              title: Text(
                question == null
                    ? 'Add FYP Question'
                    : 'Edit FYP Question',
                style: GoogleFonts.poppins(
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.primary,
                ),
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<
                        String>(
                      value: categoryCode,
                      items: _categories
                          .map(
                            (
                              PassionCategoryContentModel
                                  category,
                            ) =>
                                DropdownMenuItem<
                                    String>(
                              value:
                                  category.code,
                              child: Text(
                                '${category.emoji} ${category.name}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (
                        String? value,
                      ) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          categoryCode =
                              value;
                        });
                      },
                      decoration:
                          InputDecoration(
                        labelText:
                            'Passion category',
                        filled: true,
                        fillColor:
                            AppColors
                                .primarySoft,
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            18,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DialogField(
                      controller:
                          questionController,
                      label: 'Question',
                      maxLines: 4,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 10),
                    _DialogField(
                      controller:
                          orderController,
                      label: 'Sort order',
                      keyboardType:
                          TextInputType
                              .number,
                    ),
                    SwitchListTile(
                      value: isActive,
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Active in FYP test',
                      ),
                      onChanged: (
                        bool value,
                      ) {
                        setDialogState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(false);
                  },
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (questionController
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(true);
                  },
                  child:
                      const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || save != true) {
      questionController.dispose();
      orderController.dispose();
      return;
    }

    setState(() {
      _processingId =
          question?.id ?? 'new_question';
    });

    try {
      await _contentService
          .savePassionQuestion(
        id: question?.id,
        categoryCode: categoryCode,
        questionText:
            questionController.text,
        sortOrder: int.tryParse(
              orderController.text.trim(),
            ) ??
            0,
        isActive: isActive,
      );

      await _loadAll(
        showLoading: false,
      );

      if (mounted) {
        _showMessage(
          'Pertanyaan FYP berhasil disimpan.',
          isError: false,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _cleanError(error),
          isError: true,
        );
      }
    } finally {
      questionController.dispose();
      orderController.dispose();

      if (mounted) {
        setState(() {
          _processingId = null;
        });
      }
    }
  }

  Future<void> _toggleLyric(
    LyricContentModel lyric,
  ) async {
    await _runContentAction(
      id: lyric.id,
      action: () {
        return _contentService
            .setLyricActive(
          id: lyric.id,
          isActive: !lyric.isActive,
        );
      },
      successMessage: lyric.isActive
          ? 'Lyric dinonaktifkan.'
          : 'Lyric diaktifkan.',
    );
  }

  Future<void> _toggleJar(
    JarItemContentModel item,
  ) async {
    await _runContentAction(
      id: item.id,
      action: () {
        return _contentService
            .setJarItemActive(
          id: item.id,
          isActive: !item.isActive,
        );
      },
      successMessage: item.isActive
          ? 'Jar item dinonaktifkan.'
          : 'Jar item diaktifkan.',
    );
  }

  Future<void> _toggleQuestion(
    PassionQuestionContentModel question,
  ) async {
    await _runContentAction(
      id: question.id,
      action: () {
        return _contentService
            .setPassionQuestionActive(
          id: question.id,
          isActive: !question.isActive,
        );
      },
      successMessage: question.isActive
          ? 'Pertanyaan FYP dinonaktifkan.'
          : 'Pertanyaan FYP diaktifkan.',
    );
  }

  Future<void> _runContentAction({
    required String id,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_processingId != null) return;

    setState(() {
      _processingId = id;
    });

    try {
      await action();
      await _loadAll(
        showLoading: false,
      );

      if (mounted) {
        _showMessage(
          successMessage,
          isError: false,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          _cleanError(error),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingId = null;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? AppColors.error
              : AppColors.success,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  Widget? _buildFab() {
    if (_isLoading ||
        _processingId != null) {
      return null;
    }

    switch (_tabController.index) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: () {
            _showLyricDialog();
          },
          backgroundColor:
              AppColors.primary,
          foregroundColor:
              AppColors.white,
          icon: const Icon(
            Icons.add_rounded,
          ),
          label: const Text('Add Lyric'),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: () {
            _showJarDialog();
          },
          backgroundColor:
              AppColors.primary,
          foregroundColor:
              AppColors.white,
          icon: const Icon(
            Icons.add_rounded,
          ),
          label:
              const Text('Add Jar Item'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () {
            _showQuestionDialog();
          },
          backgroundColor:
              AppColors.primary,
          foregroundColor:
              AppColors.white,
          icon: const Icon(
            Icons.add_rounded,
          ),
          label:
              const Text('Add Question'),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.bgGradientStart,
      floatingActionButton:
          _buildFab(),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _AdminContentBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                _buildHeader(),
                _buildTabs(),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(
                            color: AppColors
                                .primary,
                          ),
                        )
                      : _errorMessage !=
                              null
                          ? _buildErrorState()
                          : TabBarView(
                              controller:
                                  _tabController,
                              children: <
                                  Widget>[
                                _buildUsersTab(),
                                _buildLyricsTab(),
                                _buildJarTab(),
                                _buildFypTab(),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        10,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Users & Content',
                  style:
                      GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppColors.primary,
                  ),
                ),
                Text(
                  'Kelola akun user dan konten yang tampil di aplikasi.',
                  style:
                      GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors
                        .textMedium,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              _loadAll();
            },
            style: IconButton.styleFrom(
              backgroundColor:
                  AppColors.white
                      .withOpacity(0.92),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.92),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: TabBar(
        controller:
            _tabController,
        indicatorSize:
            TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius:
              BorderRadius.circular(16),
        ),
        indicatorPadding:
            const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 5,
        ),
        labelColor: AppColors.white,
        unselectedLabelColor:
            AppColors.primary,
        dividerColor:
            Colors.transparent,
        labelStyle:
            GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle:
            GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        tabs: const <Tab>[
          Tab(text: 'Users'),
          Tab(text: 'Lyrics'),
          Tab(text: 'Jar'),
          Tab(text: 'FYP'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(20),
      children: <Widget>[
        const SizedBox(height: 70),
        Container(
          padding:
              const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white
                .withOpacity(0.95),
            borderRadius:
                BorderRadius.circular(24),
          ),
          child: Column(
            children: <Widget>[
              const Icon(
                Icons
                    .error_outline_rounded,
                size: 50,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
                style:
                    GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors
                      .textMedium,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
              _loadAll();
            },
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label:
                    const Text('Try Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () {
        return _loadAll(
          showLoading: false,
        );
      },
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          28,
        ),
        children: <Widget>[
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.28,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            children: <Widget>[
              _StatCard(
                title: 'Total Users',
                value: '${_users.length}',
                icon:
                    Icons.people_rounded,
                color:
                    AppColors.brandBlue,
              ),
              _StatCard(
                title: 'Active',
                value:
                    '${_countUserStatus('active')}',
                icon: Icons
                    .check_circle_rounded,
                color:
                    AppColors.success,
              ),
              _StatCard(
                title: 'Inactive',
                value:
                    '${_countUserStatus('inactive')}',
                icon: Icons
                    .pause_circle_rounded,
                color: AppColors
                    .textMedium,
              ),
              _StatCard(
                title: 'Suspended',
                value:
                    '${_countUserStatus('suspended')}',
                icon:
                    Icons.block_rounded,
                color:
                    AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.all(
              14,
            ),
            decoration: BoxDecoration(
              color: AppColors.white
                  .withOpacity(0.94),
              borderRadius:
                  BorderRadius.circular(
                22,
              ),
            ),
            child: Column(
              children: <Widget>[
                TextField(
                  controller:
                      _searchController,
                  onChanged: (_) {
                    setState(() {
                      _currentPage = 1;
                    });
                  },
                  decoration:
                      InputDecoration(
                    hintText:
                        'Cari nama, username, email, atau alamat...',
                    prefixIcon:
                        const Icon(
                      Icons.search_rounded,
                    ),
                    filled: true,
                    fillColor: AppColors
                        .surfaceMuted,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection:
                        Axis.horizontal,
                    children: <Widget>[
                      for (final String status
                          in <String>[
                        'all',
                        'active',
                        'inactive',
                        'suspended',
                      ])
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            right: 8,
                          ),
                          child: ChoiceChip(
                            label: Text(
                              status == 'all'
                                  ? 'All'
                                  : status[0]
                                          .toUpperCase() +
                                      status
                                          .substring(
                                        1,
                                      ),
                            ),
                            selected:
                                _selectedStatus ==
                                    status,
                            onSelected: (_) {
                              setState(() {
                                _selectedStatus =
                                    status;
                                _currentPage =
                                    1;
                              });
                            },
                            selectedColor:
                                AppColors
                                    .primary,
                            labelStyle:
                                TextStyle(
                              color: _selectedStatus ==
                                      status
                                  ? AppColors
                                      .white
                                  : AppColors
                                      .primary,
                            ),
                            side:
                                BorderSide.none,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_pageUsers.isEmpty)
            const _EmptyCard(
              icon: Icons
                  .person_search_rounded,
              title: 'No users found',
              subtitle:
                  'Tidak ada user yang sesuai dengan filter.',
            )
          else
            ..._pageUsers.map(
              _buildUserCard,
            ),
          if (_filteredUsers.isNotEmpty)
            _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    AdminUserModel user,
  ) {
    final bool processing =
        _processingId == user.id;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.95),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 25,
                backgroundColor:
                    AppColors.primarySoft,
                child: Text(
                  user.fullName
                          .trim()
                          .isEmpty
                      ? 'U'
                      : user.fullName
                          .trim()[0]
                          .toUpperCase(),
                  style:
                      GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: <Widget>[
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                        color: AppColors
                            .textDark,
                      ),
                    ),
                    Text(
                      '@${user.username}',
                      style:
                          GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors
                            .primary,
                      ),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors
                            .textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                status: user.status,
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: <Widget>[
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: processing
                      ? null
                      : () {
                          _showUserDetail(
                            user,
                          );
                        },
                  icon: const Icon(
                    Icons
                        .visibility_outlined,
                  ),
                  label:
                      const Text('View'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed: processing
                      ? null
                      : () {
                          _changeUserStatus(
                            user,
                          );
                        },
                  icon: processing
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                AppColors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .manage_accounts_rounded,
                        ),
                  label:
                      const Text('Status'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.94),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: const Icon(
              Icons
                  .chevron_left_rounded,
            ),
          ),
          Expanded(
            child: Text(
              'Page $_currentPage of $_totalPages • '
              '${_filteredUsers.length} users',
              textAlign:
                  TextAlign.center,
              style:
                  GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors
                    .textMedium,
              ),
            ),
          ),
          IconButton(
            onPressed: _currentPage <
                    _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            icon: const Icon(
              Icons
                  .chevron_right_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsTab() {
    return _ContentListWrapper(
      onRefresh: () {
        return _loadAll(
          showLoading: false,
        );
      },
      children: <Widget>[
        _ContentSummary(
          title: 'Lyric of the Day',
          total: _lyrics.length,
          active: _lyrics
              .where(
                (
                  LyricContentModel lyric,
                ) =>
                    lyric.isActive,
              )
              .length,
          icon: Icons.music_note_rounded,
        ),
        const SizedBox(height: 14),
        if (_lyrics.isEmpty)
          const _EmptyCard(
            icon: Icons.music_off_rounded,
            title: 'No lyrics yet',
            subtitle:
                'Tambah lyric agar tampil di Home dan FYP user.',
          )
        else
          ..._lyrics.map(
            (LyricContentModel lyric) =>
                _ContentCard(
              active: lyric.isActive,
              leadingIcon:
                  Icons.music_note_rounded,
              title: lyric.title,
              subtitle: lyric.artist,
              content: lyric.lyricExcerpt,
              processing:
                  _processingId == lyric.id,
              onEdit: () {
                _showLyricDialog(
                  lyric: lyric,
                );
              },
              onToggle: () {
                _toggleLyric(lyric);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildJarTab() {
    return _ContentListWrapper(
      onRefresh: () {
        return _loadAll(
          showLoading: false,
        );
      },
      children: <Widget>[
        _ContentSummary(
          title: 'Jar of Happiness',
          total: _jarItems.length,
          active: _jarItems
              .where(
                (
                  JarItemContentModel item,
                ) =>
                    item.isActive,
              )
              .length,
          icon: Icons.favorite_rounded,
        ),
        const SizedBox(height: 14),
        if (_jarItems.isEmpty)
          const _EmptyCard(
            icon:
                Icons.inventory_2_outlined,
            title: 'No jar items yet',
            subtitle:
                'Tambah affirmation, question, atau challenge.',
          )
        else
          ..._jarItems.map(
            (
              JarItemContentModel item,
            ) =>
                _ContentCard(
              active: item.isActive,
              leadingIcon:
                  item.itemType ==
                          'question'
                      ? Icons
                          .help_outline_rounded
                      : item.itemType ==
                              'challenge'
                          ? Icons
                              .flag_rounded
                          : Icons
                              .favorite_rounded,
              title: item.itemType
                  .toUpperCase(),
              subtitle:
                  'Jar of Happiness',
              content: item.content,
              processing:
                  _processingId == item.id,
              onEdit: () {
                _showJarDialog(
                  item: item,
                );
              },
              onToggle: () {
                _toggleJar(item);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFypTab() {
    return _ContentListWrapper(
      onRefresh: () {
        return _loadAll(
          showLoading: false,
        );
      },
      children: <Widget>[
        _ContentSummary(
          title: 'Find Your Passion',
          total: _questions.length,
          active: _questions
              .where(
                (
                  PassionQuestionContentModel
                      question,
                ) =>
                    question.isActive,
              )
              .length,
          icon: Icons.psychology_rounded,
        ),
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white
                .withOpacity(0.9),
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Text(
            'User akan mengerjakan seluruh pertanyaan aktif. '
            'Gunakan tombol nonaktifkan daripada menghapus agar '
            'riwayat hasil lama tetap aman.',
            style:
                GoogleFonts.poppins(
              fontSize: 10,
              height: 1.5,
              color:
                  AppColors.textMedium,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_questions.isEmpty)
          const _EmptyCard(
            icon:
                Icons.psychology_outlined,
            title: 'No questions yet',
            subtitle:
                'Tambah pertanyaan dan pilih kategori passion.',
          )
        else
          ..._questions.map(
            (
              PassionQuestionContentModel
                  question,
            ) =>
                _ContentCard(
              active: question.isActive,
              leadingIcon:
                  Icons.psychology_rounded,
              title:
                  '${question.sortOrder}. '
                  '${question.categoryEmoji} '
                  '${question.categoryName}',
              subtitle:
                  question.categoryCode,
              content:
                  question.questionText,
              processing:
                  _processingId ==
                      question.id,
              onEdit: () {
                _showQuestionDialog(
                  question: question,
                );
              },
              onToggle: () {
                _toggleQuestion(
                  question,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DialogField
    extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final int? maxLength;
  final TextInputType keyboardType;

  const _DialogField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType =
        TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.primarySoft,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ContentListWrapper
    extends StatelessWidget {
  final Future<void> Function()
      onRefresh;
  final List<Widget> children;

  const _ContentListWrapper({
    required this.onRefresh,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          100,
        ),
        children: children,
      ),
    );
  }
}

class _ContentSummary
    extends StatelessWidget {
  final String title;
  final int total;
  final int active;
  final IconData icon;

  const _ContentSummary({
    required this.title,
    required this.total,
    required this.active,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.94),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor:
                AppColors.primarySoft,
            child: Icon(
              icon,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style:
                  GoogleFonts.poppins(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
                color:
                    AppColors.textDark,
              ),
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$active active',
                style:
                    GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.success,
                ),
              ),
              Text(
                '$total total',
                style:
                    GoogleFonts.poppins(
                  fontSize: 10,
                  color:
                      AppColors.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentCard
    extends StatelessWidget {
  final bool active;
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final String content;
  final bool processing;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _ContentCard({
    required this.active,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.processing,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(
          active ? 0.95 : 0.75,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    AppColors.primarySoft,
                child: Icon(
                  leadingIcon,
                  color:
                      AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: <Widget>[
                    Text(
                      title,
                      style:
                          GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color: AppColors
                            .textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style:
                          GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors
                            .textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              _ActiveBadge(
                active: active,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style:
                GoogleFonts.poppins(
              fontSize: 12,
              height: 1.5,
              color:
                  AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      processing
                          ? null
                          : onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label:
                      const Text('Edit'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed:
                      processing
                          ? null
                          : onToggle,
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        active
                            ? AppColors
                                .textMedium
                            : AppColors
                                .success,
                    foregroundColor:
                        AppColors.white,
                  ),
                  icon: processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                AppColors.white,
                          ),
                        )
                      : Icon(
                          active
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                        ),
                  label: Text(
                    active
                        ? 'Deactivate'
                        : 'Activate',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge
    extends StatelessWidget {
  final bool active;

  const _ActiveBadge({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = active
        ? AppColors.success
        : AppColors.textMedium;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge
    extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        status == 'active'
            ? AppColors.success
            : status == 'suspended'
                ? AppColors.error
                : AppColors.textMedium;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DetailTile
    extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 9,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style:
                GoogleFonts.poppins(
              fontSize: 9,
              color:
                  AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style:
                GoogleFonts.poppins(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color:
                  AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat
    extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primary
              .withOpacity(0.12),
        ),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style:
                GoogleFonts.poppins(
              fontSize: 17,
              fontWeight:
                  FontWeight.w700,
              color:
                  AppColors.primary,
            ),
          ),
          Text(
            label,
            style:
                GoogleFonts.poppins(
              fontSize: 9,
              color:
                  AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.94),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor:
                color.withOpacity(0.12),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style:
                GoogleFonts.poppins(
              fontSize: 21,
              fontWeight:
                  FontWeight.w800,
              color:
                  AppColors.textDark,
            ),
          ),
          Text(
            title,
            style:
                GoogleFonts.poppins(
              fontSize: 10,
              color:
                  AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.94),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style:
                GoogleFonts.poppins(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
              color:
                  AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign:
                TextAlign.center,
            style:
                GoogleFonts.poppins(
              fontSize: 10,
              color:
                  AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminContentBackground
    extends StatelessWidget {
  const _AdminContentBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _ContentBlob(
          alignment:
              Alignment.topLeft,
          widthFactor: 0.78,
          heightFactor: 0.28,
          color: AppColors.blobPink,
          opacity: 0.95,
        ),
        _ContentBlob(
          alignment:
              Alignment.topRight,
          widthFactor: 0.82,
          heightFactor: 0.30,
          color: AppColors.blobTeal,
          opacity: 0.34,
        ),
        _ContentBlob(
          alignment:
              Alignment.centerLeft,
          widthFactor: 1.02,
          heightFactor: 0.56,
          color: AppColors.blobBlue,
          opacity: 0.28,
        ),
      ],
    );
  }
}

class _ContentBlob
    extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
  final Color color;
  final double opacity;

  const _ContentBlob({
    required this.alignment,
    required this.widthFactor,
    required this.heightFactor,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final Size size =
        MediaQuery.of(context).size;

    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width:
              size.width * widthFactor,
          height:
              size.height * heightFactor,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                color.withOpacity(
                  opacity,
                ),
                color.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
