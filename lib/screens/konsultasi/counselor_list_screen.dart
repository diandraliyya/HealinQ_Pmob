import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_counselor_model.dart';
import '../../services/user_consultation_service.dart';
import '../../theme/app_theme.dart';
import 'booking_form_screen.dart';

class CounselorListScreen
    extends StatefulWidget {
  final bool isOffline;

  const CounselorListScreen({
    super.key,
    required this.isOffline,
  });

  @override
  State<CounselorListScreen> createState() =>
      _CounselorListScreenState();
}

class _CounselorListScreenState
    extends State<CounselorListScreen> {
  final UserConsultationService _service =
      UserConsultationService();

  final TextEditingController
      _searchController =
      TextEditingController();

  List<UserCounselorModel> _counselors =
      <UserCounselorModel>[];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCounselors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCounselors({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<UserCounselorModel>
          result =
          await _service.getCounselors(
        offline: widget.isOffline,
      );

      if (!mounted) return;

      setState(() {
        _counselors = result;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error
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
          _isLoading = false;
        });
      }
    }
  }

  List<UserCounselorModel>
      get _filteredCounselors {
    final String query =
        _searchController.text
            .trim()
            .toLowerCase();

    if (query.isEmpty) {
      return _counselors;
    }

    return _counselors.where(
      (UserCounselorModel counselor) {
        return counselor.name
                .toLowerCase()
                .contains(query) ||
            counselor.specialization
                .toLowerCase()
                .contains(query) ||
            counselor.location
                .toLowerCase()
                .contains(query);
      },
    ).toList();
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
                  onRefresh: () {
                    return _loadCounselors(
                      showLoading: false,
                    );
                  },
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
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        16,
        8,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              widget.isOffline
                  ? 'Offline Consultation'
                  : 'Online Consultation',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _loadCounselors,
            style: IconButton.styleFrom(
              backgroundColor:
                  AppColors.white
                      .withOpacity(0.9),
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

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 220),
          Center(
            child:
                CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const SizedBox(height: 80),
          _buildErrorState(),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        18,
        4,
        18,
        28,
      ),
      children: <Widget>[
        Text(
          'Pilih counselor yang memiliki '
          'slot ${widget.isOffline ? 'offline' : 'online'} '
          'tersedia.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          onChanged: (_) {
            setState(() {});
          },
          style: GoogleFonts.poppins(
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText:
                'Cari nama, spesialisasi, atau lokasi...',
            prefixIcon:
                const Icon(
              Icons.search_rounded,
            ),
            suffixIcon:
                _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController
                              .clear();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
            filled: true,
            fillColor: AppColors.white
                .withOpacity(0.92),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(20),
              borderSide:
                  BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_filteredCounselors.isEmpty)
          _buildEmptyState()
        else
          ..._filteredCounselors.map(
            _buildCounselorCard,
          ),
      ],
    );
  }

  Widget _buildCounselorCard(
    UserCounselorModel counselor,
  ) {
    final double price =
        widget.isOffline
            ? counselor.priceOffline
            : counselor.priceOnline;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.94),
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 30,
                backgroundColor:
                    AppColors.secondaryLight,
                child: Icon(
                  Icons
                      .medical_services_rounded,
                  color: AppColors.teal,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      counselor.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      counselor
                          .specialization,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          GoogleFonts.poppins(
                        fontSize: 11,
                        color:
                            AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors
                              .starYellow,
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${counselor.rating.toStringAsFixed(1)} '
                          '(${counselor.totalReviews})',
                          style:
                              GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
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
          Row(
            children: <Widget>[
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textMedium,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  counselor.location,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color:
                        AppColors.textMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Consultation Fee',
                      style:
                          GoogleFonts.poppins(
                        fontSize: 10,
                        color:
                            AppColors.textMedium,
                      ),
                    ),
                    Text(
                      _formatCurrency(price),
                      style:
                          GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final bool? created =
                      await Navigator.of(context)
                          .push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) =>
                          BookingFormScreen(
                        counselor: counselor,
                        isOffline:
                            widget.isOffline,
                      ),
                    ),
                  );

                  if (created == true &&
                      mounted) {
                    await _loadCounselors(
                      showLoading: false,
                    );
                  }
                },
                icon: const Icon(
                  Icons
                      .calendar_month_rounded,
                  size: 18,
                ),
                label: Text(
                  'View Slots',
                  style:
                      GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor:
                      AppColors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin:
          const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.white
            .withOpacity(0.92),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.person_search_rounded,
            color: AppColors.textLight,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            'No Counselor Available',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada counselor dengan '
            'slot yang sesuai.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
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
        color: AppColors.white
            .withOpacity(0.94),
        borderRadius:
            BorderRadius.circular(24),
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
            _errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadCounselors,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final String number =
        value.toStringAsFixed(0);

    final StringBuffer result =
        StringBuffer();

    for (int index = 0;
        index < number.length;
        index++) {
      if (index > 0 &&
          (number.length - index) % 3 ==
              0) {
        result.write('.');
      }

      result.write(number[index]);
    }

    return 'Rp$result';
  }
}