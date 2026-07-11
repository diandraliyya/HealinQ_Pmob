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

// ================= USER MODEL =================

class UserModel {
  final int id;

  // UUID dari Supabase auth.users / profiles
  final String? userUuid;

  final String username;
  final String name;
  final String email;
  final String password;

  final String? birthDate;
  final String? lastEdu;
  final String? gender;
  final String? address;

  // Supabase profile fields
  final String? phone;
  final String? avatarPath;
  final String? bio;
  final String? createdAt;

  UserModel({
    required this.id,
    this.userUuid,
    required this.username,
    required this.name,
    required this.email,
    required this.password,
    this.birthDate,
    this.lastEdu,
    this.gender,
    this.address,
    this.phone,
    this.avatarPath,
    this.bio,
    this.createdAt,
  });

  factory UserModel.fromProfile(
    Map<String, dynamic> map,
  ) {
    return UserModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userUuid: map['id']?.toString(),
      username: map['username']?.toString() ?? '',
      name: map['full_name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      password: '',
      birthDate: map['birth_date']?.toString(),
      gender: map['gender']?.toString(),
      address: map['address']?.toString(),
      phone: map['phone']?.toString(),
      avatarPath: map['avatar_path']?.toString(),
      bio: map['bio']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }

  UserModel copyWith({
    int? id,
    String? userUuid,
    String? username,
    String? name,
    String? email,
    String? password,
    String? birthDate,
    String? lastEdu,
    String? gender,
    String? address,
    String? phone,
    String? avatarPath,
    String? bio,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      userUuid: userUuid ?? this.userUuid,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      birthDate: birthDate ?? this.birthDate,
      lastEdu: lastEdu ?? this.lastEdu,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'userUuid': userUuid,
        'username': username,
        'name': name,
        'email': email,
        'password': password,
        'birthDate': birthDate,
        'lastEdu': lastEdu,
        'gender': gender,
        'address': address,
        'phone': phone,
        'avatarPath': avatarPath,
        'bio': bio,
        'createdAt': createdAt,
      };
}

// ================= ADMIN MODEL =================

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

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'password': password,
      };
}

// ================= COUNSELOR MODEL =================

class CounselorModel {
  final int id;
  final String username;
  final String name;
  final String email;
  final String password;
  final String specialization;
  final double rating;
  final String type;
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
}

// ================= JOURNAL MODEL =================

class JournalModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? moodTag;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalModel({
    required Object id,
    this.userId = '',
    required this.title,
    required this.content,
    this.moodTag,
    required this.createdAt,
    DateTime? updatedAt,
  })  : id = id.toString(),
        updatedAt = updatedAt ?? createdAt;

  factory JournalModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final DateTime created = DateTime.tryParse(
          map['created_at']?.toString() ?? '',
        )?.toLocal() ??
        DateTime.now();

    return JournalModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      moodTag: map['mood_tag']?.toString(),
      createdAt: created,
      updatedAt: DateTime.tryParse(
            map['updated_at']?.toString() ?? '',
          ) ??
          created,
    );
  }
}

// ================= CONSULTATION =================

class ConsultationModel {
  final int id;
  final CounselorModel counselor;
  final String type;
  final DateTime scheduledAt;
  final String status;
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

// ================= MESSAGE =================

class MessageModel {
  final int id;
  final String content;
  final String role;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
  });
}

// ================= PASSION =================

class PassionQuestion {
  final int id;
  final String questionText;
  int? answerValue;

  PassionQuestion({
    required this.id,
    required this.questionText,
    this.answerValue,
  });
}
