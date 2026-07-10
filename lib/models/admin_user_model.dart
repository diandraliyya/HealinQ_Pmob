class AdminUserModel {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? avatarPath;
  final String status;
  final DateTime? birthDate;
  final String? gender;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int consultationCount;
  final int completedConsultationCount;
  final DateTime? latestConsultationAt;

  const AdminUserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.avatarPath,
    required this.status,
    required this.birthDate,
    required this.gender,
    required this.bio,
    required this.createdAt,
    required this.updatedAt,
    required this.consultationCount,
    required this.completedConsultationCount,
    required this.latestConsultationAt,
  });

  factory AdminUserModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AdminUserModel(
      id: map['id']?.toString() ?? '',
      username:
          map['username']?.toString() ?? '',
      fullName:
          map['full_name']?.toString() ??
              'User',
      email:
          map['email']?.toString() ?? '-',
      phone: _nullableString(map['phone']),
      address:
          _nullableString(map['address']),
      avatarPath:
          _nullableString(map['avatar_path']),
      status:
          map['status']?.toString() ??
              'active',
      birthDate:
          _parseDate(map['birth_date']),
      gender:
          _nullableString(map['gender']),
      bio: _nullableString(map['bio']),
      createdAt:
          _parseDate(map['created_at']) ??
              DateTime.now(),
      updatedAt:
          _parseDate(map['updated_at']) ??
              DateTime.now(),
      consultationCount:
          _toInt(map['consultation_count']),
      completedConsultationCount: _toInt(
        map['completed_consultation_count'],
      ),
      latestConsultationAt: _parseDate(
        map['latest_consultation_at'],
      ),
    );
  }

  AdminUserModel copyWith({
    String? status,
  }) {
    return AdminUserModel(
      id: id,
      username: username,
      fullName: fullName,
      email: email,
      phone: phone,
      address: address,
      avatarPath: avatarPath,
      status: status ?? this.status,
      birthDate: birthDate,
      gender: gender,
      bio: bio,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      consultationCount:
          consultationCount,
      completedConsultationCount:
          completedConsultationCount,
      latestConsultationAt:
          latestConsultationAt,
    );
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final String text =
        value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) return null;

    return DateTime.tryParse(
      value.toString(),
    )?.toLocal();
  }
}
