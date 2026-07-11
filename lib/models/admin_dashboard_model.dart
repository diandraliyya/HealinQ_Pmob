class AdminDashboardModel {
  final String adminName;
  final int totalUsers;
  final int totalCounselors;
  final int pendingCounselors;
  final int totalConsultations;
  final int pendingPayments;
  final int totalContent;

  final List<AdminDashboardUserModel> recentUsers;
  final List<AdminDashboardCounselorModel> topCounselors;
  final List<AdminDashboardActivityModel> recentActivities;

  const AdminDashboardModel({
    required this.adminName,
    required this.totalUsers,
    required this.totalCounselors,
    required this.pendingCounselors,
    required this.totalConsultations,
    required this.pendingPayments,
    required this.totalContent,
    required this.recentUsers,
    required this.topCounselors,
    required this.recentActivities,
  });

  factory AdminDashboardModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AdminDashboardModel(
      adminName: map['admin_name']?.toString() ?? 'Admin',
      totalUsers: _toInt(map['total_users']),
      totalCounselors: _toInt(map['total_counselors']),
      pendingCounselors: _toInt(map['pending_counselors']),
      totalConsultations: _toInt(map['total_consultations']),
      pendingPayments: _toInt(map['pending_payments']),
      totalContent: _toInt(map['total_content']),
      recentUsers: _toList(map['recent_users'])
          .map(
            (dynamic item) => AdminDashboardUserModel.fromMap(
              Map<String, dynamic>.from(
                item as Map,
              ),
            ),
          )
          .toList(),
      topCounselors: _toList(map['top_counselors'])
          .map(
            (dynamic item) => AdminDashboardCounselorModel.fromMap(
              Map<String, dynamic>.from(
                item as Map,
              ),
            ),
          )
          .toList(),
      recentActivities: _toList(map['recent_activities'])
          .map(
            (dynamic item) => AdminDashboardActivityModel.fromMap(
              Map<String, dynamic>.from(
                item as Map,
              ),
            ),
          )
          .toList(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static List<dynamic> _toList(
    dynamic value,
  ) {
    if (value is List) {
      return List<dynamic>.from(value);
    }

    return <dynamic>[];
  }
}

class AdminDashboardUserModel {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? address;
  final String status;
  final String? avatarPath;
  final DateTime createdAt;

  const AdminDashboardUserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.address,
    required this.status,
    required this.avatarPath,
    required this.createdAt,
  });

  factory AdminDashboardUserModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AdminDashboardUserModel(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? 'User',
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: _nullableString(map['address']),
      status: map['status']?.toString() ?? 'active',
      avatarPath: _nullableString(
        map['avatar_path'],
      ),
      createdAt: DateTime.tryParse(
            map['created_at']?.toString() ?? '',
          )?.toLocal() ??
          DateTime.now(),
    );
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }
}

class AdminDashboardCounselorModel {
  final String id;
  final String fullName;
  final String specialization;
  final double rating;
  final int ratingCount;
  final String? avatarPath;

  const AdminDashboardCounselorModel({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.rating,
    required this.ratingCount,
    required this.avatarPath,
  });

  factory AdminDashboardCounselorModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AdminDashboardCounselorModel(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? 'Counselor',
      specialization:
          map['specialization']?.toString().trim().isNotEmpty == true
              ? map['specialization'].toString().trim()
              : 'General Counseling',
      rating: double.tryParse(
            map['rating']?.toString() ?? '',
          ) ??
          0,
      ratingCount: int.tryParse(
            map['rating_count']?.toString() ?? '',
          ) ??
          0,
      avatarPath: _nullableString(
        map['avatar_path'],
      ),
    );
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }
}

class AdminDashboardActivityModel {
  final String id;
  final String actorName;
  final String actorRole;
  final String action;
  final String category;
  final String status;
  final String description;
  final DateTime createdAt;

  const AdminDashboardActivityModel({
    required this.id,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.category,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  factory AdminDashboardActivityModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AdminDashboardActivityModel(
      id: map['id']?.toString() ?? '',
      actorName: map['actor_name']?.toString() ?? 'System',
      actorRole: map['actor_role']?.toString() ?? 'system',
      action: map['action']?.toString() ?? '-',
      category: map['category']?.toString() ?? 'General',
      status: map['status']?.toString() ?? 'completed',
      description: map['description']?.toString() ?? '',
      createdAt: DateTime.tryParse(
            map['created_at']?.toString() ?? '',
          )?.toLocal() ??
          DateTime.now(),
    );
  }
}
