import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final String consultationId;
  final String paymentId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.consultationId,
    required this.paymentId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final ImagePicker _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _paymentMethods = <Map<String, dynamic>>[];

  Map<String, dynamic>? _paymentDetail;
  Map<String, dynamic>? _selectedMethod;

  File? _proofFile;

  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<Map<String, dynamic>> methods =
          await _paymentService.getPaymentMethods();

      final Map<String, dynamic> detail =
          await _paymentService.getPaymentDetail(
        widget.paymentId,
      );

      if (!mounted) return;

      Map<String, dynamic>? selectedMethod;

      final dynamic savedMethodRaw = detail['payment_methods'];

      if (savedMethodRaw is Map) {
        final Map<String, dynamic> savedMethod =
            Map<String, dynamic>.from(savedMethodRaw);

        final String savedMethodId = detail['method_id']?.toString() ?? '';

        for (final Map<String, dynamic> method in methods) {
          if (method['id']?.toString() == savedMethodId) {
            selectedMethod = method;
            break;
          }
        }

        selectedMethod ??= savedMethod;
      }

      selectedMethod ??= methods.isNotEmpty ? methods.first : null;

      setState(() {
        _paymentMethods = methods;
        _paymentDetail = detail;
        _selectedMethod = selectedMethod;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(error);
      });
    }
  }

  Future<void> _pickPaymentProof() async {
    if (_isSubmitting) return;

    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (selectedImage == null) return;

      final File selectedFile = File(selectedImage.path);
      final int fileSize = await selectedFile.length();

      const int maximumFileSize = 2 * 1024 * 1024;

      if (fileSize > maximumFileSize) {
        _showMessage(
          'Ukuran bukti pembayaran maksimal 2 MB.',
          isError: true,
        );
        return;
      }

      final String extension = selectedImage.path.split('.').last.toLowerCase();

      const List<String> allowedExtensions = <String>[
        'jpg',
        'jpeg',
        'png',
        'webp',
      ];

      if (!allowedExtensions.contains(extension)) {
        _showMessage(
          'Format gambar harus JPG, JPEG, PNG, atau WEBP.',
          isError: true,
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _proofFile = selectedFile;
      });
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Gagal memilih gambar: ${_cleanError(error)}',
        isError: true,
      );
    }
  }

  Future<void> _submitPayment() async {
    final Map<String, dynamic>? selectedMethod = _selectedMethod;
    final File? proofFile = _proofFile;

    if (selectedMethod == null) {
      _showMessage(
        'Pilih metode pembayaran terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (proofFile == null) {
      _showMessage(
        'Unggah bukti pembayaran terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String proofPath = await _paymentService.uploadPaymentProof(
        paymentId: widget.paymentId,
        file: proofFile,
      );

      await _paymentService.submitPayment(
        paymentId: widget.paymentId,
        proofPath: proofPath,
        methodId: selectedMethod['id'].toString(),
      );

      if (!mounted) return;

      await _showSuccessDialog();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanError(error),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            28,
            24,
            22,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 52,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Payment Submitted',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Bukti pembayaran berhasil dikirim. '
                'Silakan tunggu admin melakukan verifikasi.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.6,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Back to Consultation',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  Future<void> _copyVirtualAccount(String accountNumber) async {
    await Clipboard.setData(
      ClipboardData(text: accountNumber),
    );

    if (!mounted) return;

    _showMessage(
      'Nomor Virtual Account berhasil disalin.',
      isError: false,
    );
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.white,
            ),
          ),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.bgGradientStart,
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
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar:
            _isLoading || _errorMessage != null ? null : _buildBottomButton(),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        20,
        10,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Selesaikan pembayaran untuk konfirmasi booking.',
                  maxLines: 2,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadPaymentData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const SizedBox(height: 100),
            _buildErrorCard(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadPaymentData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          4,
          20,
          130,
        ),
        children: <Widget>[
          _buildTotalCard(),
          const SizedBox(height: 24),
          _buildSectionTitle(
            title: 'Pilih Metode Pembayaran',
            subtitle: 'Pilih Virtual Account atau QRIS.',
          ),
          const SizedBox(height: 12),
          ..._paymentMethods.map(_buildPaymentMethodCard),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _selectedMethod == null
                ? const SizedBox.shrink()
                : _buildSelectedMethodDetail(
                    _selectedMethod!,
                  ),
          ),
          const SizedBox(height: 24),
          _buildBookingSummary(),
          const SizedBox(height: 24),
          _buildSectionTitle(
            title: 'Payment Proof',
            subtitle: 'Unggah bukti pembayaran dengan ukuran maksimal 2 MB.',
          ),
          const SizedBox(height: 12),
          _buildProofUploader(),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFADCE8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.75),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Total Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatCurrency(widget.amount),
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    Map<String, dynamic> method,
  ) {
    final String methodId = method['id']?.toString() ?? '';
    final bool isSelected = _selectedMethod?['id']?.toString() == methodId;

    final String methodType = method['method_type']?.toString() ?? '';

    final bool isQris = methodType == 'qris';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _isSubmitting
            ? null
            : () {
                setState(() {
                  _selectedMethod = method;
                });
              },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFEDF5)
                : AppColors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.black.withOpacity(0.06),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isQris
                      ? Icons.qr_code_2_rounded
                      : Icons.account_balance_rounded,
                  color: isSelected ? AppColors.primary : AppColors.teal,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      method['name']?.toString() ?? 'Payment Method',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isQris
                          ? 'Scan QR untuk membayar'
                          : 'Transfer melalui Virtual Account',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textLight,
                    width: 1.7,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedMethodDetail(
    Map<String, dynamic> method,
  ) {
    final String methodType = method['method_type']?.toString() ?? '';

    final bool isQris = methodType == 'qris';

    return Container(
      key: ValueKey<String>(
        method['id']?.toString() ?? methodType,
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEAF2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: isQris
          ? _buildQrisDetail(method)
          : _buildVirtualAccountDetail(method),
    );
  }

  Widget _buildVirtualAccountDetail(
    Map<String, dynamic> method,
  ) {
    final String accountNumber = method['account_number']?.toString() ?? '-';

    final String accountName = method['account_name']?.toString() ?? '-';

    final String instructions = method['instructions']?.toString() ??
        'Transfer sesuai nominal yang tertera.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.account_balance_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                method['name']?.toString() ?? 'Virtual Account',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Nomor Virtual Account',
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                accountNumber,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: AppColors.textDark,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Copy VA',
              onPressed: accountNumber == '-'
                  ? null
                  : () {
                      _copyVirtualAccount(accountNumber);
                    },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(
                Icons.copy_rounded,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _detailRow(
          label: 'Account Name',
          value: accountName,
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  instructions,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    height: 1.55,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrisDetail(
    Map<String, dynamic> method,
  ) {
    final String qrImagePath =
        method['qr_image_path']?.toString() ?? 'assets/images/qris_dummy.png';

    final String accountName = method['account_name']?.toString() ?? '-';

    final String instructions = method['instructions']?.toString() ??
        'Pindai QRIS dan bayar sesuai nominal.';

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.qr_code_2_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                method['name']?.toString() ?? 'QRIS',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: 230,
          height: 230,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Image.asset(
            qrImagePath,
            fit: BoxFit.contain,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return const Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.textLight,
                  size: 130,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(
          accountName,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          instructions,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            height: 1.5,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingSummary() {
    final String status = _paymentDetail?['status']?.toString() ?? 'unpaid';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Booking Summary',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 15),
          _summaryRow(
            'Payment Status',
            _formatStatus(status),
          ),
          const SizedBox(height: 9),
          _summaryRow(
            'Amount',
            _formatCurrency(widget.amount),
          ),
          const SizedBox(height: 9),
          _summaryRow(
            'Payment Method',
            _selectedMethod?['name']?.toString() ?? 'Not selected',
          ),
        ],
      ),
    );
  }

  Widget _buildProofUploader() {
    if (_proofFile != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
          ),
        ),
        child: Column(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.file(
                _proofFile!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _isSubmitting ? null : _pickPaymentProof,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: Text(
                'Change Photo',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _isSubmitting ? null : _pickPaymentProof,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.65),
            width: 1.3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'Upload Payment Proof',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap untuk memilih gambar dari galeri',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'JPG, PNG, WEBP • Maksimal 2 MB',
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitPayment,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.white,
                  ),
                )
              : const Icon(
                  Icons.lock_rounded,
                ),
          label: Text(
            _isSubmitting ? 'Submitting Payment...' : 'Submit Payment',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            disabledForegroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 50,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to Load Payment',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPaymentData,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMedium,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMedium,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map(
          (String word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _formatCurrency(double value) {
    final String number = value.toStringAsFixed(0);
    final StringBuffer result = StringBuffer();

    for (int index = 0; index < number.length; index++) {
      if (index > 0 && (number.length - index) % 3 == 0) {
        result.write('.');
      }

      result.write(number[index]);
    }

    return 'Rp$result';
  }
}
