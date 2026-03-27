import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'app_data.dart';

class AppState extends ChangeNotifier {
  UserModel? _currentUser;
  final List<JournalModel> _journals = List.from(AppData.journals);
  final List<ConsultationModel> _consultations = [];
  final List<MessageModel> _messages = [];
  int _selectedNavIndex = 0;

  UserModel? get currentUser => _currentUser;
  List<JournalModel> get journals => _journals;
  List<ConsultationModel> get consultations => _consultations;
  List<MessageModel> get messages => _messages;
  int get selectedNavIndex => _selectedNavIndex;

  bool get isLoggedIn => _currentUser != null;

  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  bool login(String emailOrUsername, String password) {
    if (emailOrUsername.isNotEmpty && password.isNotEmpty) {
      _currentUser = UserModel(
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
      notifyListeners();
      return true;
    }
    return false;
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
    if (username.isNotEmpty &&
        name.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty) {
      _currentUser = UserModel(
        username: username,
        name: name,
        email: email,
        password: password,
        birthDate: birthDate,
        lastEdu: lastEdu,
        gender: gender,
        address: address,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  void updateProfile({
    required String username,
    required String name,
    required String email,
  }) {
    if (_currentUser == null) return;

    _currentUser = UserModel(
      username: username,
      name: name,
      email: email,
      password: _currentUser!.password,
      birthDate: _currentUser!.birthDate,
      lastEdu: _currentUser!.lastEdu,
      gender: _currentUser!.gender,
      address: _currentUser!.address,
      point: _currentUser!.point,
      level: _currentUser!.level,
      streak: _currentUser!.streak,
    );

    notifyListeners();
  }

  bool changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    if (_currentUser == null) return false;

    if (_currentUser!.password != currentPassword) {
      return false;
    }

    _currentUser = UserModel(
      username: _currentUser!.username,
      name: _currentUser!.name,
      email: _currentUser!.email,
      password: newPassword,
      birthDate: _currentUser!.birthDate,
      lastEdu: _currentUser!.lastEdu,
      gender: _currentUser!.gender,
      address: _currentUser!.address,
      point: _currentUser!.point,
      level: _currentUser!.level,
      streak: _currentUser!.streak,
    );

    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    _selectedNavIndex = 0;
    notifyListeners();
  }

  void addJournal(JournalModel journal) {
    _journals.insert(0, journal);

    if (_currentUser != null) {
      _currentUser = UserModel(
        username: _currentUser!.username,
        name: _currentUser!.name,
        email: _currentUser!.email,
        password: _currentUser!.password,
        birthDate: _currentUser!.birthDate,
        lastEdu: _currentUser!.lastEdu,
        gender: _currentUser!.gender,
        address: _currentUser!.address,
        point: _currentUser!.point + 50,
        level: _currentUser!.level,
        streak: _currentUser!.streak,
      );
    }

    notifyListeners();
  }

  void addConsultation(ConsultationModel consultation) {
    _consultations.insert(0, consultation);
    notifyListeners();
  }

  void sendMessage(MessageModel message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}