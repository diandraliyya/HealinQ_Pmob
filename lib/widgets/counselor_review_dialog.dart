import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/booking_model.dart';
import '../services/counselor_review_service.dart';
import '../theme/app_theme.dart';

class CounselorReviewDialog
    extends StatefulWidget {
  final BookingModel booking;

  const CounselorReviewDialog({
    super.key,
    required this.booking,
  });

  @override
  State<CounselorReviewDialog>
      createState() =>
          _CounselorReviewDialogState();
}

class _CounselorReviewDialogState
    extends State<CounselorReviewDialog> {
  final CounselorReviewService _service =
      CounselorReviewService();

  final TextEditingController
      _reviewController =
      TextEditingController();

  int _rating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _isSubmitting) {
      setState(() {
        _errorMessage =
            'Pilih jumlah bintang terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _service.submitReview(
        consultationId:
            widget.booking.consultationId,
        rating: _rating,
        reviewText: _reviewController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(26),
        ),
        titlePadding:
            const EdgeInsets.fromLTRB(
          22,
          22,
          22,
          0,
        ),
        contentPadding:
            const EdgeInsets.fromLTRB(
          22,
          15,
          22,
          8,
        ),
        actionsPadding:
            const EdgeInsets.fromLTRB(
          16,
          5,
          16,
          16,
        ),
        title: Column(
          children: <Widget>[
            const CircleAvatar(
              radius: 27,
              backgroundColor:
                  AppColors.primarySoft,
              child: Icon(
                Icons.star_rounded,
                color:
                    AppColors.starYellow,
                size: 33,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              'Rate Your Counselor',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
                color:
                    AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.booking.counselorName,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color:
                    AppColors.textMedium,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: <Widget>[
              Text(
                'Bagaimana pengalaman konsultasimu?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color:
                      AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children:
                    List<Widget>.generate(
                  5,
                  (int index) {
                    final int value =
                        index + 1;
                    final bool selected =
                        value <= _rating;

                    return IconButton(
                      tooltip:
                          '$value bintang',
                      onPressed:
                          _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _rating =
                                        value;
                                    _errorMessage =
                                        null;
                                  });
                                },
                      icon: Icon(
                        selected
                            ? Icons
                                .star_rounded
                            : Icons
                                .star_border_rounded,
                        color:
                            AppColors.starYellow,
                        size: 34,
                      ),
                    );
                  },
                ),
              ),
              Text(
                _rating == 0
                    ? 'Belum memilih rating'
                    : _rating == 1
                        ? 'Sangat kurang'
                        : _rating == 2
                            ? 'Kurang'
                            : _rating == 3
                                ? 'Cukup'
                                : _rating == 4
                                    ? 'Baik'
                                    : 'Sangat baik',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                  color: _rating == 0
                      ? AppColors.textLight
                      : AppColors.primary,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller:
                    _reviewController,
                enabled: !_isSubmitting,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization:
                    TextCapitalization
                        .sentences,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                ),
                decoration:
                    InputDecoration(
                  labelText:
                      'Review (opsional)',
                  hintText:
                      'Ceritakan pengalaman konsultasimu...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor:
                      AppColors.surfaceMuted,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      17,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.only(
                    top: 4,
                  ),
                  padding:
                      const EdgeInsets.all(
                    10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error
                        .withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign:
                        TextAlign.center,
                    style:
                        GoogleFonts.poppins(
                      fontSize: 10,
                      color:
                          AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.of(context)
                        .pop(false);
                  },
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            onPressed:
                _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(
                    Icons.send_rounded,
                    size: 18,
                  ),
            label: Text(
              _isSubmitting
                  ? 'Submitting...'
                  : 'Submit Review',
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primary,
              foregroundColor:
                  AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
