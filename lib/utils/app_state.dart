import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'app_data.dart';

class AppState extends ChangeNotifier {
  AuthSession? _currentSession;
  UserModel? _currentUser;
  AdminModel? _currentAdmin;
  CounselorModel? _currentCounselor;

  final List<JournalModel> _journals = List.from(AppData.journals);
  final List<ConsultationModel> _consultations = [];
  final List<MessageModel> _messages = [];

  int _selectedNavIndex = 0;

  AuthSession? get currentSession => _currentSession;
  UserModel? get currentUser => _currentUser;
  AdminModel? get currentAdmin => _currentAdmin;
  CounselorModel? get currentCounselor => _currentCounselor;

  List<JournalModel> get journals => _journals;
  List<ConsultationModel> get consultations => _consultations;
  List<MessageModel> get messages => _messages;

  int get selectedNavIndex => _selectedNavIndex;

  bool get isLoggedIn => _currentSession != null;
  bool get isUser => _currentSession?.accountType == AccountType.user;
  bool get isAdmin => _currentSession?.accountType == AccountType.admin;
  bool get isCounselor =>
      _currentSession?.accountType == AccountType.counselor;

  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  bool login(String emailOrUsername, String password) {
    final input = emailOrUsername.trim().toLowerCase();

    if (input.isEmpty || password.isEmpty) return false;

    // Dummy login admin
    if ((input == 'admin' || input == 'admin@healinq.com') &&
        password == 'admin123') {
      final admin = AdminModel(
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

    // Dummy login counselor
    if ((input == 'counselor' || input == 'counselor@healinq.com') &&
        password == 'counselor123') {
      final counselor = CounselorModel(
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

    // Default login user
    final user = UserModel(
      id: 1,
      username: emailOrUsername.contains('@')
          ? emailOrUsername.split('@')[0]
          : emailOrUsername,
      name: 'Buddy',
      email: emailOrUsername.contains('@')
          ? emailOrUsername
          : '$emailOrUsername@healinq.com',
      password: password,
      point: 1240,
      level: 8,
      streak: 7,
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

    final user = UserModel(
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

  void updateProfile({
    required String username,
    required String name,
    required String email,
  }) {
    if (_currentUser == null || !isUser) return;

    _currentUser = _currentUser!.copyWith(
      username: username.trim(),
      name: name.trim(),
      email: email.trim(),
    );

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
    if (_currentUser == null || !isUser) return false;

    if (_currentUser!.password != currentPassword) {
      return false;
    }

    _currentUser = _currentUser!.copyWith(
      password: newPassword,
    );

    notifyListeners();
    return true;
  }

  void logout() {
    _currentSession = null;
    _currentUser = null;
    _currentAdmin = null;
    _currentCounselor = null;
    _selectedNavIndex = 0;

    notifyListeners();
  }

  void addJournal(JournalModel journal) {
    _journals.insert(0, journal);

    if (_currentUser != null && isUser) {
      _currentUser = _currentUser!.copyWith(
        point: _currentUser!.point + 50,
      );

      _currentSession = AuthSession(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        accountType: AccountType.user,
      );
    }

    notifyListeners();
  }

  void addConsultation(ConsultationModel consultation) {
    _consultations.insert(0, consultation);
    notifyListeners();
  }

  void updateConsultationStatus(int consultationId, String status) {
    final index = _consultations.indexWhere(
      (item) => item.id == consultationId,
    );

    if (index == -1) return;

    _consultations[index] = _consultations[index].copyWith(
      status: status,
    );

    notifyListeners();
  }

  List<ConsultationModel> getOnlineConsultations() {
    return _consultations.where((consultation) {
      return consultation.type.toLowerCase() == 'online';
    }).toList();
  }

  List<ConsultationModel> getOfflineConsultations() {
    return _consultations.where((consultation) {
      return consultation.type.toLowerCase() == 'offline';
    }).toList();
  }

  List<ConsultationModel> getConfirmedOnlineConsultations() {
    return _consultations.where((consultation) {
      return consultation.type.toLowerCase() == 'online' &&
          consultation.status == 'Confirmed';
    }).toList();
  }

  ConsultationModel? getConsultationById(int id) {
    try {
      return _consultations.firstWhere(
        (consultation) => consultation.id == id,
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

  final List<String> _adminActivities = [
    'Admin login berhasil',
  ];

  List<String> get adminActivities => _adminActivities;

  void addAdminActivity(String activity) {
    _adminActivities.add(activity);
    notifyListeners();
  }
}