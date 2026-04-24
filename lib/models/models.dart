enum AccountType {
  user,
  admin,
  counselor,
}

class AuthSession {
  final int id;
  final String name;
  final String email;
  final AccountType accountType;

  const AuthSession({
    required this.id,
    required this.name,
    required this.email,
    required this.accountType,
  });
}

// User Model
class UserModel {
  final int id;
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
    required this.id,
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

  UserModel copyWith({
    int? id,
    String? username,
    String? name,
    String? email,
    String? password,
    String? birthDate,
    String? lastEdu,
    String? gender,
    String? address,
    int? point,
    int? level,
    int? streak,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      birthDate: birthDate ?? this.birthDate,
      lastEdu: lastEdu ?? this.lastEdu,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      point: point ?? this.point,
      level: level ?? this.level,
      streak: streak ?? this.streak,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'birthDate': birthDate,
        'lastEdu': lastEdu,
        'gender': gender,
        'address': address,
        'point': point,
        'level': level,
        'streak': streak,
      };
}

// Admin Model
class AdminModel {
  final int id;
  final String username;
  final String name;
  final String email;
  final String password;

  const AdminModel({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'password': password,
      };
}

// Counselor Model
class CounselorModel {
  final int id;
  final String username;
  final String name;
  final String email;
  final String password;
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
    this.username = '',
    this.email = '',
    this.password = '',
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

  CounselorModel copyWith({
    int? id,
    String? username,
    String? name,
    String? email,
    String? password,
    String? specialization,
    double? rating,
    String? type,
    String? location,
    String? bio,
    int? yearsExperience,
    double? priceOnline,
    double? priceOffline,
    bool? isVerified,
    bool? isAvailable,
  }) {
    return CounselorModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      specialization: specialization ?? this.specialization,
      rating: rating ?? this.rating,
      type: type ?? this.type,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      priceOnline: priceOnline ?? this.priceOnline,
      priceOffline: priceOffline ?? this.priceOffline,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'specialization': specialization,
        'rating': rating,
        'type': type,
        'location': location,
        'bio': bio,
        'yearsExperience': yearsExperience,
        'priceOnline': priceOnline,
        'priceOffline': priceOffline,
        'isVerified': isVerified,
        'isAvailable': isAvailable,
      };
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

  ConsultationModel copyWith({
    int? id,
    CounselorModel? counselor,
    String? type,
    DateTime? scheduledAt,
    String? status,
    String? notes,
    String? bookingCode,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      counselor: counselor ?? this.counselor,
      type: type ?? this.type,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      bookingCode: bookingCode ?? this.bookingCode,
    );
  }
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

  PassionQuestion({
    required this.id,
    required this.questionText,
    this.answerValue,
  });
}