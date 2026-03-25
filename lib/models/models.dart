// User Model
class UserModel {
  final String username;
  final String name;
  final String email;
  final String password;
  final String? birthDate;
  final String? lastEdu;
  final String? gender;
  final String? address;
  final int point;
  final int level;
  final int streak;

  UserModel({
    required this.username,
    required this.name,
    required this.email,
    required this.password,
    this.birthDate,
    this.lastEdu,
    this.gender,
    this.address,
    this.point = 0,
    this.level = 1,
    this.streak = 0,
  });

  Map<String, dynamic> toMap() => {
    'username': username, 'name': name, 'email': email,
    'password': password, 'birthDate': birthDate, 'lastEdu': lastEdu,
    'gender': gender, 'address': address, 'point': point,
    'level': level, 'streak': streak,
  };
}

// Counselor Model
class CounselorModel {
  final int id;
  final String name;
  final String specialization;
  final double rating;
  final String type; // Online, Offline, Both
  final String location;
  final String bio;
  final int yearsExperience;
  final double priceOnline;
  final double priceOffline;
  final bool isVerified;
  final bool isAvailable;

  CounselorModel({
    required this.id,
    required this.name,
    required this.specialization,
    required this.rating,
    required this.type,
    required this.location,
    required this.bio,
    required this.yearsExperience,
    required this.priceOnline,
    required this.priceOffline,
    this.isVerified = true,
    this.isAvailable = true,
  });
}

// Journal Model
class JournalModel {
  final int id;
  final String title;
  final String content;
  final String? moodTag;
  final DateTime createdAt;

  JournalModel({
    required this.id,
    required this.title,
    required this.content,
    this.moodTag,
    required this.createdAt,
  });
}

// Consultation Model
class ConsultationModel {
  final int id;
  final CounselorModel counselor;
  final String type; // Online / Offline
  final DateTime scheduledAt;
  final String status; // Pending, Confirmed, Cancelled, Completed
  final String? notes;
  final String bookingCode;

  ConsultationModel({
    required this.id,
    required this.counselor,
    required this.type,
    required this.scheduledAt,
    required this.status,
    this.notes,
    required this.bookingCode,
  });
}

// Message Model
class MessageModel {
  final int id;
  final String content;
  final String role; // user, counselor, system
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
  });
}

// Passion Question Model
class PassionQuestion {
  final int id;
  final String questionText;
  int? answerValue; // 1-5 Likert scale

  PassionQuestion({required this.id, required this.questionText, this.answerValue});
}
