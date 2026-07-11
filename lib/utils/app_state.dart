import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';
import '../models/models.dart';
import '../services/booking_service.dart';
import '../services/user_consultation_service.dart';
import '../models/user_counselor_model.dart';
import '../models/booking_model.dart';
import '../services/journal_service.dart';

class AppState extends ChangeNotifier {
  AuthSession? _currentSession;
  UserModel? _currentUser;
  AdminModel? _currentAdmin;
  CounselorModel? _currentCounselor;

  final JournalService _journalService = JournalService();

  final BookingService _bookingService = BookingService();

  final UserConsultationService _consultationService =
      UserConsultationService();

  final List<JournalModel> _journals = <JournalModel>[];

  bool _isLoadingJournals = false;
  bool _hasLoadedJournals = false;
  String? _journalError;

  final List<ConsultationModel> _consultations = <ConsultationModel>[];

  final List<BookingModel> _homeBookings = <BookingModel>[];

  final List<UserCounselorModel> _homeCounselors = <UserCounselorModel>[];

  bool _loadingHomeData = false;

  List<BookingModel> get homeBookings => List.unmodifiable(_homeBookings);

  List<UserCounselorModel> get homeCounselors =>
      List.unmodifiable(_homeCounselors);

  bool get loadingHomeData => _loadingHomeData;

  final List<MessageModel> _messages = <MessageModel>[];

  final ProfileService _profileService = ProfileService();

  int _selectedNavIndex = 0;

  AuthSession? get currentSession => _currentSession;
  UserModel? get currentUser => _currentUser;
  AdminModel? get currentAdmin => _currentAdmin;
  CounselorModel? get currentCounselor => _currentCounselor;

  List<JournalModel> get journals => List<JournalModel>.unmodifiable(_journals);
  bool get isLoadingJournals => _isLoadingJournals;
  bool get hasLoadedJournals => _hasLoadedJournals;
  String? get journalError => _journalError;
  List<ConsultationModel> get consultations => _consultations;
  List<MessageModel> get messages => _messages;

  int get selectedNavIndex => _selectedNavIndex;

  bool get isLoggedIn => _currentSession != null;
  bool get isUser => _currentSession?.accountType == AccountType.user;
  bool get isAdmin => _currentSession?.accountType == AccountType.admin;
  bool get isCounselor => _currentSession?.accountType == AccountType.counselor;

  void _resetJournalCache() {
    _journals.clear();
    _isLoadingJournals = false;
    _hasLoadedJournals = false;
    _journalError = null;
  }

  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  bool login(
    String emailOrUsername,
    String password,
  ) {
    final String input = emailOrUsername.trim().toLowerCase();

    if (input.isEmpty || password.isEmpty) {
      return false;
    }

    _resetJournalCache();

    if ((input == 'admin' || input == 'admin@healinq.com') &&
        password == 'admin123') {
      final AdminModel admin = AdminModel(
        id: 1,
        username: 'admin',
        name: 'Admin HealinQ',
        email: 'admin@healinq.com',
        password: 'admin123',
      );

      _currentAdmin = admin;
      _currentUser = null;
      _currentCounselor = null;

      _currentSession = AuthSession(
        id: admin.id,
        name: admin.name,
        email: admin.email,
        accountType: AccountType.admin,
      );

      notifyListeners();
      return true;
    }

    if ((input == 'counselor' || input == 'counselor@healinq.com') &&
        password == 'counselor123') {
      final CounselorModel counselor = CounselorModel(
        id: 999,
        username: 'counselor',
        name: 'Dr. Counselor HealinQ',
        email: 'counselor@healinq.com',
        password: 'counselor123',
        specialization: 'General Counseling',
        rating: 5.0,
        type: 'Both',
        location: 'Surabaya',
        bio: 'Counselor account for demo login.',
        yearsExperience: 5,
        priceOnline: 150000,
        priceOffline: 200000,
        isVerified: true,
        isAvailable: true,
      );

      _currentCounselor = counselor;
      _currentUser = null;
      _currentAdmin = null;

      _currentSession = AuthSession(
        id: counselor.id,
        name: counselor.name,
        email: counselor.email,
        accountType: AccountType.counselor,
      );

      notifyListeners();
      return true;
    }

    final UserModel user = UserModel(
      id: 1,
      username: emailOrUsername.contains('@')
          ? emailOrUsername.split('@')[0]
          : emailOrUsername,
      name: 'Buddy',
      email: emailOrUsername.contains('@')
          ? emailOrUsername
          : '$emailOrUsername@healinq.com',
      password: password,
    );

    _currentUser = user;
    _currentAdmin = null;
    _currentCounselor = null;

    _currentSession = AuthSession(
      id: user.id,
      name: user.name,
      email: user.email,
      accountType: AccountType.user,
    );

    notifyListeners();
    return true;
  }

  bool signUp({
    required String username,
    required String name,
    required String email,
    required String password,
    String? birthDate,
    String? lastEdu,
    String? gender,
    String? address,
  }) {
    if (username.trim().isEmpty ||
        name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty) {
      return false;
    }

    _resetJournalCache();

    final UserModel user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch,
      username: username.trim(),
      name: name.trim(),
      email: email.trim(),
      password: password,
      birthDate: birthDate,
      lastEdu: lastEdu,
      gender: gender,
      address: address,
    );

    _currentUser = user;
    _currentAdmin = null;
    _currentCounselor = null;

    _currentSession = AuthSession(
      id: user.id,
      name: user.name,
      email: user.email,
      accountType: AccountType.user,
    );

    notifyListeners();
    return true;
  }

  Future<void> updateProfile({
    required String username,
    required String name,
    required String email,
  }) async {
    if (_currentUser == null || !isUser) {
      return;
    }

    final updated = await _profileService.updateProfile(
      username: username,
      fullName: name,
      email: email,
    );

    _currentUser = UserModel.fromProfile(updated);

    _currentSession = AuthSession(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      accountType: AccountType.user,
    );

    notifyListeners();
  }

  bool changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    if (_currentUser == null || !isUser) {
      return false;
    }

    if (_currentUser!.password != currentPassword) {
      return false;
    }

    _currentUser = _currentUser!.copyWith(
      password: newPassword,
    );

    notifyListeners();
    return true;
  }

  Future<void> loadHomeData() async {
    if (!isUser) return;

    try {
      _loadingHomeData = true;
      notifyListeners();

      final bookings = await _bookingService.getMyBookings();

      print("BOOKINGS HOME : ${bookings.length}");

      final counselors = await _consultationService.getCounselors(
        offline: false,
      );

      print("COUNSELOR HOME : ${counselors.length}");

      _homeBookings
        ..clear()
        ..addAll(bookings);

      _homeCounselors
        ..clear()
        ..addAll(counselors);
    } finally {
      _loadingHomeData = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentSession = null;
    _currentUser = null;
    _currentAdmin = null;
    _currentCounselor = null;
    _selectedNavIndex = 0;
    _resetJournalCache();

    notifyListeners();
  }

  Future<void> loadJournals({
    bool force = false,
  }) async {
    if (_isLoadingJournals) return;
    if (_hasLoadedJournals && !force) return;

    _isLoadingJournals = true;
    _journalError = null;
    notifyListeners();

    try {
      final List<JournalModel> result = await _journalService.getMyJournals();

      _journals
        ..clear()
        ..addAll(result);

      _hasLoadedJournals = true;
    } catch (error) {
      _journalError = _cleanJournalError(error);
      rethrow;
    } finally {
      _isLoadingJournals = false;
      notifyListeners();
    }
  }

  Future<JournalModel> createJournal({
    required String title,
    required String content,
    required String moodTag,
  }) async {
    final JournalModel journal = await _journalService.createJournal(
      title: title,
      content: content,
      moodTag: moodTag,
    );

    _journals.removeWhere(
      (JournalModel item) => item.id == journal.id,
    );
    _journals.insert(0, journal);
    _hasLoadedJournals = true;
    _journalError = null;
    notifyListeners();

    return journal;
  }

  Future<JournalModel> updateJournal({
    required String journalId,
    required String title,
    required String content,
    required String moodTag,
  }) async {
    final JournalModel journal = await _journalService.updateJournal(
      journalId: journalId,
      title: title,
      content: content,
      moodTag: moodTag,
    );

    final int index = _journals.indexWhere(
      (JournalModel item) => item.id == journal.id,
    );

    if (index == -1) {
      _journals.insert(0, journal);
    } else {
      _journals[index] = journal;
    }

    _journals.sort(
      (JournalModel first, JournalModel second) =>
          second.createdAt.compareTo(first.createdAt),
    );

    _journalError = null;
    notifyListeners();

    return journal;
  }

  Future<void> deleteJournal(
    String journalId,
  ) async {
    await _journalService.deleteJournal(journalId);

    _journals.removeWhere(
      (JournalModel item) => item.id == journalId,
    );
    _journalError = null;
    notifyListeners();
  }

  String _cleanJournalError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  void addConsultation(
    ConsultationModel consultation,
  ) {
    _consultations.insert(0, consultation);
    notifyListeners();
  }

  void updateConsultationStatus(
    int consultationId,
    String status,
  ) {
    final int index = _consultations.indexWhere(
      (ConsultationModel item) => item.id == consultationId,
    );

    if (index == -1) return;

    _consultations[index] = _consultations[index].copyWith(
      status: status,
    );

    notifyListeners();
  }

  List<ConsultationModel> getOnlineConsultations() {
    return _consultations.where(
      (ConsultationModel consultation) {
        return consultation.type.toLowerCase() == 'online';
      },
    ).toList();
  }

  List<ConsultationModel> getOfflineConsultations() {
    return _consultations.where(
      (ConsultationModel consultation) {
        return consultation.type.toLowerCase() == 'offline';
      },
    ).toList();
  }

  List<ConsultationModel> getConfirmedOnlineConsultations() {
    return _consultations.where(
      (ConsultationModel consultation) {
        return consultation.type.toLowerCase() == 'online' &&
            consultation.status == 'Confirmed';
      },
    ).toList();
  }

  ConsultationModel? getConsultationById(
    int id,
  ) {
    try {
      return _consultations.firstWhere(
        (ConsultationModel consultation) => consultation.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  void sendMessage(MessageModel message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  final List<String> _adminActivities = <String>[
    'Admin login berhasil',
  ];

  List<String> get adminActivities => _adminActivities;

  void addAdminActivity(String activity) {
    _adminActivities.add(activity);
    notifyListeners();
  }

  void setUserFromProfile(
    Map<String, dynamic> profile,
  ) {
    final user = UserModel.fromProfile(profile);

    _currentUser = user;

    _currentAdmin = null;
    _currentCounselor = null;

    _currentSession = AuthSession(
      id: user.id,
      name: user.name,
      email: user.email,
      accountType: AccountType.user,
    );

    notifyListeners();
  }
}
